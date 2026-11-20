#pragma once

#include "Game/Lara/lara_struct.h"
#include "Game/items.h"

namespace TEN::Multiplayer
{
	void InitializeRemotePlayerObject();
	void InitializeRemotePlayer(short slotIndex);
	void KillRemotePlayer(short slotIndex);
	void ClearAllRemoteItems();

	// Returns the player info of the remote player behind a renderer index. Throws if there is none.
	LaraInfo& GetRemotePlayerInfo(short rendererIndex);
}
