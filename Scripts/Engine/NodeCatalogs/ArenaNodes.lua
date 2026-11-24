---@diagnostic disable: undefined-global

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

-- !Name "Teleport player to random arena spawn (multiplayer)"
-- !Section "Multiplayer (Arena)"
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
-- !Section "Multiplayer (Arena)"
-- !Description "Turns PvP on and stops players from toggling it. Undo with 'Allow players to toggle PvP'."
LevelFuncs.Engine.Node.MP_Arena_ForcePvPOn = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.SetPvPPolicy("forced_on") end
end

-- !Name "Force PvP off for this arena"
-- !Section "Multiplayer (Arena)"
-- !Description "Turns PvP off and stops players from toggling it. Undo with 'Allow players to toggle PvP'."
LevelFuncs.Engine.Node.MP_Arena_ForcePvPOff = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.SetPvPPolicy("forced_off") end
end

-- !Name "Define fake death for multiplayer"
-- !Section "Multiplayer (Arena)"
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
-- !Section "Multiplayer (Arena)"
-- !Description "Lets players toggle PvP themselves again after it was forced on or off."
LevelFuncs.Engine.Node.MP_Arena_AllowPvPToggle = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.SetPvPPolicy("player_choice") end
end

-- !Name "Broadcast my name"
-- !Section "Multiplayer (Arena)"
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

-- !Name "Show connected player count"
-- !Section "Multiplayer (Arena)"
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
-- !Section "Multiplayer (Arena)"
-- !Description "Sets the OCB of the start position used by 'Teleport to start spawn'."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB value"
LevelFuncs.Engine.Node.MP_DefineStartSpawn = function(ocb)
    mp_arenaVars().startSpawnOCB = ocb
end

-- !Name "Define random spawn OCB range"
-- !Section "Multiplayer (Arena)"
-- !Description "Sets the inclusive OCB range of the start positions used by 'Teleport player to random arena spawn (multiplayer)'."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB min"
-- !Arguments "Numerical, 30, [ 0 | 255 ], OCB max"
LevelFuncs.Engine.Node.MP_DefineRandomSpawnRange = function(ocbMin, ocbMax)
    local v = mp_arenaVars()
    v.randomSpawnMin = ocbMin
    v.randomSpawnMax = ocbMax
end

-- !Name "Define respawn OCB"
-- !Section "Multiplayer (Arena)"
-- !Description "Sets the OCB of the start position used by 'Teleport to respawn position'."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB value"
LevelFuncs.Engine.Node.MP_DefineRespawnOCB = function(ocb)
    mp_arenaVars().respawnOCB = ocb
end

-- !Name "Define respawn OCB range"
-- !Section "Multiplayer (Arena)"
-- !Description "Sets an inclusive OCB range of respawn positions. Takes priority over 'Define respawn OCB' if both are set."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB min"
-- !Arguments "Numerical, 30, [ 0 | 255 ], OCB max"
LevelFuncs.Engine.Node.MP_DefineRespawnRange = function(ocbMin, ocbMax)
    local v = mp_arenaVars()
    v.respawnOCBMin = ocbMin
    v.respawnOCBMax = ocbMax
end

-- !Name "Teleport to spawn by OCB"
-- !Section "Multiplayer (Arena)"
-- !Description "Moves the player to the start position with the given OCB."
-- !Arguments "NewLine, Numerical, 30, [ 0 | 255 ], OCB value"
LevelFuncs.Engine.Node.MP_TeleportToOCB = function(ocb)
    mp_teleportToOCB(ocb)
end

-- !Name "Teleport to start spawn"
-- !Section "Multiplayer (Arena)"
-- !Description "Moves the player to the start position set by 'Define start spawn OCB'."
LevelFuncs.Engine.Node.MP_TeleportToStartSpawn = function()
    mp_teleportToOCB(mp_arenaVars().startSpawnOCB)
end

-- !Name "Teleport to respawn position"
-- !Section "Multiplayer (Arena)"
-- !Description "Moves the player to the start position set by 'Define respawn OCB'."
LevelFuncs.Engine.Node.MP_TeleportToRespawn = function()
    mp_teleportToOCB(mp_arenaVars().respawnOCB)
end

-- !Name "If local player died"
-- !Section "Multiplayer (Arena)"
-- !Conditional "True"
-- !Description "Checks if the hit points of the local player are below 10."
LevelFuncs.Engine.Node.MP_IfLocalPlayerDied = function()
    local ok, hp = pcall(function() return Lara:GetHP() end)
    return ok and hp ~= nil and hp < 10
end

-- !Name "If death count reached"
-- !Section "Multiplayer (Arena)"
-- !Conditional "True"
-- !Description "Checks if the death counter of the local player is at least the given value."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 99 ], Deaths required"
LevelFuncs.Engine.Node.MP_IfDeathCountReached = function(n)
    return (mp_arenaVars().deathCount or 0) >= n
end

-- !Name "Increment death counter"
-- !Section "Multiplayer (Arena)"
-- !Description "Adds 1 to the death counter of the local player."
LevelFuncs.Engine.Node.MP_IncrementDeathCounter = function()
    local v = mp_arenaVars()
    v.deathCount = (v.deathCount or 0) + 1
end

-- !Name "Reset death counter"
-- !Section "Multiplayer (Arena)"
-- !Description "Sets the death counter of the local player to 0."
LevelFuncs.Engine.Node.MP_ResetDeathCounter = function()
    mp_arenaVars().deathCount = 0
end

-- !Name "Broadcast death count"
-- !Section "Multiplayer (Arena)"
-- !Description "Sends the death counter of the local player to the other players on the next frame."
LevelFuncs.Engine.Node.MP_BroadcastDeathCount = function()
    mp_arenaVars().pendingDeathBcast = true
end

-- !Name "If local player has least deaths"
-- !Section "Multiplayer (Arena)"
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
-- !Section "Multiplayer (Arena)"
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

-- !Name "If I am the match host"
-- !Section "Multiplayer (Arena)"
-- !Conditional "True"
-- !Description "Checks if the local player is the match host."
LevelFuncs.Engine.Node.MP_Arena_IAmHost = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    return ok and Arena and Arena.IAmHost() == true
end

-- !Name "End current round"
-- !Section "Multiplayer (Arena)"
-- !Description "Ends the round. Only the host acts on it."
LevelFuncs.Engine.Node.MP_Arena_EndRound = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.EndRound() end
end

-- !Name "Signal fight start (arena)"
-- !Section "Multiplayer (Arena)"
-- !Description "Starts the fighting phase. Place it first in the arena_fight_start global event set."
LevelFuncs.Engine.Node.MP_Arena_OnFightStart = function()
    local ok, Arena = pcall(require, "Engine.Arena")
    if ok and Arena then Arena.StartFighting() end
end
