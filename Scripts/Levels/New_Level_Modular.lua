local Multiplayer = require("Engine.Multiplayer")

local DEBUG = true

local levelState = {
    isSaving = false
}

LevelFuncs = LevelFuncs or {}
LevelFuncs.Engine = LevelFuncs.Engine or {}

LevelFuncs.OnLoad = function()
    Multiplayer.OnLoad()
    Multiplayer.Reset()
    Multiplayer.Connect()
    levelState.isSaving = false
end

LevelFuncs.OnSave = function()
    Multiplayer.OnSave()
    levelState.isSaving = true
    Multiplayer.CleanupRemoteEntities()
    if DEBUG then print("Network objects destroyed before save.") end
end

LevelFuncs.OnStart = function()
    Multiplayer.Connect()
end

LevelFuncs.OnLoop = function(dt)
    if DEBUG and Multiplayer.GetFrameCounter() % 300 == 0 then
        print("Connected=" .. tostring(Multiplayer.IsConnected()) .. " MyID=" .. tostring(Multiplayer.GetMyId()) .. " Frame=" .. Multiplayer.GetFrameCounter())
    end

    if levelState.isSaving then
        levelState.isSaving = false
        Multiplayer.Connect()
        if DEBUG then print("Saving reset, network restored.") end
        return
    end

    Multiplayer.Update()

    if not Multiplayer.IsConnected() then
        if Multiplayer.GetDisconnectedTimer() % 60 == 0 then
            Multiplayer.Connect()
        end
        return
    end
end

LevelFuncs.OnEnd = function()
    Multiplayer.Disconnect()
    Multiplayer.CleanupRemoteEntities()
end

LevelFuncs.OnUseItem = function(item)
    if not Multiplayer.IsConnected() then
        Multiplayer.Connect()
    end
end

LevelFuncs.OnFreeze = function()
end







LevelFuncs.OnLaraSoundEffect = function(soundID, frameNumber)
    Multiplayer.HandleLaraSoundEffect(soundID, frameNumber)
end

LevelFuncs.Engine.connect = function()
    return Multiplayer.Connect()
end
_G.connect = LevelFuncs.Engine.connect
