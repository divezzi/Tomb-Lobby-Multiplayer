---@diagnostic disable: undefined-global

-- !Name "Register checkpoint (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Registers the next checkpoint of the local player. Use one event set for every checkpoint volume and set its call count to infinite, because the count is shared by all volumes that use the event set."
LevelFuncs.Engine.Node.TB_Checkpoint = function()
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.CheckpointReached() end
end

-- !Name "Register checkpoint by number (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Registers the checkpoint with the given stage number. Use it where the automatic count would be wrong, such as optional pads or alternate routes."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 99 ], Stage number being entered"
LevelFuncs.Engine.Node.TB_CheckpointNumbered = function(stageNumber)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetCheckpoint(stageNumber) end
end

-- !Name "Hazard: teleport to last checkpoint (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Moves the local player to the last checkpoint, restores their hit points, clears poison and counts a death. The tag is only printed in the console."
-- !Arguments "NewLine, String, 70, Debug tag for the console (optional)"
LevelFuncs.Engine.Node.TB_HazardRespawn = function(tag)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.RespawnAtCheckpoint(tag) end
end

-- !Name "Finish the run (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Ends the run of the local player: stops the timer and shows the results card. Ignored once the run is finished."
LevelFuncs.Engine.Node.TB_Finish = function()
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.Finish() end
end

-- !Name "Define total stage count (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Sets the total of the 'Stage X / N' counter. Place it in the level start event set."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 99 ], Total number of stages"
LevelFuncs.Engine.Node.TB_DefineTotalStages = function(n)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetTotalStages(n) end
end

-- !Name "Define checkpoint sound (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Sets the sound played when a new checkpoint is registered. The sound has to be included in the level, for example by selecting it in the Sound Infos window."
-- !Arguments "NewLine, Numerical, 40, [ 0 | 4095 ], Sound ID (Tomb Editor Sound Infos)"
LevelFuncs.Engine.Node.TB_DefineCheckpointSound = function(soundID)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetCheckpointSound(soundID) end
end

-- !Name "Define hazard death sound (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Sets the sound played when the player dies to a hazard. The sound has to be included in the level, for example by selecting it in the Sound Infos window."
-- !Arguments "NewLine, Numerical, 40, [ 0 | 4095 ], Sound ID (Tomb Editor Sound Infos)"
LevelFuncs.Engine.Node.TB_DefineHazardSound = function(soundID)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetHazardSound(soundID) end
end

-- !Name "Define end sound (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Sets the sound played when the run is finished. The sound has to be included in the level, for example by selecting it in the Sound Infos window."
-- !Arguments "NewLine, Numerical, 40, [ 0 | 4095 ], Sound ID (Tomb Editor Sound Infos)"
LevelFuncs.Engine.Node.TB_DefineEndSound = function(soundID)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetEndSound(soundID) end
end

-- !Name "Define finish message (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Sets the text of the results card. {time}, {deaths}, {best} and {newbest} are replaced when the run is finished, and \n is a line break."
-- !Arguments "NewLine, 90, String, Finish text ( {time} {deaths} {best} {newbest}, \n = line break )"
LevelFuncs.Engine.Node.TB_DefineFinishMessage = function(text)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetFinishMessage(text) end
end

-- !Name "Force fly cheat off (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Keeps the fly cheat off for the whole level, also after the finish."
LevelFuncs.Engine.Node.TB_ForceFlyOff = function()
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetFlyPolicy("off") end
end

-- !Name "Force fly cheat on (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Keeps the fly cheat on for the whole level."
LevelFuncs.Engine.Node.TB_ForceFlyOn = function()
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetFlyPolicy("on") end
end

-- !Name "Grant fly cheat when obby complete (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Turns the fly cheat on once the run is finished. Undoes 'Force fly cheat off' and 'Force fly cheat on'."
LevelFuncs.Engine.Node.TB_GrantFlyOnComplete = function()
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetFlyPolicy("auto") end
end

-- !Name "Define fly-cheat chat phrase (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Sets the chat phrase that turns the fly cheat on."
-- !Arguments "NewLine, String, 70, Chat phrase that unlocks fly (default: flycheatenable)"
LevelFuncs.Engine.Node.TB_DefineFlyCheatPhrase = function(phrase)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.SetFlyCheatPhrase(phrase) end
end

-- !Name "Allow teleport after completion (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Description "Refuses the teleport to another player until the local player finishes the run. Place it in the level start event set."
LevelFuncs.Engine.Node.TB_AllowTeleportAfterCompletion = function()
    local ok, Tblock = pcall(require, "Engine.Tblock")
    if ok and Tblock then Tblock.EnableTeleportAfterCompletion() end
end

-- !Name "If reached checkpoint is at least... (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Conditional "True"
-- !Description "Checks if the highest checkpoint reached by the local player is at least the given stage."
-- !Arguments "NewLine, Numerical, 30, [ 1 | 99 ], Stage number required"
LevelFuncs.Engine.Node.TB_IfCheckpointAtLeast = function(n)
    local ok, Tblock = pcall(require, "Engine.Tblock")
    return ok and Tblock ~= nil and Tblock.GetCheckpoint() >= (tonumber(n) or 0)
end

-- !Name "If the run is finished (TBlocks)"
-- !Section "Multiplayer (TBlocks)"
-- !Conditional "True"
-- !Description "Checks if the local player has finished the run."
LevelFuncs.Engine.Node.TB_IfFinished = function()
    local ok, Tblock = pcall(require, "Engine.Tblock")
    return ok and Tblock ~= nil and Tblock.IsFinished()
end
