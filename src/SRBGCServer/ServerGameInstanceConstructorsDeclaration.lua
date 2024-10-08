--[[
A static table describing server-side functions for each game in the experience.
Passed into ServerStartUp.ServerStartUp from RobloxBoardGame.
There must be a 1-1 mapping between elements in this table and the games in GameDetailsDeclaration.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameDetailsDeclaration = require(SRBGCShared.GameDetailsDeclaration)

-- SRBGCServer
local SRBGCServer = ServerScriptService.SRBGCServer
local ServerGameInstance = require(SRBGCServer.MockGame.Classes.ServerGameInstance)

local ServerGameInstanceConstructorsDeclaration = {}

local serverGameInstanceConstructorsByGameId = {} :: CommonTypes.ServerGameInstanceConstructorsByGameId

ServerGameInstanceConstructorsDeclaration.addMockGames = function()
    local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()

    for gameId, _ in gameDetailsByGameId do
        serverGameInstanceConstructorsByGameId[gameId] = ServerGameInstance.new
    end
end

ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId = function() : CommonTypes.ServerGameInstanceConstructorsByGameId
    return serverGameInstanceConstructorsByGameId
end

return ServerGameInstanceConstructorsDeclaration
