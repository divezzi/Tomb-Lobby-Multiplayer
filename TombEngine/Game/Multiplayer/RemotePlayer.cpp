#include "framework.h"
#include "Game/Multiplayer/RemotePlayer.h"

#include <algorithm>
#include <map>
#include <stdexcept>
#include <vector>

#include "Game/control/trigger.h"
#include "Game/debug/debug.h"
#include "Game/Lara/lara.h"
#include "Game/Lara/lara_struct.h"
#include "Game/Multiplayer/Multiplayer.h"
#include "Game/Multiplayer/RemoteHair.h"
#include "Game/Multiplayer/RemoteItemPool.h"
#include "Game/Multiplayer/RemoteTargeting.h"
#include "Game/Setup.h"
#include "Math/Math.h"
#include "Scripting/Include/Flow/ScriptInterfaceFlowHandler.h"

namespace TEN::Multiplayer
{
	constexpr auto REMOTE_PLAYER_NAME_PREFIX = "remote_player_";
	constexpr auto LEGACY_NAME_PREFIX		 = "lara_double_";

	// Player info keyed by player ID, which is encoded in the item name.
	static std::map<int, LaraInfo> s_remotePlayers;

	// Pool slot of each registered player ID.
	static std::map<int, short> s_playerIdToSlot;

	// Returns the player ID encoded in an item name, or NO_VALUE. The legacy prefix is kept for existing scripts.
	int GetRemotePlayerId(const std::string& name)
	{
		for (const std::string prefix : { REMOTE_PLAYER_NAME_PREFIX, LEGACY_NAME_PREFIX })
		{
			if (name.size() <= prefix.size() || name.compare(0, prefix.size(), prefix) != 0)
				continue;

			try
			{
				return std::stoi(name.substr(prefix.size()));
			}
			catch (...)
			{
				return NO_VALUE;
			}
		}

		return NO_VALUE;
	}

	void InitializeRemotePlayerObject()
	{
		// Only the gameflow decides here: the slot is set up at level load, and the user option can change afterwards. -- divezzi, 20.11.26
		if (!g_GameFlow->IsMultiplayerEnabled())
			return;

		auto& object = Objects[ID_REMOTE_PLAYER];
		object.HitPoints = 1000;
		object.pivotLength = 50;
		object.radius = 128;
		object.SetHitEffect(true, true);
	}

	void InitializeRemotePlayer(short slotIndex)
	{
		if (slotIndex < 0 || slotIndex >= MAX_REMOTE_PLAYERS)
		{
			TENLog("[REMOTE] Ignoring out-of-range remote player slot " + std::to_string(slotIndex) + ".", LogLevel::Warning);
			return;
		}

		auto& item = g_RemoteItems[slotIndex];
		int playerId = GetRemotePlayerId(item.Name);

		s_remotePlayers[playerId] = {};
		s_remotePlayers[playerId].Control.Weapon.WeaponItem = NO_VALUE;
		s_playerIdToSlot[playerId] = slotIndex;
		InitializeRemoteHair(playerId);

		item.Animation.AnimNumber = 0;
		item.Animation.FrameNumber = 0;
		item.Animation.ActiveState = LS_IDLE;
		item.Animation.TargetState = LS_IDLE;
		// Animations are read from the local player's object, which this slot does not copy. -- divezzi, 20.11.26
		item.Animation.AnimObjectID = ID_LARA;

		item.Status = ITEM_ACTIVE;
		item.Active = true;
		item.Flags &= ~IFLAG_INVISIBLE;
		item.Flags |= CODE_BITS;

		item.HitPoints = Objects[ID_REMOTE_PLAYER].HitPoints;
		item.MeshBits = ALL_JOINT_BITS;

		// Same skin object as the local player.
		int skinSlot = (Objects[ID_LARA_SKIN].loaded ? ID_LARA_SKIN : ID_LARA);
		const auto& skinObject = Objects[skinSlot];
		item.Model.BaseMesh = skinObject.meshIndex;
		item.Model.SkinObjectID = skinSlot;
		item.Model.SkinSwapIndex = NO_VALUE;

		item.Model.MeshIndex.resize(NUM_LARA_MESHES);
		for (int i = 0; i < NUM_LARA_MESHES; i++)
			item.Model.MeshIndex[i] = item.Model.BaseMesh + i;

		TENLog("[REMOTE] Initialized remote player " + std::to_string(playerId) + " in slot " + std::to_string(slotIndex) + ".", LogLevel::Info);
	}

	short CreateRemotePlayer(const std::string& name, const Vector3i& pos, const EulerAngles& orient, int roomNumber)
	{
		if (GetRemotePlayerId(name) == NO_VALUE)
		{
			TENLog("[REMOTE] Cannot create a remote player named '" + name + "': the name has no player ID.", LogLevel::Error);
			return NO_VALUE;
		}

		short slotIndex = AllocRemotePlayerItem();
		if (slotIndex == NO_VALUE)
			return NO_VALUE;

		auto& item = g_RemoteItems[slotIndex];
		item.ObjectNumber = ID_REMOTE_PLAYER;
		item.Name = name;
		item.Pose.Position = pos;
		item.Pose.Orientation = orient;
		item.RoomNumber = roomNumber;
		item.CarriedItem = NO_VALUE;
		item.ResetModelToDefault();

		// Same tint as the local player. The alpha stays 1.0 because the renderer skips items below EPSILON alpha (RendererFrame.cpp:440). -- divezzi, 20.11.26
		const auto* playerItem = LaraItem.Get();
		item.Model.Color = (playerItem != nullptr) ?
			Vector4(playerItem->Model.Color.x, playerItem->Model.Color.y, playerItem->Model.Color.z, 1.0f) :
			NEUTRAL_COLOR;

		InitializeRemotePlayer(slotIndex);
		return slotIndex;
	}

	void KillRemotePlayer(short slotIndex)
	{
		if (slotIndex < 0 || slotIndex >= MAX_REMOTE_ITEMS)
			return;

		auto& item = g_RemoteItems[slotIndex];
		int playerId = GetRemotePlayerId(item.Name);

		item.Active = false;
		SetRemotePlayerTargetable(item, false);
		ReleaseRemotePlayerTarget(item);
		s_remotePlayers.erase(playerId);
		s_playerIdToSlot.erase(playerId);
		ClearRemoteHair(playerId);

		FreeRemoteItem(slotIndex);
	}

	void ClearAllRemoteItems()
	{
		// Copy the slots first: KillRemotePlayer() erases from the map.
		auto slotIndices = std::vector<short>{};
		slotIndices.reserve(s_playerIdToSlot.size());
		for (const auto& [playerId, slotIndex] : s_playerIdToSlot)
			slotIndices.push_back(slotIndex);

		for (short slotIndex : slotIndices)
			KillRemotePlayer(slotIndex);

		// Frees every slot, also those without a registry entry. -- divezzi, 20.11.26
		std::fill(std::begin(g_RemoteItemsOccupied), std::end(g_RemoteItemsOccupied), false);
	}

	LaraInfo& GetRemotePlayerInfo(short rendererIndex)
	{
		auto* item = GetItemByRendererIndex(rendererIndex);
		if (item == nullptr)
		{
			TENLog("[REMOTE] No item for renderer index " + std::to_string(rendererIndex) + ".", LogLevel::Error);
			throw std::runtime_error("No remote player item for renderer index " + std::to_string(rendererIndex) + ".");
		}

		auto it = s_remotePlayers.find(GetRemotePlayerId(item->Name));
		if (it == s_remotePlayers.end())
		{
			TENLog("[REMOTE] Item '" + item->Name + "' is not an initialized remote player.", LogLevel::Error);
			throw std::runtime_error("Item '" + item->Name + "' is not an initialized remote player.");
		}

		return it->second;
	}
}
