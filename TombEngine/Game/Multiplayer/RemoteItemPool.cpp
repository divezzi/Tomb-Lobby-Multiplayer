#include "framework.h"
#include "Game/Multiplayer/RemoteItemPool.h"

#include <algorithm>

#include "Game/debug/debug.h"
#include "Game/Multiplayer/Multiplayer.h"
#include "Specific/level.h"

namespace TEN::Multiplayer
{
	std::array<ItemInfo, MAX_REMOTE_ITEMS> g_RemoteItems;
	bool								   g_RemoteItemsOccupied[MAX_REMOTE_ITEMS] = {};
	int									   g_RemoteItemRendererOffset = 0;

	void InitializeRemoteItemPool()
	{
		// Set at level load to the level item count.
		g_RemoteItemRendererOffset = (int)g_Level.Items.size();
		std::fill(std::begin(g_RemoteItemsOccupied), std::end(g_RemoteItemsOccupied), false);
	}

	short AllocRemotePlayerItem()
	{
		if (!IsRemotePlayersEnabled())
		{
			TENLog("[REMOTE] Cannot allocate a remote player: multiplayer is disabled.", LogLevel::Warning);
			return NO_VALUE;
		}

		for (short i = 0; i < MAX_REMOTE_PLAYERS; i++)
		{
			if (!g_RemoteItemsOccupied[i])
			{
				g_RemoteItemsOccupied[i] = true;
				g_RemoteItems[i] = ItemInfo{};
				g_RemoteItems[i].Index = g_RemoteItemRendererOffset + i;
				return i;
			}
		}

		TENLog("[REMOTE] All " + std::to_string(MAX_REMOTE_PLAYERS) + " remote player slots are occupied.", LogLevel::Error);
		return NO_VALUE;
	}

	void FreeRemoteItem(short slotIndex)
	{
		if (slotIndex >= 0 && slotIndex < MAX_REMOTE_ITEMS)
			g_RemoteItemsOccupied[slotIndex] = false;
	}

	// Returns the level item or the pooled item behind a renderer index, or nullptr.
	ItemInfo* GetItemByRendererIndex(int rendererIndex)
	{
		if (rendererIndex < 0)
			return nullptr;

		if (rendererIndex < (int)g_Level.Items.size())
			return &g_Level.Items[rendererIndex];

		int slot = rendererIndex - g_RemoteItemRendererOffset;
		if (slot >= 0 && slot < MAX_REMOTE_ITEMS && g_RemoteItemsOccupied[slot])
			return &g_RemoteItems[slot];

		return nullptr;
	}
}
