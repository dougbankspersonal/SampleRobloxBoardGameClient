local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local RobloxBoardGameClient = script.Parent.Parent.RobloxBoardGameClient
local ClientStartUp = require(RobloxBoardGameClient.StartupFiles.ClientStartUp)

local SRBGCClient = StarterGui.MainScreenGui.SRBGCClient
local ClientGameInstanceFunctionsDeclaration = require(SRBGCClient.ClientGameInstanceFunctionsDeclaration)

local screenGui = script.Parent.Parent

assert(screenGui:IsA("ScreenGui"), "screenGui should exist and be a screenGui")

GameDetailsDeclaration.addMockGames()
ClientGameInstanceFunctionsDeclaration.addMockGames()

ClientStartUp.ClientStartUp(screenGui, GameDetailsDeclaration.getGameDetailsByGameId(),
    ClientGameInstanceFunctionsDeclaration.getClientGameInstanceFunctionsByGameId())
