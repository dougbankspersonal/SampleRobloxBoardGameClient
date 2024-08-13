local ReplicatedStorage =  game:GetService("ReplicatedStorage")
local RobloxBoardGameServer = script.Parent.Parent.RobloxBoardGameServer
local ServerStartUp = require(RobloxBoardGameServer.StartupFiles.ServerStartUp)
local GameDetailsDeclaration = require(ReplicatedStorage.SFBGShared.GameDetailsDeclaration)

local SFBGServer = script.Parent
local GameInstanceFunctionsDeclaration = require(SFBGServer.GameInstanceFunctionsDeclaration)

assert(GameDetailsDeclaration.getGameDetailsByGameId() ~= nil, ", GameDetailsDeclaration.getGameDetailsByGameId() is nil")
assert(GameInstanceFunctionsDeclaration.getGameInstanceFunctionsByGameId() ~= nil, "GameDetailsDeclaration.getGameInstanceFunctionsByGameId() is nil")

GameDetailsDeclaration.addMockGames()
GameInstanceFunctionsDeclaration.addMockGames()

local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()
local gameInstanceFunctionsByGameId = GameInstanceFunctionsDeclaration.getGameInstanceFunctionsByGameId()

ServerStartUp.ServerStartUp(gameDetailsByGameId, gameInstanceFunctionsByGameId)
