---@diagnostic disable: undefined-global

local function mp_arenaVars()
    LevelVars.Engine       = LevelVars.Engine or {}
    LevelVars.Engine.Arena = LevelVars.Engine.Arena or {}
    return LevelVars.Engine.Arena
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
