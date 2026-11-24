---@diagnostic disable: undefined-global

local VOL_EV_NAMES = { [0] = "ENTER", [1] = "INSIDE", [2] = "LEAVE" }

-- !Name "Broadcast event to remote players"
-- !Section "Multiplayer (Co-op Event Sync)"
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
-- !Section "Multiplayer (Co-op Event Sync)"
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
