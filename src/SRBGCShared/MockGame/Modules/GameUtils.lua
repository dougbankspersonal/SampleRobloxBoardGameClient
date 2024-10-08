local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.MockGame.Types.GameTypes)
local DieTypes = require(SRBGCShared.MockGame.Types.DieTypes)

local GameUtils = {}

function GameUtils.getDieName(dieType: GameTypes.DieType): string
    if dieType == DieTypes.Types.Standard then
        return "Standard"
    elseif dieType == DieTypes.Types.Smushed then
        return "Smushed"
    elseif dieType == DieTypes.Types.Advantage then
        return "Advantage"
    else
        error("Unknown die type: " .. dieType)
    end
end

return GameUtils