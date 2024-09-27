local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local DieTypes = require(SRBGCShared.Modules.MockGame.DieTypes)

local GameUtils = {}

function GameUtils.firstUserCanPlayAsSecondUser(tableDescription: CommonTypes.TableDescription, firstUserId: CommonTypes.UserId, secondUserId:CommonTypes.UserId): boolean
    -- Better be a member of the game.
    assert(firstUserId, "firstUserId is nil")
    assert(secondUserId, "secondUserId is nil")

    -- If current player is attemped actor, fine.
    if firstUserId == secondUserId then
        return true
    end
    -- If current player is mock and attempted actor is host, fine.
    if tableDescription.hostUserId == firstUserId and tableDescription.mockUserIds[secondUserId] then
        return true
    end

    -- No good.
    return false
end

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