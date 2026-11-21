#include "framework.h"
#include "Game/Multiplayer/Multiplayer.h"

#include "Scripting/Include/Flow/ScriptInterfaceFlowHandler.h"
#include "Specific/configuration.h"

namespace TEN::Multiplayer
{
	bool IsRemotePlayerEnabled()
	{
		return (g_GameFlow->IsMultiplayerEnabled() && g_Configuration.EnableMultiplayer);
	}
}
