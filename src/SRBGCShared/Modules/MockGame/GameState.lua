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

    GameState.sanityCheck(retVal)

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

function GameState.sanityCheck(gameState: GameTypes.GameState)
    assert(gameState, "gameState is nil")
    assert(gameState.playerIdsInTurnOrder, "playerIdsInTurnOrder is nil")
    assert(gameState.currentPlayerIndex, "currentPlayerIndex is nil")

    assert(#gameState.playerIdsInTurnOrder > 0, "playerIdsInTurnOrder is empty")

    local scoreUserIds = Cryo.Dictionary.keys(gameState.scoresByUserId)
    Utils.debugPrint("SanityChecks", "scoreUserIds = ", scoreUserIds)
    Utils.debugPrint("SanityChecks", "gameState.playerIdsInTurnOrder = ", gameState.playerIdsInTurnOrder)
    for _, userId in ipairs(gameState.playerIdsInTurnOrder) do
        assert(typeof(userId) == "number", "GameState.sanityCheck: playerIdsInTurnOrder has a non-number key")
    end
    for userId, _ in pairs(gameState.scoresByUserId) do
        assert(typeof(userId) == "number", "GameState.sanityCheck: scoresByUserId has a non-number key")
    end
    assert(Utils.unsortedListsMatch(scoreUserIds, gameState.playerIdsInTurnOrder), "GameState.sanityCheck: scoresByUserId and playerIdsInTurnOrder don't match")

    assert(gameState.currentPlayerIndex >= 1, "GameState.sanityCheck: currentPlayerIndex is less than 1")
    assert(gameState.currentPlayerIndex <= #gameState.playerIdsInTurnOrder, "GameState.sanityCheck: currentPlayerIndex is greater than the number of players")

    for userId, _ in pairs(gameState.scoresByUserId) do
        assert(typeof(userId) == "number", "GameState.sanityCheck: scoresByUserId has a non-number key")
    end
    for _, userId in ipairs(gameState.playerIdsInTurnOrder) do
        assert(typeof(userId) == "number", "GameState.sanityCheck: playerIdsInTurnOrder has a non-number key")
    end
end

return GameState