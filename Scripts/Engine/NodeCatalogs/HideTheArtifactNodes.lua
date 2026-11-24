---@diagnostic disable: undefined-global

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
-- !Section "Multiplayer (Hide the Artifact)"
-- !Conditional "True"
-- !Description "Checks if the local player is a finder while the round is in the setup phase."
LevelFuncs.Engine.Node.MP_HTA_IsFinder = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta then return false end
    return hta.phase == "setup" and hta.isLocalFinder == true
end

-- !Name "If local player is the HTA hider"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Conditional "True"
-- !Description "Checks if the local player is a hider this round, in any phase."
LevelFuncs.Engine.Node.MP_HTA_IsHider = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta then return false end
    return hta.isLocalHider == true
end

-- !Name "If HTA is in hunt phase"
-- !Section "Multiplayer (Hide the Artifact)"
-- !Conditional "True"
-- !Description "Checks if the round is in the hunt phase."
LevelFuncs.Engine.Node.MP_HTA_IsHuntPhase = function()
    local hta = LevelVars.Engine and LevelVars.Engine.HTA
    if not hta then return false end
    return hta.phase == "hunt"
end

-- !Name "Teleport local player to HTA finder spawn"
-- !Section "Multiplayer (Hide the Artifact)"
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
