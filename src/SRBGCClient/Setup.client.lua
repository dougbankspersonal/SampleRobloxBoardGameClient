local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local RobloxBoardGameStarterGui = script.Parent.Parent.RobloxBoardGameStarterGui
local ClientStartUp = require(RobloxBoardGameStarterGui.StartupFiles.ClientStartUp)

local SRBGCClient = script.Parent
local GameUIsDeclaration = require(SRBGCClient.GameUIsDeclaration)

local screenGui = script.Parent.Parent

assert(screenGui:IsA("ScreenGui"), "screenGui should exist and be a screenGui")

GameDetailsDeclaration.addMockGames()
GameUIsDeclaration.addMockGames()

ClientStartUp.ClientStartUp(screenGui, GameDetailsDeclaration.getGameDetailsByGameId(), GameUIsDeclaration.getGameUIsByGameId())
