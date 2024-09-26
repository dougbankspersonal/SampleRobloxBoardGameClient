local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)

local ServerTypes = {}

export type ServerGameInstance = {
    -- members
    gameInstanceGUID: CommonTypes.GameInstanceGUID,
    tableDescription: CommonTypes.TableDescription,
    gameState: GameTypes.GameState,

    -- static functions.
    findGameInstance: (gameInstanceGUID: CommonTypes.GameInstanceGUID) -> ServerGameInstance?,

    -- const member functions.
    -- Shortcuts to ask questions about game instance.
    getGameInstanceGUID: (ServerGameInstance) -> CommonTypes.GameInstanceGUID,
    getGameState: (ServerGameInstance) -> GameTypes.GameState,
    isPlayerOverMax: (ServerGameInstance, CommonTypes.UserId) -> boolean,
    getCurrentPlayerUserId: (ServerGameInstance) -> CommonTypes.UserId,
    isPlayerInGame: (ServerGameInstance, CommonTypes.UserId) -> boolean,
    getGameOptions: (ServerGameInstance) -> CommonTypes.NonDefaultGameOptions,

    -- non-const functions.  Each returns true iff something changed.
    -- user rolls a die.  Game state changes. Return the value they rolled.
    rollDie: (ServerGameInstance, CommonTypes.UserId, GameTypes.DieType) -> (boolean, number),
    checkForWinner: (ServerGameInstance, CommonTypes.UserId) ->  nil,

    -- The functions any ServerGameInstance needs to implement to work with RBG library.
    new: (gameInstanceGUID: CommonTypes.GameInstanceGUID, tableDescription: CommonTypes.TableDescription) -> ServerGameInstance,
    destroy: (ServerGameInstance) -> nil,
    playerLeftGame: (ServerGameInstance, userId: CommonTypes.UserId) -> nil,
}


return ServerTypes