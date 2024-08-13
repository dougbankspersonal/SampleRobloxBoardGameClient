local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameDetailsDeclaration = {}

GameDetailsDeclaration.nutsGameId = 1

local SquirrelMovementGameOptionVariants =  {
    {
        name = "Normal",
        description = "Stop (5), Hunt (5), Scamper (2)",
    },
    {
        name = "Aggressive",
        description = "Stop (3), Hunt (7), Scamper (2)",
    },
    {
        name = "Random",
        description = "Stop (4), Hunt (4), Scamper (4)",
    },
    {
        name = "Lazy",
        description = "Stop (7), Hunt (3), Scamper (2)",
    },
} :: {CommonTypes.GameOptionVariant}

local nutsGameOptions = {
    {
        name = "\"Schmoozing\" Expansion",
        gameOptionId = "Schmooze_boolean",
        description = "Players attend may gain powerful advantages by bribing the right people.",
    },
    {
        name = "Squirrel Movement Variants",
        gameOptionId = "Squirrel_variants",
        description = "Adjust how the squirrel move.",
        opt_variants = SquirrelMovementGameOptionVariants,
    },
} :: {CommonTypes.GameOption}

local nutsGameDetails: CommonTypes.GameDetails = {
    gameId = GameDetailsDeclaration.nutsGameId,
    gameImage = "http://www.roblox.com/asset/?id=6253829628",
    name = "Nuts",
    description = "Ship nuts, and watch out for that squirrel!.",
    minPlayers = 2,
    maxPlayers = 5,
    gameOptions = nutsGameOptions,
}

local gameDetailsByGameId: CommonTypes.GameDetailsByGameId = {
    [GameDetailsDeclaration.nutsGameId] = nutsGameDetails,
}

local mockImageIndex = 1
local mockImages = {
    "http://www.roblox.com/asset/?id=12899280578",
    "http://www.roblox.com/asset/?id=6233948090",
    "http://www.roblox.com/asset/?id=133537141",
}
local getNextMockImage = function()
    mockImageIndex = math.fmod(mockImageIndex + 1, #mockImages) + 1
    return mockImages[mockImageIndex]
end

local mockGameId = GameDetailsDeclaration.nutsGameId + 100
local function addMockGame()
    local gameId = mockGameId
    mockGameId = mockGameId + 1
    local mockGameDetails = {
        gameId = mockGameId,
        gameImage = getNextMockImage(),
        name = "Mock Game " .. gameId,
        description = "This is a mock game",
        minPlayers = 2,
        maxPlayers = 3,
    }
    gameDetailsByGameId[gameId] = mockGameDetails
end

GameDetailsDeclaration.addMockGames = function()
    for _ = 1, 10 do
        addMockGame()
    end
end

GameDetailsDeclaration.getGameDetailsByGameId = function(): CommonTypes.GameDetailsByGameId
    return gameDetailsByGameId
end

return GameDetailsDeclaration