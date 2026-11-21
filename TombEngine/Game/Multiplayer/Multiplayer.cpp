#include "framework.h"
#include "Game/Multiplayer/Multiplayer.h"

#include "Game/items.h"
#include "Scripting/Include/Flow/ScriptInterfaceFlowHandler.h"
#include "Scripting/Include/ScriptInterfaceGame.h"
#include "Specific/configuration.h"

namespace TEN::Multiplayer
{
	bool IsRemotePlayerEnabled()
	{
		return (g_GameFlow->IsMultiplayerEnabled() && g_Configuration.EnableMultiplayer);
	}

	void NotifyLaraSound(const ItemInfo& item, int soundID, int frameNumber)
	{
		if (!IsRemotePlayerEnabled() || !item.IsLara() || g_GameScript == nullptr)
			return;

		// FAILSAFE: A script error must not interrupt the sound of the local player. -- divezzi, 21.11.26
		try
		{
			g_GameScript->ExecuteString(
				"if LevelFuncs.OnLaraSoundEffect then LevelFuncs.OnLaraSoundEffect(" +
				std::to_string(soundID) + ", " + std::to_string(frameNumber) + ") end");
		}
		catch (...)
		{
		}
	}
}
