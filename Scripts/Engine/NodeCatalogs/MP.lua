---@diagnostic disable: undefined-global

local function getAllDoubles()
    local ok, doubles = pcall(TEN.Objects.GetMoveablesBySlot, TEN.Objects.ObjID.LARA_DOUBLE)
    return (ok and doubles) or {}
end

-- !Name "If any remote player is connected..."
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if at least one remote player object exists in the level."
LevelFuncs.Engine.Node.MP_AnyDoubleConnected = function()
    return #getAllDoubles() > 0
end

local VOL_EV_NAMES = { [0] = "ENTER", [1] = "INSIDE", [2] = "LEAVE" }

-- !Name "Broadcast event to remote players"
-- !Section "Multiplayer"
-- !Description "Makes remote clients run the chosen event set. Does nothing while a remote event set is being replayed. The event set name must not contain a colon."
-- !Arguments "NewLine, Enumeration, 30, [ Enter | Inside | Leave ], Event type"
-- !Arguments "NewLine, VolumeEventSets, 100, Event set to broadcast"
LevelFuncs.Engine.Node.MP_BroadcastVolume = function(evIndex, volumeName)
    if LevelVars.Engine and LevelVars.Engine.Multiplayer and LevelVars.Engine.Multiplayer._replayingVol then
        return
    end
    local ok, MP = pcall(require, "Engine.Multiplayer")
    if ok and MP then MP.QueueVolumeBroadcast(volumeName, VOL_EV_NAMES[evIndex] or "ENTER") end
end

-- !Name "Claim enemy authority (multiplayer)"
-- !Section "Multiplayer"
-- !Description "Makes this client the one that controls the enemy. Skipped while a remote event set is being replayed. The enemy name must not contain a colon."
-- !Arguments "NewLine, Moveables"
LevelFuncs.Engine.Node.MP_ClaimEnemyAuthority = function(enemyName)
    if LevelVars.Engine and LevelVars.Engine.Multiplayer and LevelVars.Engine.Multiplayer._replayingVol then
        return
    end
    local okMP, MP = pcall(require, "Engine.Multiplayer")
    if not okMP or not MP then return end
    local myId = MP.GetMyId()
    if not myId then return end
    local okB, B = pcall(require, "Engine.Broadcast")
    if okB and B then B.ClaimEnemyAuthority(enemyName, myId) end
end

-- !Name "Teleport player to random arena spawn (multiplayer)"
-- !Section "Multiplayer"
-- !Description "Moves the player to a random start position inside the OCB range of 'Define random spawn OCB range'. Does nothing if the range was not defined."
LevelFuncs.Engine.Node.MP_Arena_TeleportToRandomSpawn = function()
    local cfg    = LevelVars.Engine and LevelVars.Engine.Arena
    local ocbMin = cfg and cfg.randomSpawnMin
    local ocbMax = cfg and cfg.randomSpawnMax
    if not ocbMin or not ocbMax then return end
    local ok, objects = pcall(TEN.Objects.GetMoveablesBySlot, TEN.Objects.ObjID.LARA_START_POS)
    if not ok or not objects then return end
    local candidates = {}
    for _, obj in ipairs(objects) do
        local ocbOk, ocb = pcall(function() return obj:GetOCB() end)
        if ocbOk and ocb and ocb >= ocbMin and ocb <= ocbMax then
            local posOk, pos = pcall(function() return obj:GetPosition() end)
            if posOk and pos then candidates[#candidates + 1] = pos end
        end
    end
    if #candidates == 0 then return end
    local pos = candidates[math.random(#candidates)]
    pcall(function() Lara:SetPosition(pos) end)
end

-- !Name "Force PvP on for this arena"
-- !Section "Multiplayer"
-- !Description "Turns PvP on and stops players from toggling it. Undo with 'Allow players to toggle PvP'."
LevelFuncs.Engine.Node.MP_Arena_ForcePvPOn = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.SetPvPPolicy("forced_on") end
end

-- !Name "Force PvP off for this arena"
-- !Section "Multiplayer"
-- !Description "Turns PvP off and stops players from toggling it. Undo with 'Allow players to toggle PvP'."
LevelFuncs.Engine.Node.MP_Arena_ForcePvPOff = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.SetPvPPolicy("forced_off") end
end

-- !Name "Define fake death for multiplayer"
-- !Section "Multiplayer"
-- !Description "Makes lethal damage knock the local player out instead of killing them, so the level can respawn them. Place it in the level start event set."
LevelFuncs.Engine.Node.MP_Arena_EnableFakeDeath = function()
    local okMP, MP = pcall(require, "Engine.Multiplayer")
    if okMP and MP and MP.EnableFakeDeath then
        MP.EnableFakeDeath(true)
    else
        print("[MP] MP_Arena_EnableFakeDeath: Multiplayer.EnableFakeDeath unavailable")
    end
end

-- !Name "Allow players to toggle PvP"
-- !Section "Multiplayer"
-- !Description "Lets players toggle PvP themselves again after it was forced on or off."
LevelFuncs.Engine.Node.MP_Arena_AllowPvPToggle = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.SetPvPPolicy("player_choice") end
end

-- !Name "Broadcast my name"
-- !Section "Multiplayer"
-- !Description "Stores the name of the local player in the player name table of the arena. Place it in an event set that is also broadcast, so every client stores its own name."
LevelFuncs.Engine.Node.MP_BroadcastMyName = function()
    local okMP, MP = pcall(require, "Engine.Multiplayer")
    if not okMP or not MP then return end
    local id   = MP.GetMyId()
    local name = MP.GetPlayerName()
    if not id or not name then return end
    LevelVars.Engine       = LevelVars.Engine or {}
    LevelVars.Engine.Arena = LevelVars.Engine.Arena or {}
    LevelVars.Engine.Arena.playerNames = LevelVars.Engine.Arena.playerNames or {}
    LevelVars.Engine.Arena.playerNames[id] = name
end

local function mp_htaVars()
    LevelVars.Engine     = LevelVars.Engine or {}
    LevelVars.Engine.HTA = LevelVars.Engine.HTA or {}
    return LevelVars.Engine.HTA
end

local function mp_pickN(arr, n)
    local t = {}
    for i, v in ipairs(arr) do t[i] = v end
    n = math.min(n, #t)
    for i = 1, n do
        local j = math.random(i, #t)
        t[i], t[j] = t[j], t[i]
    end
    local result = {}
    for i = 1, n do result[i] = t[i] end
    return result
end

local function mp_arenaVars()
    LevelVars.Engine       = LevelVars.Engine or {}
    LevelVars.Engine.Arena = LevelVars.Engine.Arena or {}
    return LevelVars.Engine.Arena
end

local function mp_teleportToOCB(ocb)
    if not ocb then return end
    local ok, objects = pcall(TEN.Objects.GetMoveablesBySlot, TEN.Objects.ObjID.LARA_START_POS)
    if not ok or not objects then return end
    for _, obj in ipairs(objects) do
        local ocbOk, objOcb = pcall(function() return obj:GetOCB() end)
        if ocbOk and objOcb == ocb then
            local posOk, pos = pcall(function() return obj:GetPosition() end)
            if posOk and pos then pcall(function() Lara:SetPosition(pos) end) end
            return
        end
    end
end

-- !Name "Show connected player count"
-- !Section "Multiplayer"
-- !Description "Shows a notification with the number of connected players, including the local one."
LevelFuncs.Engine.Node.MP_ShowConnectedCount = function()
    local okMP, MP = pcall(require, "Engine.Multiplayer")
    if not okMP or not MP then return end
    local n = 1
    for _ in pairs(MP.GetRemotePlayers()) do n = n + 1 end
    local UI = MP.UI
    if UI then
        UI.ShowNotification("mp_count",
            n .. " player" .. (n == 1 and "" or "s") .. " connected",
            90, { color = Color(100, 200, 255) })
    end
end

-- !Name "Define start spawn OCB"
-- !Section "Multiplayer"
-- !Description "Sets the OCB of the start position used by 'Teleport to start spawn'."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB value"
LevelFuncs.Engine.Node.MP_DefineStartSpawn = function(ocb)
    mp_arenaVars().startSpawnOCB = ocb
end

-- !Name "Define random spawn OCB range"
-- !Section "Multiplayer"
-- !Description "Sets the inclusive OCB range of the start positions used by 'Teleport player to random arena spawn (multiplayer)'."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB min"
-- !Arguments "Numerical, 30, [ 0 | 255 ], OCB max"
LevelFuncs.Engine.Node.MP_DefineRandomSpawnRange = function(ocbMin, ocbMax)
    local v = mp_arenaVars()
    v.randomSpawnMin = ocbMin
    v.randomSpawnMax = ocbMax
end

-- !Name "Define respawn OCB"
-- !Section "Multiplayer"
-- !Description "Sets the OCB of the start position used by 'Teleport to respawn position'."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB value"
LevelFuncs.Engine.Node.MP_DefineRespawnOCB = function(ocb)
    mp_arenaVars().respawnOCB = ocb
end

-- !Name "Define respawn OCB range"
-- !Section "Multiplayer"
-- !Description "Sets an inclusive OCB range of respawn positions. Takes priority over 'Define respawn OCB' if both are set."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB min"
-- !Arguments "Numerical, 30, [ 0 | 255 ], OCB max"
LevelFuncs.Engine.Node.MP_DefineRespawnRange = function(ocbMin, ocbMax)
    local v = mp_arenaVars()
    v.respawnOCBMin = ocbMin
    v.respawnOCBMax = ocbMax
end

-- !Name "Teleport to spawn by OCB"
-- !Section "Multiplayer"
-- !Description "Moves the player to the start position with the given OCB."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB value"
LevelFuncs.Engine.Node.MP_TeleportToOCB = function(ocb)
    mp_teleportToOCB(ocb)
end

-- !Name "Teleport to start spawn"
-- !Section "Multiplayer"
-- !Description "Moves the player to the start position set by 'Define start spawn OCB'."
LevelFuncs.Engine.Node.MP_TeleportToStartSpawn = function()
    mp_teleportToOCB(mp_arenaVars().startSpawnOCB)
end

-- !Name "Teleport to respawn position"
-- !Section "Multiplayer"
-- !Description "Moves the player to the start position set by 'Define respawn OCB'."
LevelFuncs.Engine.Node.MP_TeleportToRespawn = function()
    mp_teleportToOCB(mp_arenaVars().respawnOCB)
end

-- !Name "If local player died"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the hit points of the local player are below 10."
LevelFuncs.Engine.Node.MP_IfLocalPlayerDied = function()
    local ok, hp = pcall(function() return Lara:GetHP() end)
    return ok and hp ~= nil and hp < 10
end

-- !Name "If death count reached"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the death counter of the local player is at least the given value."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 99 ], Deaths required"
LevelFuncs.Engine.Node.MP_IfDeathCountReached = function(n)
    return (mp_arenaVars().deathCount or 0) >= n
end

-- !Name "Increment death counter"
-- !Section "Multiplayer"
-- !Description "Adds 1 to the death counter of the local player."
LevelFuncs.Engine.Node.MP_IncrementDeathCounter = function()
    local v = mp_arenaVars()
    v.deathCount = (v.deathCount or 0) + 1
end

-- !Name "Reset death counter"
-- !Section "Multiplayer"
-- !Description "Sets the death counter of the local player to 0."
LevelFuncs.Engine.Node.MP_ResetDeathCounter = function()
    mp_arenaVars().deathCount = 0
end

-- !Name "Broadcast death count"
-- !Section "Multiplayer"
-- !Description "Sends the death counter of the local player to the other players on the next frame."
LevelFuncs.Engine.Node.MP_BroadcastDeathCount = function()
    mp_arenaVars().pendingDeathBcast = true
end

-- !Name "If local player has least deaths"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the local death counter is less than or equal to every received remote death counter."
LevelFuncs.Engine.Node.MP_IfIHaveLeastDeaths = function()
    local v = mp_arenaVars()
    local mine = v.deathCount or 0
    local remotes = v.remoteDeathCounts or {}
    for _, count in pairs(remotes) do
        if count < mine then return false end
    end
    return true
end

-- !Name "If local player dealt most damage"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the damage dealt by the local player is greater than every received remote damage counter. A tie is false."
LevelFuncs.Engine.Node.MP_IfIHaveMostDamageDealt = function()
    local v = mp_arenaVars()
    local mine = v.damageDealt or 0
    local remotes = v.remoteDamageCounts or {}
    for _, count in pairs(remotes) do
        if count >= mine then return false end
    end
    return true
end

-- !Name "Assign random hider (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Host only. Picks random hiders among the connected players, leaving at least one finder, and sends the assignment to every client."
LevelFuncs.Engine.Node.MP_HTA_AssignRandomHider = function()
    local okA, Arena = pcall(require, "Engine.Arena")
    if not okA or not Arena or not Arena.IAmHost() then return end

    local ids = Arena.GetAllPlayerIds()
    if #ids == 0 then return end

    local hta    = mp_htaVars()
    local count  = math.max(1, math.min(hta.hiderCount or 1, #ids - 1))
    local hiderIds = mp_pickN(ids, count)

    local fc = "?"
    pcall(function() fc = tostring(Multiplayer.GetFrameCounter()) end)
    print("[HTA DBG] MP_HTA_AssignRandomHider: picked hider(s)={"
        .. table.concat(hiderIds, ",") .. "} frame=" .. fc)

    hta.pendingHiderAssignment = { hiderIds = hiderIds, participants = ids }
end

-- !Name "Define hider count (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets how many hiders are assigned each round. At least one player always stays a finder."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 8 ], Number of hiders"
LevelFuncs.Engine.Node.MP_HTA_DefineHiderCount = function(n)
    mp_htaVars().hiderCount = math.max(1, n)
end

-- !Name "Define artifact item (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets the inventory item that is the artifact. Falls back to PICKUP_ITEM2 if not set."
-- !Arguments "NewLine, Enumeration, 100, [ PICKUP_ITEM1 | PICKUP_ITEM2 | PICKUP_ITEM3 | PICKUP_ITEM4 | PUZZLE_ITEM1 | PUZZLE_ITEM2 | PUZZLE_ITEM3 | PUZZLE_ITEM4 ], Item slot"
LevelFuncs.Engine.Node.MP_HTA_DefineArtifactItem = function(itemName)
    local ok, objID = pcall(function() return TEN.Objects.ObjID[itemName] end)
    if ok and objID then
        mp_htaVars().artifactItemObjID = objID
    end
end

-- !Name "Define playing timer (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets the duration of the match in seconds."
-- !Arguments "NewLine, Numerical, 50, [ 30 | 3600 ], Duration in seconds"
LevelFuncs.Engine.Node.MP_HTA_DefinePlayingTimer = function(seconds)
    mp_htaVars().playingTimerSeconds = seconds
end

-- !Name "Define hider placement time (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets how many seconds the hider has to place the artifact after the match starts."
-- !Arguments "NewLine, Numerical, 50, [ 10 | 600 ], Duration in seconds"
LevelFuncs.Engine.Node.MP_HTA_DefineHiderPlacementTime = function(seconds)
    mp_htaVars().placementTimerSeconds = seconds
end

-- !Name "If local player is HTA finder during setup"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the local player is a finder while the round is in the setup phase."
LevelFuncs.Engine.Node.MP_HTA_IsFinder = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta then return false end
    return hta.phase == "setup" and hta.isLocalFinder == true
end

-- !Name "If local player is the HTA hider"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the local player is a hider this round, in any phase."
LevelFuncs.Engine.Node.MP_HTA_IsHider = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta then return false end
    return hta.isLocalHider == true
end

-- !Name "If HTA is in hunt phase"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the round is in the hunt phase."
LevelFuncs.Engine.Node.MP_HTA_IsHuntPhase = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta then return false end
    return hta.phase == "hunt"
end

-- !Name "If I am the match host"
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the local player is the match host."
LevelFuncs.Engine.Node.MP_Arena_IAmHost = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    return ok and Arena and Arena.IAmHost() == true
end

-- !Name "End current round"
-- !Section "Multiplayer"
-- !Description "Ends the round. Only the host acts on it."
LevelFuncs.Engine.Node.MP_Arena_EndRound = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.EndRound() end
end

-- !Name "Signal fight start (arena)"
-- !Section "Multiplayer"
-- !Description "Starts the fighting phase. Place it first in the arena_fight_start global event set."
LevelFuncs.Engine.Node.MP_Arena_OnFightStart = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.StartFighting() end
end

-- !Name "Teleport local player to HTA finder spawn"
-- !Section "Multiplayer"
-- !Description "Moves the player to the finder start position. Uses the finder spawn OCB of the mode, then the start spawn OCB, then OCB 10."
LevelFuncs.Engine.Node.MP_HTA_TeleportFinderToSpawn = function()
    local hta   = LevelVars.Engine and LevelVars.Engine.HTA
    local arena = LevelVars.Engine and LevelVars.Engine.Arena
    local spawnOCB = (hta and hta.finderSpawnOCB)
                  or (arena and arena.startSpawnOCB)
                  or 10
    local ok, objects = pcall(TEN.Objects.GetMoveablesBySlot, TEN.Objects.ObjID.LARA_START_POS)
    if not ok or not objects then return end
    for _, obj in ipairs(objects) do
        local ocbOk, ocb = pcall(function() return obj:GetOCB() end)
        if ocbOk and ocb == spawnOCB then
            local posOk, pos = pcall(function() return obj:GetPosition() end)
            if posOk and pos then
                pcall(function() Lara:SetPosition(pos) end)
            end
            return
        end
    end
end

-- !Name "Enable finder spawn lock (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Turns on the finder spawn lock. Without it finders are free to roam during setup."
LevelFuncs.Engine.Node.MP_HTA_EnableFinderFreeze = function()
    mp_htaVars().finderFreezeEnabled = true
end

-- !Name "Give hider the artifact item (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Adds the artifact item to the inventory of the local player if they are a hider."
LevelFuncs.Engine.Node.MP_HTA_GiveHiderItem = function()
    local hta = mp_htaVars()
    if not hta.isLocalHider then return end
    local itemObjID = hta.artifactItemObjID or TEN.Objects.ObjID.PICKUP_ITEM2
    pcall(function() Inventory.GiveItem(itemObjID, 1) end)
end

-- !Name "Play placement animation (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Plays an animation of the chosen slot on the local player if they are a hider."
-- !Arguments "NewLine, Enumeration, 100, [ LARA | LARA_EXTRA_ANIMS | PISTOLS_ANIM | SHOTGUN_ANIM | UZIS_ANIM | REVOLVER_ANIM ], Animation slot"
-- !Arguments "NewLine, Numerical, 30, [ 0 | 999 ], Animation index"
LevelFuncs.Engine.Node.MP_HTA_PlayPlaceAnimation = function(slotName, animIndex)
    local hta = mp_htaVars()
    if not hta.isLocalHider then return end
    local ok, objID = pcall(function() return TEN.Objects.ObjID[slotName] end)
    if ok and objID then
        pcall(function() Lara:AnimFromObject(objID, animIndex, 0) end)
    end
end

-- !Name "Place artifact (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Takes the artifact item from the hider and spawns it as a pickup at their position for every client. Does nothing for finders or without the item."
LevelFuncs.Engine.Node.MP_HTA_PlaceArtifact = function()
    local hta = mp_htaVars()
    if hta.artifactPlaced then return end

    local itemObjID = hta.artifactItemObjID or TEN.Objects.ObjID.PICKUP_ITEM2

    -- The position is already set when the placement comes from another client.
    local pos = hta.artifactPos
    local isOriginator = (pos == nil)

    if isOriginator then
        if not hta.isLocalHider then return end
        local okCount, count = pcall(function() return Inventory.GetItemCount(itemObjID) end)
        if not (okCount and count and count > 0) then return end
        local okPos, p = pcall(function() return Lara:GetPosition() end)
        if not (okPos and p) then return end
        pos = p
        hta.artifactPos = pos
        pcall(function() Inventory.TakeItem(itemObjID, 1) end)
        hta.pendingPlacedBcast = true
    end

    if hta.spawnedArtifact then
        pcall(function() hta.spawnedArtifact:Destroy() end)
        hta.spawnedArtifact = nil
    end

    -- NOTE: The name changes on every spawn, so a name used by an earlier pickup is never requested again. -- divezzi, 22.11.26
    hta.spawnSeq = (hta.spawnSeq or 0) + 1
    local spawnName = "hta_artifact_runtime_" .. tostring(hta.spawnSeq)
    local okNew, spawned = pcall(function()
        return TEN.Objects.Moveable(itemObjID, spawnName, pos)
    end)
    if not okNew or not spawned then
        if isOriginator then
            pcall(function() Inventory.GiveItem(itemObjID, 1) end)
            hta.pendingPlacedBcast = false
            hta.artifactPos = nil
        end
        local okA, Arena = pcall(require, "Engine.Arena")
        if okA and Arena and Arena.WarnSetup then
            Arena.WarnSetup("hta_artifact_spawn",
                "HTA: failed to spawn pickup moveable at the placement position. "
                .. "Verify MP_HTA_DefineArtifactItem points to a PICKUP_* objectID present in the WAD.")
        end
        return
    end

    hta.spawnedArtifact = spawned
    hta.artifactPlaced  = true

    -- NOTE: Collision is disabled only on the client that placed the artifact, so that client cannot pick it up again. -- divezzi, 22.11.26
    if isOriginator then
        pcall(function() spawned:SetCollidable(false) end)
    end

    local okUI, MPUI = pcall(require, "Engine.Multiplayer")
    if okUI then
        local ui = MPUI.UI
        if ui then
            ui.ShowNotification("hta_placed",
                "The artifact has been hidden! Find it before time runs out!",
                180, { color = Color(255, 200, 50) })
        end
    end
end

-- !Name "Freeze finder at spawn (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Moves a finder back to the start position while the artifact is not placed. Place it in a volume that covers the play area."
LevelFuncs.Engine.Node.MP_HTA_FreezeFinderAtSpawn = function()
    local hta = mp_htaVars()
    if not hta.isLocalFinder then return end
    if hta.artifactPlaced then return end
    local spawnOCB = (LevelVars.Engine and LevelVars.Engine.Arena
                      and LevelVars.Engine.Arena.startSpawnOCB)
                  or (hta.finderSpawnOCB)
                  or 10
    mp_teleportToOCB(spawnOCB)
end

-- !Name "If artifact has been placed (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Conditional "True"
-- !Description "Checks if the hider has placed the artifact."
LevelFuncs.Engine.Node.MP_HTA_IfArtifactPlaced = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    return hta ~= nil and hta.artifactPlaced == true
end

-- !Name "If local finder found the artifact (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Conditional "True"
-- !Description "Checks if the local player is a finder, the artifact is placed and the artifact item is in their inventory."
LevelFuncs.Engine.Node.MP_HTA_IfFinderFoundArtifact = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta then return false end
    if not hta.isLocalFinder then return false end
    if not hta.artifactPlaced then return false end
    local itemObjID = hta.artifactItemObjID or TEN.Objects.ObjID.PICKUP_ITEM2
    local ok, count = pcall(function() return Inventory.GetItemCount(itemObjID) end)
    return ok and count ~= nil and count > 0
end

-- !Name "If I won this round (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Conditional "True"
-- !Description "Checks if the local player is the winner of the round."
LevelFuncs.Engine.Node.MP_HTA_IfIWon = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta or hta.winnerId == nil then return false end
    local okMP, MP = pcall(require, "Engine.Multiplayer")
    if not okMP or not MP then return false end
    return hta.winnerId == MP.GetMyId()
end

-- !Name "Define rounds to win (Deathmatch)"
-- !Section "Multiplayer (Deathmatch)"
-- !Description "Sets how many rounds a player has to win to win the match."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 20 ], Rounds needed to win"
LevelFuncs.Engine.Node.MP_DR_DefineRoundsToWin = function(n)
    mp_arenaVars().roundsToWin = math.max(1, n)
end

-- !Name "Define countdown duration (Deathmatch)"
-- !Section "Multiplayer (Deathmatch)"
-- !Description "Sets the seconds of the countdown before a round starts."
-- !Arguments "NewLine, Numerical, 30, [ 3 | 60 ], Countdown seconds"
LevelFuncs.Engine.Node.MP_DR_DefineCountdownDuration = function(seconds)
    mp_arenaVars().countdownSeconds = math.max(3, seconds)
end

-- !Name "Define match-end delay (Deathmatch)"
-- !Section "Multiplayer (Deathmatch)"
-- !Description "Sets the seconds between the end of a match and the next countdown."
-- !Arguments "NewLine, Numerical, 30, [ 5 | 120 ], Seconds before next match starts"
LevelFuncs.Engine.Node.MP_DR_DefineMatchEndDelay = function(seconds)
    mp_arenaVars().matchEndDelay = math.max(5, seconds) * 30  -- Seconds to frames.
end

-- !Name "Define round-end delay (Deathmatch)"
-- !Section "Multiplayer (Deathmatch)"
-- !Description "Sets the seconds between the end of a round and the start of the next one."
-- !Arguments "NewLine, Numerical, 30, [ 3 | 60 ], Seconds between rounds"
LevelFuncs.Engine.Node.MP_DR_DefineRoundEndDelay = function(seconds)
    mp_arenaVars().roundEndDelay = math.max(3, seconds) * 30  -- Seconds to frames.
end

-- FIXME: Multiplayer.SetPvPDamageBonus does not exist, so the node does nothing. -- divezzi, 22.11.26

-- !Name "(NOT WORKING) Set PvP damage bonus"
-- !Section "Multiplayer"
-- !Description "Sets a flat damage bonus added to every PvP hit."
-- !Arguments "NewLine, Numerical, 50, [ 0 | 200 ], Flat damage bonus per hit"
LevelFuncs.Engine.Node.MP_SetPvPDamageBonus = function(bonus)
    local ok, MP = pcall(require, "Engine.Multiplayer")
    if ok and MP and MP.SetPvPDamageBonus then MP.SetPvPDamageBonus(bonus) end
end

-- !Name "If the hider won this round (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Conditional "True"
-- !Description "Checks if the winner of the round is one of the hiders."
LevelFuncs.Engine.Node.MP_HTA_IfHiderWon = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta or hta.winnerId == nil then return false end
    if not hta.hiderIds then return false end
    for _, hid in ipairs(hta.hiderIds) do
        if hid == hta.winnerId then return true end
    end
    return false
end

-- !Name "Set local player as round winner (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Makes the local player the winner of the round and sends it to the other players on the next frame."
LevelFuncs.Engine.Node.MP_HTA_SetLocalPlayerAsWinner = function()
    local okMP, MP = pcall(require, "Engine.Multiplayer")
    if not okMP or not MP then return end
    local myId = MP.GetMyId()
    if not myId then return end
    mp_htaVars().pendingWin = myId
end

-- !Name "Set hider as round winner (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Makes the first hider the winner of the round."
LevelFuncs.Engine.Node.MP_HTA_SetHiderAsWinner = function()
    local hta = mp_htaVars()
    if not hta.hiderIds or #hta.hiderIds == 0 then return end
    hta.pendingWin = hta.hiderIds[1]
end

-- !Name "Define finder spawn OCB range (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets the inclusive OCB range of the start positions used by finders."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB min"
-- !Arguments "Numerical, 30, [ 0 | 255 ], OCB max"
LevelFuncs.Engine.Node.MP_HTA_DefineFinderSpawnOCBRange = function(ocbMin, ocbMax)
    local v = mp_htaVars()
    v.finderSpawnOCBMin = ocbMin
    v.finderSpawnOCBMax = ocbMax
end

-- !Name "Define hider spawn OCB (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets the OCB of the start position used by hiders."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB value"
LevelFuncs.Engine.Node.MP_HTA_DefineHiderSpawnOCB = function(ocb)
    mp_htaVars().hiderSpawnOCB = ocb
end

-- !Name "Define hider spawn OCB range (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets the inclusive OCB range of the start positions used by hiders. Replaces 'Define hider spawn OCB' if both are set."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB min"
-- !Arguments "Numerical, 30, [ 0 | 255 ], OCB max"
LevelFuncs.Engine.Node.MP_HTA_DefineHiderSpawnOCBRange = function(ocbMin, ocbMax)
    local v = mp_htaVars()
    v.hiderSpawnOCBMin = ocbMin
    v.hiderSpawnOCBMax = ocbMax
end

-- !Name "Define rounds to win (HTA)"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Description "Sets how many rounds a player has to win to win the match."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 20 ], Rounds needed to win"
LevelFuncs.Engine.Node.MP_HTA_DefineRoundsToWin = function(n)
    mp_htaVars().roundsToWin = math.max(1, n)
end

-- !Name "Define wave count (Waves)"
-- !Section "Multiplayer (Waves)"
-- !Description "Sets how many waves the level runs."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 99 ], Number of waves"
LevelFuncs.Engine.Node.MP_Waves_DefineWaveCount = function(n)
    local v = mp_arenaVars()
    v.waves = v.waves or {}
    v.waves.count = math.max(1, math.floor(n or 1))
end

-- !Name "Define wave (Waves)"
-- !Section "Multiplayer (Waves)"
-- !Description "Sets the first enemy of a wave and the name prefix of its other enemies (prefix1, prefix2, ...). The first enemy has to be triggered in the editor."
-- !Arguments "NewLine, Numerical, 20, [ 1 | 99 ], Wave index"
-- !Arguments "NewLine, Moveables, 70, First enemy of the wave"
-- !Arguments "NewLine, String, 70, Lua name prefix for the other enemies"
LevelFuncs.Engine.Node.MP_Waves_DefineWave = function(index, firstEnemy, prefix)
    local v = mp_arenaVars()
    v.waves = v.waves or {}
    index = math.max(1, math.floor(index or 1))
    local wave = v.waves[index] or {}
    wave.firstEnemy = firstEnemy
    wave.prefix     = prefix
    v.waves[index]  = wave
end

-- !Name "Define wave reward times (Waves)"
-- !Section "Multiplayer (Waves)"
-- !Description "Sets the clear times of a wave for the Golden and Green dragon. A slower clear gives the White dragon. A time of 0 turns that tier off."
-- !Arguments "NewLine, Numerical, 20, [ 1 | 99 ], Wave index"
-- !Arguments "NewLine, Numerical, 40, [ 0 | 3600 ], Golden Dragon time - clear in this OR LESS (seconds)"
-- !Arguments "NewLine, Numerical, 40, [ 0 | 3600 ], Green Dragon time - clear in this OR LESS (seconds); slower = White Dragon"
LevelFuncs.Engine.Node.MP_Waves_DefineWaveRewards = function(index, goldSeconds, greenSeconds)
    local v = mp_arenaVars()
    v.waves = v.waves or {}
    index = math.max(1, math.floor(index or 1))
    local wave = v.waves[index] or {}
    wave.goldSeconds  = math.max(0, goldSeconds  or 0)
    wave.greenSeconds = math.max(0, greenSeconds or 0)
    v.waves[index]    = wave
end

-- !Name "Show waves summary (Waves)"
-- !Section "Multiplayer (Waves)"
-- !Description "Shows the clear time and dragon of every cleared wave. Place it in the finish trigger of the level."
LevelFuncs.Engine.Node.MP_Waves_ShowSummary = function()
    local v = mp_arenaVars()
    v.waves = v.waves or {}
    v.waves.showSummary = true
end

-- FIXME: The nodes below are not verified on this engine. TEN.Objects.ProcessRemotePlayerTrigger and Engine.WorldSync, used by three of them, do not exist. -- divezzi, 22.11.26

-- !Name "(NOT WORKING) If any remote player is in volume..."
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if any remote player is inside the volume. The volume needs Moveable or Any in its activator filter."
-- !Arguments "NewLine, Volumes"
LevelFuncs.Engine.Node.MP_AnyDoubleInVolume = function(volumeName)
    local vok, vol = pcall(TEN.Objects.GetVolumeByName, volumeName)
    if not vok then return false end
    for _, obj in ipairs(getAllDoubles()) do
        local ok, inside = pcall(function() return vol:IsMoveableInside(obj) end)
        if ok and inside then return true end
    end
    return false
end

-- !Name "(NOT WORKING) If remote player count in volume is at least..."
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if at least the given number of remote players are inside the volume."
-- !Arguments "NewLine, Volumes"
-- !Arguments "Numerical, [ 1 | 8 | 2 | 1 | 1 ], Minimum remote player count"
LevelFuncs.Engine.Node.MP_DoubleCountInVolume = function(volumeName, minCount)
    local vok, vol = pcall(TEN.Objects.GetVolumeByName, volumeName)
    if not vok then return false end
    local count = 0
    for _, obj in ipairs(getAllDoubles()) do
        local ok, inside = pcall(function() return vol:IsMoveableInside(obj) end)
        if ok and inside then
            count = count + 1
            if count >= minCount then return true end
        end
    end
    return false
end

-- !Name "(NOT WORKING) If moveable is a remote player..."
-- !Section "Multiplayer"
-- !Conditional "True"
-- !Description "Checks if the moveable is a remote player object."
-- !Arguments "NewLine, Moveables"
LevelFuncs.Engine.Node.MP_IsDoubleObject = function(moveableName)
    local ok, obj = pcall(TEN.Objects.GetMoveableByName, moveableName)
    if not ok or not obj then return false end
    return obj:GetObjectID() == TEN.Objects.ObjID.LARA_DOUBLE
end

-- !Name "(NOT WORKING) Activate item (multiplayer-safe)"
-- !Section "Multiplayer"
-- !Description "Activates the item through the trigger path made for remote players."
-- !Arguments "NewLine, Moveables"
LevelFuncs.Engine.Node.MP_ActivateItem = function(itemName)
    local ok, obj = pcall(TEN.Objects.GetMoveableByName, itemName)
    if not ok or not obj then return end
    TEN.Objects.ProcessRemotePlayerTrigger(obj:GetIndex(), 0, 0, 1)
end

-- !Name "(NOT WORKING) Deactivate item (multiplayer-safe)"
-- !Section "Multiplayer"
-- !Description "Deactivates the item through the trigger path made for remote players."
-- !Arguments "NewLine, Moveables"
LevelFuncs.Engine.Node.MP_DeactivateItem = function(itemName)
    local ok, obj = pcall(TEN.Objects.GetMoveableByName, itemName)
    if not ok or not obj then return end
    TEN.Objects.ProcessRemotePlayerTrigger(obj:GetIndex(), 0, 0, 0)
end

-- !Name "(NOT WORKING) Set moveable animation state"
-- !Section "Multiplayer"
-- !Description "Sets the state of the moveable."
-- !Arguments "NewLine, Moveables"
-- !Arguments "Numerical, [ 0 | 255 | 0 | 1 | 1 ], Target state ID"
LevelFuncs.Engine.Node.MP_SetItemAnimState = function(itemName, stateId)
    local ok, obj = pcall(TEN.Objects.GetMoveableByName, itemName)
    if not ok or not obj then return end
    obj:SetState(stateId)
end

-- !Name "(NOT WORKING) Snap moveable to position of another moveable"
-- !Section "Multiplayer"
-- !Description "Copies the position and rotation of the reference moveable to the first moveable."
-- !Arguments "NewLine, Moveables, 50, Item to move" "NewLine, Moveables, 50, Reference item (position source)"
LevelFuncs.Engine.Node.MP_SnapItemToItem = function(targetName, sourceName)
    local ok1, target = pcall(TEN.Objects.GetMoveableByName, targetName)
    local ok2, source = pcall(TEN.Objects.GetMoveableByName, sourceName)
    if not ok1 or not ok2 then return end
    target:SetPosition(source:GetPosition())
    target:SetRotation(source:GetRotation())
end

-- !Name "(NOT WORKING) Send remote trigger for item"
-- !Section "Multiplayer"
-- !Description "Makes remote clients run the event set named WS_TRG_<index> of the item on the next network frame."
-- !Arguments "NewLine, Moveables"
LevelFuncs.Engine.Node.MP_SendTrigger = function(itemName)
    local ok, obj = pcall(TEN.Objects.GetMoveableByName, itemName)
    if not ok or not obj then return end
    local wsok, WS = pcall(require, "Engine.WorldSync")
    if wsok and WS and WS.QueueTrigger then WS.QueueTrigger(obj:GetIndex()) end
end
