local ReplicatedStorage =  game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameServer
local RobloxBoardGameServer = ServerScriptService.RobloxBoardGameServer
local ServerStartUp = require(RobloxBoardGameServer.StartupFiles.ServerStartUp)
local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)
local DebugStateHandler = require(RobloxBoardGameServer.Modules.DebugStateHandler)

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- SRBGCServer
local SRBGCServer = ServerScriptService.SRBGCServer
local ServerGameInstanceConstructorsDeclaration = require(SRBGCServer.ServerGameInstanceConstructorsDeclaration)

assert(GameDetailsDeclaration.getGameDetailsByGameId() ~= nil, ", GameDetailsDeclaration.getGameDetailsByGameId() is nil")
assert(ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() ~= nil, "ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() is nil")

GameDetailsDeclaration.addMockGames()
ServerGameInstanceConstructorsDeclaration.addMockGames()

local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()
local serverGameInstanceConstructorsByGameId = ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId()

ServerStartUp.ServerStartUp(gameDetailsByGameId, serverGameInstanceConstructorsByGameId)

local function mockEndOfGame()
    local gameIds = Cryo.Dictionary.keys(gameDetailsByGameId)
    -- Sort em so it's deterministic.
    gameIds = Cryo.List.sort(gameIds)
    local gameId = gameIds[1]

    -- Make an instance of the game.
    local gameTable = DebugStateHandler.enterDebugState(Utils.RealPlayerUserId, {
        gameId = gameId,
        startGame = true,
    })
    local serverGameInstance = gameTable:getServerGameInstance()
    assert(serverGameInstance, "serverGameInstance is nil")

    -- Jump to some final state.
    serverGameInstance:runMockGame()
end

-- Do any debug setup we want to do.
if RunService:IsStudio() then
    -- mockEndOfGame()
end
