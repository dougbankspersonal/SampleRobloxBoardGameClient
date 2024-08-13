--[[
A static table describing server-side functions for each game in the experience.
Passed into ServerStartUp.ServerStartUp from RobloxBoardGame.
There must be a 1-1 mapping between elements in this table and the games in GameDetailsDeclaration.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local GameInstanceFunctionsDeclaration = {}

local gameInstanceFunctionsByGameId = {} :: CommonTypes.GameInstanceFunctionsByGameId


GameInstanceFunctionsDeclaration.addMockGames = function()
    local gameDetailsByGameId = GameDetailsDeclaration.getGameDetailsByGameId()

    for gameId, _ in gameDetailsByGameId do
        local mockGameInstanceFunctions = {
            onPlay = function()
                assert(false, "FIXME(dbanks) Implement mockGame.onPlay")
            end,
            onEnd = function()
                assert(false, "FIXME(dbanks) Implement mockGame.onEnd")
            end,
            onPlayerLeft = function(userId: CommonTypes.UserId)
                assert(false, "FIXME(dbanks) Implement mockGame.onPlayerLeft")
            end,
        }
        gameInstanceFunctionsByGameId[gameId] = mockGameInstanceFunctions
    end
end

GameInstanceFunctionsDeclaration.getGameInstanceFunctionsByGameId = function() : CommonTypes.GameInstanceFunctionsByGameId
    return gameInstanceFunctionsByGameId
end

return GameInstanceFunctionsDeclaration
