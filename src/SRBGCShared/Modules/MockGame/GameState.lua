--[[
Utilities around the GameState structure.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)

local GameState = {}

function GameState.sanityCheck(gameState: GameTypes.GameState)
    assert(gameState, "gameState is nil")
    assert(gameState.playerIdsInTurnOrder, "playerIdsInTurnOrder is nil")
    assert(#gameState.playerIdsInTurnOrder > 0, "playerIdsInTurnOrder is empty")
    local playerIds = Cryo.Dictionary.keys(gameState.scoresByUserId)
    assert(#gameState.playerIdsInTurnOrder == #playerIds, "playerIdsInTurnOrder and scoresByUserId don't match")
    assert(gameState.currentPlayerIndex, "currentPlayerIndex is nil")
    assert(gameState.currentPlayerIndex >= 1, "currentPlayerIndex is less than 1")
    assert(gameState.currentPlayerIndex <= #gameState.playerIdsInTurnOrder, "currentPlayerIndex is greater than the number of players")
end

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

    GameState.sanityCheck(gameState)

    return retVal
end

-- Whose turn is it?
function GameState.getCurrentPlayerUserId(gameState: GameTypes.GameState): CommonTypes.UserId
    assert(gameState, "gameState is nil")
    assert(gameState.playerIdsInTurnOrder, "playerIdsInTurnOrder is nil")
    assert(gameState.currentPlayerIndex, "currentPlayerIndex is nil")
    assert(gameState.playerIdsInTurnOrder[gameState.currentPlayerIndex], "playerIdsInTurnOrder[currentPlayerIndex] is nil")

    return gameState.playerIdsInTurnOrder[gameState.currentPlayerIndex]
end

function GameState.getCurrentPlayerName(gameState: GameTypes.GameState): string
    local currentPlayerUserId = GameState.getCurrentPlayerUserId(gameState)
    return PlayerUtils.getName(currentPlayerUserId)
end

-- Initing a game state.
function GameState.createNewGameState(tableDescription: CommonTypes.TableDescription): GameTypes.GameState
    local gameState = {}

    gameState.scoresByUserId = {}
    Utils.debugPrint("Mocks", "createNewGameState tableDescription.memberUserIds", tableDescription.memberUserIds)
    for userId, _ in pairs(tableDescription.memberUserIds) do
        gameState.scoresByUserId[userId] = 0
    end

    gameState.playerIdsInTurnOrder = Cryo.Dictionary.keys(tableDescription.memberUserIds)
    gameState.playerIdsInTurnOrder = Utils.randomizeArray(gameState.playerIdsInTurnOrder)
    gameState.currentPlayerIndex = 1

    gameState.opt_winnerUserId = nil

    return gameState
end

return GameState