--[[
Logic for creating and handling events on the server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- Server
local RobloxBoardGameServer = ServerScriptService.RobloxBoardGameServer
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.MockGame.Types.GameTypes)
local GameEventNames = require(SRBGCShared.MockGame.Globals.GameEventNames)

-- SRBGCServer
local SRBGCServer = ServerScriptService.SRBGCServer
local ServerTypes = require(SRBGCServer.MockGame.Types.ServerTypes)
local ServerGameInstanceStorage = require(SRBGCServer.MockGame.Modules.ServerGameInstanceStorage)

local ServerEventManagement = {}

ServerEventManagement.broadcastGameState = function(serverGameInstance:ServerTypes.ServerGameInstance, opt_actionDescription: GameTypes.ActionDescription?)
    local gameState = serverGameInstance:getGameState()
    ServerEventUtils.sendEventForPlayersInGame(serverGameInstance.tableDescription, "GameUpdated", gameState, opt_actionDescription)
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

    ServerEventUtils.createGameRemoteEvent(gameInstanceGUID, GameEventNames.EventNameRequestDieRoll, function(player: Player, dieType: GameTypes.DieType)
        assert(player, "Player is nil")
        assert(dieType, "dieType is nil")
        -- add the logic for die roll here.
        local gameInstance = ServerGameInstanceStorage.getServerGameInstance(gameInstanceGUID)
        assert(gameInstance, "Game instance not found for " .. gameInstanceGUID)

        local success, actionDescription = gameInstance:dieRoll(player.UserId, dieType)

        if success then
            ServerEventManagement.broadcastGameState(gameInstance, actionDescription)
        end
    end)

    -- Events sent from server to client.
    ServerEventUtils.createGameRemoteEvent(gameInstanceGUID, "GameUpdated")
end

return ServerEventManagement