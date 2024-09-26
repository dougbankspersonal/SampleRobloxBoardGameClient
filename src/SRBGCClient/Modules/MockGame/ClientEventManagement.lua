--[[
Client side event management: listening to events from the server, sending events to server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local GameState= require(SRBGCShared.Modules.MockGame.GameState)


local ClientEventManagement = {}

-- Called on startup, get the initial game state.
ClientEventManagement.getGameStateAsync = function(gameInstanceGUID: CommonTypes.GameInstanceGUID): GameTypes.GameState
    local getGameStateRemoteFunc = EventUtils.getRemoteFunctionForGame(gameInstanceGUID, "GetGameState")
    assert(getGameStateRemoteFunc, "GetGameState remote function missing")
    local raw_gameState = getGameStateRemoteFunc:InvokeServer()
    local clean_gameState = GameState.sanitizeGameState(raw_gameState)
    return clean_gameState
end

ClientEventManagement.listenToServerEvents = function(gameInstanceGUID: CommonTypes.GameInstanceGUID, onGameStateUpdated: (GameTypes.GameState, GameTypes.ActionDescription?) -> ())
    -- When server tells us about new state call this function.
    local event = EventUtils.getRemoteEventForGame(gameInstanceGUID, "GameUpdated")
    assert(event, "GameUpdated event missing")
    event.OnClientEvent:Connect(function(raw_gameState: GameTypes.GameState, opt_actionDescriotion: GameTypes.ActionDescription?)
        local clean_gameState = GameState.sanitizeGameState(raw_gameState)
        onGameStateUpdated(clean_gameState, opt_actionDescriotion)
    end)
end

-- Tell the server this party wants to roll the die.
ClientEventManagement.requestRollDie = function(gameInstanceGUID: CommonTypes.GameInstanceGUID, dieType: GameTypes.DieType)
    local event = EventUtils.getRemoteEventForGame(gameInstanceGUID, "RollDie")
    assert(event, "RollDie event missing")
    event:FireServer(dieType)
end

return ClientEventManagement