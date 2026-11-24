---@diagnostic disable: undefined-global

local function getAllDoubles()
    local ok, doubles = pcall(TEN.Objects.GetMoveablesBySlot, TEN.Objects.ObjID.LARA_DOUBLE)
    return (ok and doubles) or {}
end

-- !Name "If any remote player is connected..."
-- !Section "Multiplayer (Remote Players)"
-- !Conditional "True"
-- !Description "Checks if at least one remote player object exists in the level."
LevelFuncs.Engine.Node.MP_AnyDoubleConnected = function()
    return #getAllDoubles() > 0
end
