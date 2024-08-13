local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameDetailsDeclaration = require(ReplicatedStorage.SFBGShared.GameDetailsDeclaration)

local RobloxBoardGameStarterGui = script.Parent.Parent.RobloxBoardGameStarterGui
local ClientStartUp = require(RobloxBoardGameStarterGui.StartupFiles.ClientStartUp)

local SFBGClient = script.Parent
local GameUIsDeclaration = require(SFBGClient.GameUIsDeclaration)

local screenGui = script.Parent.Parent

assert(screenGui:IsA("ScreenGui"), "screenGui should exist and be a screenGui")

GameDetailsDeclaration.addMockGames()
GameUIsDeclaration.addMockGames()

ClientStartUp.ClientStartUp(screenGui, GameDetailsDeclaration.getGameDetailsByGameId(), GameUIsDeclaration.getGameUIsByGameId())
