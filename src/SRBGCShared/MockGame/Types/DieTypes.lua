--[[
Enumerated type for DieTypes.
We have different types of dice.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.MockGame.Types.GameTypes)

local DieTypes = {}

DieTypes.Types = {
    Standard = 0,
    Smushed = 1,
    Advantage = 2,
} :: GameTypes.DieTypes

DieTypes.NumDieTypes = #Cryo.Dictionary.keys(DieTypes.Types)

return DieTypes