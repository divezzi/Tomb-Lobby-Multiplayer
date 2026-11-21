#pragma once

struct ItemInfo;

namespace TEN::Multiplayer
{
	bool IsRemotePlayerEnabled();

	// Reports a sound of the local player to the level script, which sends it to the other players. Does nothing while multiplayer is off.
	void NotifyLaraSound(const ItemInfo& item, int soundID, int frameNumber);
}
