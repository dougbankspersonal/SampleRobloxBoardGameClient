--[[
A static table describing server-side functions for each game in the experience.
Passed into ServerStartUp.ServerStartUp from RobloxBoardGame.
There must be a 1-1 mapping between elements in this table and the games in GameDetailsDeclaration.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCClient
local SRBGCClient = StarterGui.MainScreenGui.SRBGCClient
local ClientGameInstance = require(SRBGCClient.MockGame.Classes.ClientGameInstance)

local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local ClientGameInstanceFunctionsDeclaration = {}

local clientGameInstanceFunctionsByGameId = {} :: CommonTypes.ClientGameInstanceFunctionsByGameId

ClientGameInstanceFunctionsDeclaration.addMockGames = function()
    for gameId, _ in GameDetailsDeclaration.getGameDetailsByGameId() do
        clientGameInstanceFunctionsByGameId[gameId] = {
            makeClientGameInstanceAsync = function(tableDescription, parentFrame)
                local cgi = ClientGameInstance.new(tableDescription)
                cgi:buildUIAsync(parentFrame)
                return cgi
            end,
            getClientGameInstance = ClientGameInstance.get,
            renderAnalyticsRecords = function(parent: Frame, records: {CommonTypes.AnalyticsRecord})
                ClientGameInstance.renderAnalyticsRecords(gameId, parent, records)
            end,
        }
    end
end

ClientGameInstanceFunctionsDeclaration.getClientGameInstanceFunctionsByGameId = function() : CommonTypes.ClientGameInstanceFunctionsByGameId
    return clientGameInstanceFunctionsByGameId
end

return ClientGameInstanceFunctionsDeclaration
