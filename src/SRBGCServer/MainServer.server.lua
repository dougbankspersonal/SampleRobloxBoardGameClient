local ReplicatedStorage =  game:GetService("ReplicatedStorage")
local RobloxBoardGameServer = script.Parent.Parent.RobloxBoardGameServer
local ServerStartUp = require(RobloxBoardGameServer.StartupFiles.ServerStartUp)
local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local SRBGCServer = script.Parent
local ServerGameInstanceConstructorsDeclaration = require(SRBGCServer.ServerGameInstanceConstructorsDeclaration)

assert(GameDetailsDeclaration.getGameDetailsByGameId() ~= nil, ", GameDetailsDeclaration.getGameDetailsByGameId() is nil")
assert(ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() ~= nil, "ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId() is nil")

GameDetailsDeclaration.addMockGames()
ServerGameInstanceConstructorsDeclaration.addMockGames()

local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()
local serverGameInstanceConstructorsByGameId = ServerGameInstanceConstructorsDeclaration.getServerGameInstanceConstructorsByGameId()

ServerStartUp.ServerStartUp(gameDetailsByGameId, serverGameInstanceConstructorsByGameId)
