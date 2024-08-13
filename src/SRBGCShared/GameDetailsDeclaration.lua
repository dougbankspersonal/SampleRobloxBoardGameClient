local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameDetailsDeclaration = {}

local mockGame1Variants =  {
    {
        name = "Normal",
        description = "The normal game variant.",
    },
    {
        name = "Quick",
        description = "Game variant for faster play",
    },
    {
        name = "Complex",
        description = "More depth and strategy",
    },
} :: {CommonTypes.GameOptionVariant}

local mockGame1Options = {
    {
        name = "\"Zombie\" Expansion",
        gameOptionId = "Zombie_boolean",
        description = "Adds zombies.",
    },
    {
        name = "Mock Game Variants",
        gameOptionId = "Game_variants",
        description = "Select different play modes.",
        opt_variants = mockGame1Variants,
    },
} :: {CommonTypes.GameOption}

local gameDetailsByGameId: CommonTypes.GameDetailsByGameId = {}

local mockImages = {
    "http://www.roblox.com/asset/?id=12899280578",
    "http://www.roblox.com/asset/?id=6233948090",
    "http://www.roblox.com/asset/?id=133537141",
    "http://www.roblox.com/asset/?id=6253829628",
}

local mockGameId = 1000

GameDetailsDeclaration.addMockGames = function()
    for i = 1, #mockImages do
        local gameId = mockGameId
        mockGameId = mockGameId + 1
        local mockGameDetails = {
            gameId = gameId,
            gameImage = mockImages[i],
            name = string.format("Mock Game #%d", i),
            description = string.format("This is mock game number %d", i),
            minPlayers = 2,
            maxPlayers = 2 + i,
        }
        if i == 1 then
            mockGameDetails.gameOptions = mockGame1Options
        end
        gameDetailsByGameId[gameId] = mockGameDetails
    end
end

GameDetailsDeclaration.getGameDetailsByGameId = function(): CommonTypes.GameDetailsByGameId
    return gameDetailsByGameId
end

return GameDetailsDeclaration