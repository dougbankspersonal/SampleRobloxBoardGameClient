local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)

local GameState = {}

--[[
Sending game state over the wire corrupts it: indicies that should be numbers become strings.
Fix it.
]]
GameState.sanitizeGameState = function(gameState: GameTypes.GameState): GameTypes.GameState
    local retVal = Cryo.Dictionary.join(gameState, {})

    retVal.scoresByUserId = {}
    for stringUserId, score in gameState.scoresByUserId do
        retVal.scoresByUserId[tonumber(stringUserId)] = score
    end
    return retVal
end

return GameState