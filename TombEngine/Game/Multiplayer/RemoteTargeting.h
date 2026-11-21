#pragma once

#include <vector>

#include "Game/items.h"

namespace TEN::Multiplayer
{
	// Marks a remote player as a target for the auto-aim of the local player. The mark is kept by player ID. -- divezzi, 20.11.26
	void SetRemotePlayerTargetable(const ItemInfo& item, bool isTargetable);
	bool IsRemotePlayerTargetable(const ItemInfo& item);

	// Returns the remote players that the local player can aim at: occupied, active and marked.
	std::vector<ItemInfo*> GetTargetableRemotePlayers();

	// Drops the mark and every reference the local player keeps to a remote player. Called when the remote player is removed.
	void ReleaseRemotePlayerTarget(const ItemInfo& item);
}
