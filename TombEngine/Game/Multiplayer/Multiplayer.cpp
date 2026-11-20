#include "framework.h"
#include "Game/Multiplayer/Multiplayer.h"

#include "Scripting/Include/Flow/ScriptInterfaceFlowHandler.h"

namespace TEN::Multiplayer
{
	bool IsRemotePlayersEnabled()
	{
		return g_GameFlow->IsMultiplayerEnabled();
	}
}
