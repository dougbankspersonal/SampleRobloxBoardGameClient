local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local DieTypes = require(SRBGCShared.Modules.MockGame.DieTypes)

local GameUtils = {}

function GameUtils.getDieName(dieType: GameTypes.DieType): string
    if dieType == DieTypes.Standard then
        return "Standard"
    elseif dieType == DieTypes.Smushed then
        return "Smushed"
    elseif dieType == DieTypes.Advantage then
        return "Advantage"
    else
        error("Unknown die type: " .. dieType)
    end
end

return GameUtils