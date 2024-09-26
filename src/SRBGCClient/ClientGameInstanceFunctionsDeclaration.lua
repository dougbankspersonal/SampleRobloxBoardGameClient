--[[
A static table describing server-side functions for each game in the experience.
Passed into ServerStartUp.ServerStartUp from RobloxBoardGame.
There must be a 1-1 mapping between elements in this table and the games in GameDetailsDeclaration.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCClient
local SRBGCClient = script.Parent
local ClientGameInstance = require(SRBGCClient.Modules.MockGame.ClientGameInstance)

local GameDetailsDeclaration = require(ReplicatedStorage.SRBGCShared.GameDetailsDeclaration)

local ClientGameInstanceFunctionsDeclaration = {}

local clientGameInstanceFunctionsByGameId = {} :: CommonTypes.ClientGameInstanceFunctionsByGameId

ClientGameInstanceFunctionsDeclaration.addMockGames = function()
    for gameId, _ in GameDetailsDeclaration.getGameDetailsByGameId() do
        clientGameInstanceFunctionsByGameId[gameId] = {
            makeClientGameInstance = function(tableDescription, parentFrame)
                local cgi = ClientGameInstance.new(tableDescription)
                cgi:asyncBuildUI(parentFrame)
            end,
            getClientGameInstance = ClientGameInstance.get,
        }
    end
end

ClientGameInstanceFunctionsDeclaration.getClientGameInstanceFunctionsByGameId = function() : CommonTypes.ClientGameInstanceFunctionsByGameId
    return clientGameInstanceFunctionsByGameId
end

return ClientGameInstanceFunctionsDeclaration
