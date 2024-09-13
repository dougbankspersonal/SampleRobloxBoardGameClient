--[[
    Server-concept only.
    Class for an instance of the mock die roll game.
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local Cryo = require(ReplicatedStorage.Cryo)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local GameState = require(SRBGCShared.Modules.MockGame.GameState)

-- SRBGCServer
local SRBGCServer = script.Parent.Parent

local GameInstance = {}
GameInstance.__index = GameInstance

local nextGameTableId: CommonTypes.TableId = 10000

export type GameInstance = {
    -- members
    gameInstanceGUID: CommonTypes.GameInstanceGUID,
    tableDescription: CommonTypes.TableDescription,
    gameState: GameTypes.GameState,

    -- static functions.
    new: (gameInstanceGUID: CommonTypes.GameInstanceGUID, tableDescription: CommonTypes.TableDescription) -> GameInstance,
    findGameInstance: (gameInstanceGUID: CommonTypes.GameInstanceGUID) -> GameInstance?,

    -- const member functions.
    -- Shortcuts to ask questions about game instance.
    getPlayers: (GameInstance) -> { Player },
    getGUID: (GameInstance) -> CommonTypes.GameInstanceGUID,
    getGameState: (GameInstance) -> GameTypes.GameState,

    -- non-const functions.  Each returns true iff something changed.
    -- user rolls a die.  Game state changes. Return the value they rolled.
    rollDie: (GameInstance, userId: CommonTypes.UserId) -> number,
}

local mockGameInstances = {} :: { [CommonTypes.GameInstanceGUID]: GameInstance.GameInstance }


GameInstance.findGameInstance = function(gameInstanceGUID: CommonTypes.GameInstanceGUID): GameInstance.GameInstance?
    return mockGameInstances[gameInstanceGUID]
end

GameInstance.new = function(gameInstanceGUID: CommonTypes.GameInstanceGUID, tableDescription: CommonTypes.TableDescription): GameInstance.GameInstance
    local self = {}
    setmetatable(self, GameInstance)

    self.gameInstanceGUID = gameInstanceGUID
    self.tableDescription = tableDescription

    self.gameState = GameState.createNewGameState(tableDescription)
end

GameInstance.getPlayers = function(self: GameInstance): { Player }
    -- Get Player for everyone I think is in the game.
    -- Due to funky timing issues, Player may not exist for some ids: leave them out.
    local players = {}
    for userId, _ in self.tableDescription.memberUserIds do
        local player = game.Players:GetPlayerByUserId(userId)
        if player then
            table.insert(players, player)
        end
    end
    return players
end

GameInstance.getGUID = function(self: GameInstance): CommonTypes.GameInstanceGUID
    return self.gameInstanceGUID
end

GameInstance.getGameState = function(self: GameInstance): GameTypes.GameState
    return self.gameState
end

GameInstance.rollDie = function(self: GameInstance, userId: CommonTypes.UserId): number
    -- Roll a die, update game state.
    local dieRoll = math.random(1, 6)
    self.gameState.scoresByUserId[userId] = (self.gameState.scoresByUserId[userId] or 0) + dieRoll

    if self.gameState.scoresByUserId[userId] >= 20 then
        self.gameState.gameOver = true
    end

    return dieRoll
end

return GameInstance