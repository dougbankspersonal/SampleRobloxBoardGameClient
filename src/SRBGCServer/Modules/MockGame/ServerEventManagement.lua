--[[
Logic for creating and handling events on the server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- Server
local RobloxBoardGameServer = script.Parent.Parent.Parent.Parent.RobloxBoardGameServer
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)

-- SRBGCServer
local SRBGCServer = script.Parent.Parent.Parent
local ServerTypes = require(SRBGCServer.Modules.MockGame.ServerTypes)
local ServerGameInstanceStorage = require(SRBGCServer.Modules.MockGame.ServerGameInstanceStorage)

local ServerEventManagement = {}

ServerEventManagement.broadcastGameState = function(serverGameInstance:ServerTypes.ServerGameInstance, opt_actionDescription: GameTypes.ActionDescription?)
    local gameState = serverGameInstance:getGameState()
    ServerEventUtils.sendEventForPlayersInGame(serverGameInstance, "GameUpdated", gameState, opt_actionDescription)
end

--[[
Startup Function making all the events where client sends to server.
]]
ServerEventManagement.setupGameInstanceEventsAndFunctions = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    -- Remote function to fetch game state.
    ServerEventUtils.createGameRemoteFunction(gameInstanceGUID, "GetGameState", function(player: Player): GameTypes.GameState
        local gameInstance = ServerGameInstanceStorage.getServerGameInstance(gameInstanceGUID)
        if not gameInstance then
            return nil
        end
        if not gameInstance:isPlayerInGame(player.UserId) then
            return nil
        end
        local gameState = gameInstance:getGameState()
        return gameState
    end)

    ServerEventUtils.createGameRemoteEvent(gameInstanceGUID, "RollDie", function(player: Player, dieType: GameTypes.DieType)
        -- add the logic for die roll here.
        local gameInstance = ServerGameInstanceStorage.getServerGameInstance(gameInstanceGUID)
        assert(gameInstance, "Game instance not found for " .. gameInstanceGUID)
        local currentPlayerUserId = gameInstance:getCurrentPlayerUserId()
        if not gameInstance:isPlayerInGame(player.UserId) then
            return nil
        end

        local success, result = gameInstance:rollDie(player.UserId, dieType)
        if success then
            local actionDescrition = {
                userId = currentPlayerUserId,
                action = "RollDie",
                result = result,
            }
            ServerEventManagement.broadcastGameState(gameInstance, actionDescrition)
        end
    end)

    -- Events sent from server to client.
    ServerEventUtils.createGameRemoteEvent(gameInstanceGUID, "GameUpdated")
end

return ServerEventManagement