--[[
Enumerated type for ActionTypes.
We have different actions a user can take.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)

local ActionTypes: GameTypes.ActionType = {
    RollDie = 0,
} :: GameTypes.ActionTypes

return ActionTypes