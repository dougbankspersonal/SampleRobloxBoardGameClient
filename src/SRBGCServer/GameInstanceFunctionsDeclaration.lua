--[[
A static table describing server-side functions for each game in the experience.
Passed into ServerStartUp.ServerStartUp from RobloxBoardGame.
There must be a 1-1 mapping between elements in this table and the games in GameDetailsDeclaration.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameDetailsDeclaration = require(SRBGCShared.GameDetailsDeclaration)

-- SRBGCServer
local SRBGCServer = script.Parent
local GameStartup = require(SRBGCServer.Modules.MockGame.GameStartup)

local GameInstanceFunctionsDeclaration = {}

local gameInstanceFunctionsByGameId = {} :: CommonTypes.GameInstanceFunctionsByGameId

GameInstanceFunctionsDeclaration.addMockGames = function()
    local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()

    for gameId, _ in gameDetailsByGameId do
        local mockGameInstanceFunctions = {
            onPlay = GameStartup.onPlay,
            onEnd = function()
                print("Mock game is ended")
            end,
            onPlayerLeft = function(userId: CommonTypes.UserId)
                print("Player left mock game")
            end,
        }
        gameInstanceFunctionsByGameId[gameId] = mockGameInstanceFunctions
    end
end

GameInstanceFunctionsDeclaration.getGameInstanceFunctionsByGameId = function() : CommonTypes.GameInstanceFunctionsByGameId
    return gameInstanceFunctionsByGameId
end

return GameInstanceFunctionsDeclaration
