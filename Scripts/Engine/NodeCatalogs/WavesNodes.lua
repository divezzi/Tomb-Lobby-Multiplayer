---@diagnostic disable: undefined-global

local function mp_arenaVars()
    LevelVars.Engine       = LevelVars.Engine or {}
    LevelVars.Engine.Arena = LevelVars.Engine.Arena or {}
    return LevelVars.Engine.Arena
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
