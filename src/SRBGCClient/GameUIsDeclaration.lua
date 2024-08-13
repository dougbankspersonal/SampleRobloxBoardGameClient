--[[
A static table describing server-side functions for each game in the experience.
Passed into ServerStartUp.ServerStartUp from RobloxBoardGame.
There must be a 1-1 mapping between elements in this table and the games in GameDetailsDeclaration.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local GameUIsDeclaration = {}

local gameUIsByGameId = {} :: CommonTypes.GameUIsByGameId

GameUIsDeclaration.addMockGames = function()
    for gameId, _ in GameDetailsDeclaration.getGameDetailsByGameId() do
        local mockGameUIs = {
            setupUI = function()
                assert(false, "FIXME(dbanks) Implement mockGameUIs.setupUI")
            end,
        }
        gameUIsByGameId[gameId] = mockGameUIs
    end
end

GameUIsDeclaration.getGameUIsByGameId = function() : CommonTypes.GameUIsByGameId
    return gameUIsByGameId
end

return GameUIsDeclaration
