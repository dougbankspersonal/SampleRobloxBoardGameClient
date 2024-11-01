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
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCServer
local SRBGCServer = ServerScriptService.SRBGCServer
local ServerGameInstanceConstructorsDeclaration = require(SRBGCServer.ServerGameInstanceConstructorsDeclaration)
local ServerTypes = require(SRBGCServer.MockGame.Types.ServerTypes)

assert(GameDetailsDeclaration.getGameDetailsByGameId() ~= nil, ", GameDetailsDeclaration.getGameDetailsByGameId() is nil")
assert(ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() ~= nil, "ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() is nil")

GameDetailsDeclaration.addMockGames()
ServerGameInstanceConstructorsDeclaration.addMockGames()

local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()
local serverGameInstanceConstructorsByGameId = ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId()

ServerStartUp.ServerStartUp(gameDetailsByGameId, serverGameInstanceConstructorsByGameId)

local function getDeterministicGameId(): CommonTypes.GameId
    local gameIds = Cryo.Dictionary.keys(gameDetailsByGameId)
    -- Sort em so it's deterministic.
    gameIds = Cryo.List.sort(gameIds)
    return gameIds[1]
end

local function mockStartOfGame(): ServerTypes.ServerGameInstance
    local gameId = getDeterministicGameId()

    -- Make an instance of the game.
    local gameTable = DebugStateHandler.enterDebugState(Utils.RealPlayerUserId, {
        gameId = gameId,
        startGame = true,
    })
    local serverGameInstance = gameTable:getServerGameInstance()
    assert(serverGameInstance, "serverGameInstance is nil")

    return serverGameInstance
end

local function mockEndOfGame()
    local serverGameInstance = mockStartOfGame()

    -- Jump to some final state.
    serverGameInstance:runMockGame()
end

local function mockGameConfigDialog()
    local gameId = getDeterministicGameId()

    -- Make an instance of the table, waiting for game to start.
    DebugStateHandler.enterDebugState(Utils.RealPlayerUserId, {
        gameId = gameId,
        startGame = false,
    })
end

-- Do any debug setup we want to do.
if RunService:IsStudio() then
    mockStartOfGame()
end
