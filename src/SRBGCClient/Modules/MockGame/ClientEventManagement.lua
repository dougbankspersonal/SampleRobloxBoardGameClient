--[[
Client side event management: listening to events from the server, sending events to server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local GameState = require(SRBGCShared.Modules.MockGame.GameState)
local GameEventUtils = require(SRBGCShared.Modules.MockGame.GameEventUtils)

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
        Utils.debugPrint("GamePlay", "ClientEventManagement GameUpdated raw_gameState = ", raw_gameState)
        Utils.debugPrint("GamePlay", "ClientEventManagement GameUpdated opt_actionDescriotion = ", opt_actionDescriotion)
        local clean_gameState = GameState.sanitizeGameState(raw_gameState)
        onGameStateUpdated(clean_gameState, opt_actionDescriotion)
    end)
end

-- A message from this client to server: the current player wants to roll die.
-- Works iff local player is current player, or current player is a mock and
-- local player is the host.
ClientEventManagement.requestDieRoll = function(gameInstanceGUID: CommonTypes.GameInstanceGUID, dieType: GameTypes.DieType)
    Utils.debugPrint("GamePlay", "ClientEventManagement.requestDieRoll ", dieType)
    local event = EventUtils.getRemoteEventForGame(gameInstanceGUID, GameEventUtils.EventName_DieRoll)
    assert(event, GameEventUtils.EventName_DieRoll .. " event missing")
    event:FireServer(dieType)
end

return ClientEventManagement