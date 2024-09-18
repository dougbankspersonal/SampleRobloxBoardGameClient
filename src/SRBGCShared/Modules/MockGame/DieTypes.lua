--[[
Enumerated type for DieTypes.
We have different types of dice.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)

local DieTypes: GameTypes.DieTypes = {
    Standard = 0,
    Smushed = 1,
    Advantage = 2,
} :: GameTypes.DieTypes

return DieTypes