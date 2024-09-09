--[[
A static table describing server-side functions for each game in the experience.
Passed into ServerStartUp.ServerStartUp from RobloxBoardGame.
There must be a 1-1 mapping between elements in this table and the games in GameDetailsDeclaration.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RBGBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules     .Utils)

local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local GameUIsDeclaration = {}

local gameUIsByGameId = {} :: CommonTypes.GameUIsByGameId

GameUIsDeclaration.addMockGames = function()
    for gameId, _ in GameDetailsDeclaration.getGameDetailsByGameId() do
        local mockGameUIs = {
            build = function()
                Utils.debugPrint("TablePlaying", "Doug: in mock build")
            end,
            destroy = function()
                Utils.debugPrint("TablePlaying", "Doug: in mock destroy")
            end,
            handlePlayerLeftGame = function()
                Utils.debugPrint("TablePlaying", "Doug: in mock handlePlayerLeftGame")
            end,
        }
        gameUIsByGameId[gameId] = mockGameUIs
    end
end

GameUIsDeclaration.getGameUIsByGameId = function() : CommonTypes.GameUIsByGameId
    return gameUIsByGameId
end

return GameUIsDeclaration
