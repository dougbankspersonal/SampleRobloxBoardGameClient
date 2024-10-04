local ReplicatedStorage =  game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameServer
local RobloxBoardGameServer = script.Parent.Parent.RobloxBoardGameServer
local ServerStartUp = require(RobloxBoardGameServer.StartupFiles.ServerStartUp)
local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)
local DebugStateHandler = require(RobloxBoardGameServer.Modules.DebugStateHandler)

-- SRBGCServer
local SRBGCServer = script.Parent
local ServerGameInstanceConstructorsDeclaration = require(SRBGCServer.ServerGameInstanceConstructorsDeclaration)

assert(GameDetailsDeclaration.getGameDetailsByGameId() ~= nil, ", GameDetailsDeclaration.getGameDetailsByGameId() is nil")
assert(ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() ~= nil, "ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() is nil")

GameDetailsDeclaration.addMockGames()
ServerGameInstanceConstructorsDeclaration.addMockGames()

local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()
local serverGameInstanceConstructorsByGameId = ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId()

-- FIXME(dbanks)
-- There should be some better way to do this.
-- If you're in a plugin you can ask for the id of the user logged in to Studio, but
-- this is not a plugin.
-- Hardwiring to my account id.
local RealPlayerUserId = 5845980262

ServerStartUp.ServerStartUp(gameDetailsByGameId, serverGameInstanceConstructorsByGameId)

-- Do any debug setup we want to do.
if RunService:IsStudio() then
    -- See CommonTypes.lua DebugStateConfigs for details on what configs can be set here.
    local gameIds = Cryo.Dictionary.keys(gameDetailsByGameId)
    local gameId = gameIds[1]

    -- Make an instance of thhe game,
    local gameTable = DebugStateHandler.enterDebugState(RealPlayerUserId, {
        gameId = gameId,
        startGame = true,
    })
    local serverGameInstance = gameTable:getServerGameInstance()
    assert(serverGameInstance, "serverGameInstance is nil")

    -- Jump to some final state.
    serverGameInstance:mockEndGame()
end
