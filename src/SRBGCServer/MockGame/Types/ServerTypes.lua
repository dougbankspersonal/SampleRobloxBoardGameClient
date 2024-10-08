local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.MockGame.Types.GameTypes)

local ServerTypes = {}

export type ServerGameInstance = {
    -- members
    tableDescription: CommonTypes.TableDescription,
    gameState: GameTypes.GameState,

    -- static functions.
    findGameInstance: (gameInstanceGUID: CommonTypes.GameInstanceGUID) -> ServerGameInstance?,
    new: (gameInstanceGUID: CommonTypes.GameInstanceGUID, tableDescription: CommonTypes.TableDescription) -> ServerGameInstance,

    -- const member functions.
    -- Shortcuts to ask questions about game instance.
    getGameInstanceGUID: (ServerGameInstance) -> CommonTypes.GameInstanceGUID,
    getGameState: (ServerGameInstance) -> GameTypes.GameState,
    isPlayerOverMax: (ServerGameInstance, CommonTypes.UserId) -> boolean,
    getCurrentPlayerUserId: (ServerGameInstance) -> CommonTypes.UserId,
    isPlayerInGame: (ServerGameInstance, CommonTypes.UserId) -> boolean,
    getGameOptions: (ServerGameInstance) -> CommonTypes.NonDefaultGameOptions,
    sanityCheck: (ServerGameInstance) -> nil,

    -- non-const functions.  Each returns true iff something changed.
    -- user rolls a die.  Game state changes. Return the value they rolled.
    dieRoll: (ServerGameInstance, CommonTypes.UserId, GameTypes.DieType) -> (boolean, GameTypes.ActionDescription?),
    hasWinner: (ServerGameInstance) -> boolean,
    -- Called at the end of every turn.
    -- Evaluate whether game has a winner.  If so set the winnerId.
    maybeSetWinner: (ServerGameInstance) -> nil,
    -- For debug purposes.  Do an automated run thru the game.
    runMockGame: (ServerGameInstance) -> nil,

    -- The functions any ServerGameInstance needs to implement to work with RBG library.
    destroy: (ServerGameInstance) -> nil,
    playerLeftGame: (ServerGameInstance, CommonTypes.UserId) -> nil,
    getGameSpecificGameEndDetails: (ServerGameInstance) -> any?,
}

return ServerTypes