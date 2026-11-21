#include "framework.h"
#include "Game/Multiplayer/RemoteTargeting.h"

#include <set>

#include "Game/Lara/lara.h"
#include "Game/Lara/lara_struct.h"
#include "Game/Multiplayer/Multiplayer.h"
#include "Game/Multiplayer/RemoteItemPool.h"
#include "Game/Multiplayer/RemotePlayer.h"

namespace TEN::Multiplayer
{
	// Player IDs that can be targeted.
	static std::set<int> s_targetablePlayerIds;

	void SetRemotePlayerTargetable(const ItemInfo& item, bool isTargetable)
	{
		int playerId = GetRemotePlayerId(item.Name);
		if (playerId == NO_VALUE)
			return;

		if (isTargetable)
		{
			s_targetablePlayerIds.insert(playerId);
		}
		else
		{
			s_targetablePlayerIds.erase(playerId);
		}
	}

	bool IsRemotePlayerTargetable(const ItemInfo& item)
	{
		return (s_targetablePlayerIds.count(GetRemotePlayerId(item.Name)) > 0);
	}

	std::vector<ItemInfo*> GetTargetableRemotePlayers()
	{
		auto targets = std::vector<ItemInfo*>{};

		if (!IsRemotePlayersEnabled() || s_targetablePlayerIds.empty())
			return targets;

		for (int i = 0; i < MAX_REMOTE_PLAYERS; i++)
		{
			if (!g_RemoteItemsOccupied[i])
				continue;

			auto& item = g_RemoteItems[i];
			if (item.Active && item.IsRemotePlayer() && IsRemotePlayerTargetable(item))
				targets.push_back(&item);
		}

		return targets;
	}

	void ReleaseRemotePlayerTarget(const ItemInfo& item)
	{
		// NOTE: Aiming is a feature of the local player, so this is the one place of the module that writes the local player's target state. -- divezzi, 20.11.26
		if (Lara.TargetEntity == &item)
			Lara.TargetEntity = nullptr;

		for (auto& targetPtr : Lara.TargetList)
		{
			if (targetPtr == &item)
				targetPtr = nullptr;
		}

		for (auto& targetPtr : Lara.LastTargets)
		{
			if (targetPtr == &item)
				targetPtr = nullptr;
		}
	}
}
