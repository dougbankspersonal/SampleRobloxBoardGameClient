-- A place to store server-side game instances.
-- Moved out from ServerGameInstance file to avoid circular dependencies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCServer
local SRBGCServer = script.Parent.Parent.Parent
local ServerTypes = require(SRBGCServer.Modules.MockGame.ServerTypes)

local ServerGameInstanceStorage = {}

local serverGameInstancesByGameInstanceGUID = {} :: {[CommonTypes.GameInstanceGUID]: ServerTypes.ServerGameInstance}

ServerGameInstanceStorage.storeServerGameInstance = function(serverGameInstance: ServerTypes.ServerGameInstance)
    assert(serverGameInstance, "serverGameInstance is nil")
    assert(serverGameInstance.tableDescription, "serverGameInstance.tableDescription is nil")
    assert(serverGameInstance.tableDescription.gameInstanceGUID, "serverGameInstance.tableDescription.gameInstanceGUID is nil")
    serverGameInstancesByGameInstanceGUID[serverGameInstance.tableDescription.gameInstanceGUID] = serverGameInstance
end

ServerGameInstanceStorage.getServerGameInstance = function(gameInstanceGUID: CommonTypes.GameInstanceGUID): ServerTypes.ServerGameInstance?
    assert(gameInstanceGUID, "gameInstanceGUID is nil")
    return serverGameInstancesByGameInstanceGUID[gameInstanceGUID]
end

ServerGameInstanceStorage.removeServerGameInstance = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    assert(gameInstanceGUID, "gameInstanceGUID is nil")
    assert(serverGameInstancesByGameInstanceGUID[gameInstanceGUID], "serverGameInstance not found")
    serverGameInstancesByGameInstanceGUID[gameInstanceGUID] = nil
end

return ServerGameInstanceStorage