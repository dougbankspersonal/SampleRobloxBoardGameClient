local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameDetailsDeclaration = {}

local mockRulesVariants =  {
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

local mockColorVariants = {
    {
        name = "Red",
        description = "Like a cherry.",
    },
    {
        name = "Green",
        description = "Grass is green",
    },
    {
        name = "Blue",
        description = "Azul in Spanish",
    },
}

local mockGameOptions = {
    {
        name = "\"Alpha\" Expansion",
        gameOptionId = "Alpha_boolean",
        description = "The \"Alpha\" expansion introduces auctions and agendas.",
    },
    {
        name = "\"Bravo\" Expansion",
        gameOptionId = "Bravo_boolean",
        description = "The \"Bravo\" expansion introduces trade and guilds.",
    },
    {
        name = "Rules Variants",
        gameOptionId = "Rules_Variants",
        opt_variants = mockRulesVariants,
    },
    {
        name = "Color Schemes",
        gameOptionId = "Color_Schemes",
        opt_variants = mockColorVariants,
    },
}

local gameDetailsByGameId: CommonTypes.GameDetailsByGameId = {}

local mockImages = {
    "http://www.roblox.com/asset/?id=12899280578",
    "http://www.roblox.com/asset/?id=6233948090",
    "http://www.roblox.com/asset/?id=133537141",
    "http://www.roblox.com/asset/?id=6253829628",
}

local mockNames = {
    "Zombies",
    "Cupcake Aventure",
    "Cosmic Encounter",
    "Illuminati",
    "Settlers of Catan",
    "Monopoly",
    "Risk",
    "Clue",
    "Sagrada",
    "Betrayal at the House on the Hill",
    "Mansions of Madness",
    "Telestrations",
    "Pictionary",
    "Carcassonne",
    "Ticket to Ride",
    "Scrabble",
    "Battleship",
    "Connect Four",
    "Chess",
    "Checkers",
    "Go",
    "Backgammon",
}

local mockGameId = 1000

GameDetailsDeclaration.addMockGames = function()
    for i = 1, #mockNames do
        local gameId = mockGameId
        mockGameId = mockGameId + 1
        local mockGameDetails = {
            gameId = gameId,
            gameImage = mockImages[i % #mockImages + 1],
            name = mockNames[i],
            description = string.format("This is mock game number %d", i),
            minPlayers = 2,
            maxPlayers = 2 + (i % 6 + 1),
        }
        mockGameDetails.gameOptions = mockGameOptions
        gameDetailsByGameId[gameId] = mockGameDetails
    end
end

GameDetailsDeclaration.getGameDetailsByGameId = function(): CommonTypes.GameDetailsByGameId
    return gameDetailsByGameId
end

return GameDetailsDeclaration