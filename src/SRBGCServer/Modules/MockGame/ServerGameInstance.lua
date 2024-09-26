--[[
    Server-concept only.
    Class for an instance of the mock die roll game.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local DieTypes = require(SRBGCShared.Modules.MockGame.DieTypes)
local GameUtils = require(SRBGCShared.Modules.MockGame.GameUtils)

-- SRBGCServer
local SRBGCServer = script.Parent.Parent.Parent
local ServerEventManagement = require(SRBGCServer.Modules.MockGame.ServerEventManagement)
local ServerTypes = require(SRBGCServer.Modules.MockGame.ServerTypes)
local ServerGameInstanceStorage = require(SRBGCServer.Modules.MockGame.ServerGameInstanceStorage)

local maxScore = 50

local ServerGameInstance = {}
ServerGameInstance.__index = ServerGameInstance

local function createNewGameState(tableDescription: CommonTypes.TableDescription): GameTypes.GameState
    local gameState = {}

    gameState.scoresByUserId = {}
    Utils.debugPrint("Mocks", "createNewGameState tableDescription.memberUserIds", tableDescription.memberUserIds)
    for userId, _ in pairs(tableDescription.memberUserIds) do
        gameState.scoresByUserId[userId] = 0
    end

    gameState.playerIdsInTurnOrder = Cryo.Dictionary.keys(tableDescription.memberUserIds)
    gameState.playerIdsInTurnOrder = Utils.randomizeArray(gameState.playerIdsInTurnOrder)
    gameState.currrentPlayerTurnIndex = 1

    gameState.opt_winnerUserId = nil

    return gameState
end

ServerGameInstance.new = function(tableDescription: CommonTypes.TableDescription): ServerTypes.ServerGameInstance
    assert(tableDescription, "tableDescription is nil")
    assert(tableDescription.gameInstanceGUID, "tableDescription.gameInstanceGUID is nil")

    local self = {}
    setmetatable(self, ServerGameInstance)

    self.tableDescription = tableDescription

    ServerGameInstanceStorage.storeServerGameInstance(self)

    ServerEventManagement.setupGameInstanceEventsAndFunctions(tableDescription.gameInstanceGUID)
    self.gameState = createNewGameState(self.tableDescription)

    return self
end

function ServerGameInstance:destroy()
    ServerGameInstanceStorage.removeServerGameInstance(self:getGameInstanceGUID())
end

function ServerGameInstance:playerLeftGame(userId: CommonTypes.UserId)
    -- Remove from all arrays....
    self.tableDescription.memberUserIds[userId] = nil
    self.tableDescription.mockUserIds[userId] = nil
    self.gameState.scoresByUserId[userId] = nil
    self.gameState.playerIdsInTurnOrder = Cryo.List.removeValue(self.gameState.playerIdsInTurnOrder, userId)
end

function ServerGameInstance:getGameInstanceGUID(): CommonTypes.GameInstanceGUID
    return self.gameInstanceGUID
end

function ServerGameInstance:getGameState(): GameTypes.GameState
    return self.gameState
end

function ServerGameInstance:isPlayerOverMax(userId: CommonTypes.UserId): boolean
    assert(self.tableDescription.memberUserIds[userId], "User " .. userId .. " is not a member of game " .. self.gameInstanceGUID)
    local score = self.gameState.scoresByUserId[userId] or 0
    return score >= maxScore
end

function ServerGameInstance:getCurrentPlayerUserId(): CommonTypes.UserId
    return GameUtils.getCurrentPlayerUserId(self.gameState)
end

function ServerGameInstance:isPlayerInGame(userId: CommonTypes.UserId) : boolean
    return self.tableDescription.memberUserIds[userId]
end

function ServerGameInstance:getGameOptions(): CommonTypes.NonDefaultGameOptions
    return self.tableDescription.opt_nonDefaultGameOptions or {}
end

function ServerGameInstance:checkForWinner(dieRollerUserId: CommonTypes.UserId)
    local gameOptions = self:getGameOptions()
    if gameOptions.Evalaute_At_End_Of_Round then
        if self.gameState.currentPlayerIndex == #self.gameState.playerIdsInTurnOrder then
            for userId, _ in self.gameState.scoresByUserId do
                if self:isPlayerOverMax(userId) then
                    self.gameState.opt_winnerUserId = userId
                    break
                end
            end
        end
    else
        if self:isPlayerOverMax(dieRollerUserId) then
            self.gameState.opt_winnerUserId = dieRollerUserId
        end
    end
end

function ServerGameInstance:rollDie(dieRollerUserId: CommonTypes.UserId, dieType: GameTypes.DieType): (boolean, number)
    -- Better be a member of the game.
    assert(self.tableDescription.memberUserIds[dieRollerUserId], "User " .. dieRollerUserId .. " is not a member of game " .. self.gameInstanceGUID)

    -- Whose turn is it.
    local currentPlayerUserId = self:getCurrentPlayerUserId()

    -- Either this is the player requesting the roll, or it's a mock and the player requesting the roll is the host.
    if not GameUtils.firstUserCanPlayAsSecondUser(self.tableDescription, dieRollerUserId, currentPlayerUserId) then
        return false, 0
    end

    -- Roll a die, update game state.
    local dieRoll = math.random(1, 6)

    local gameOptions = self:getGameOptions()

    if dieType == DieTypes.Smushed then
        if dieRoll == 1 then
            dieRoll = 2
        end
        if dieRoll == 6 then
            dieRoll = 5
        end
    elseif (not gameOptions.No_Advantage_Die) and dieType == DieTypes.Advantage then
        dieRoll = dieRoll + 1
    elseif not dieType == DieTypes.Standard then
        return false, 0
    end

    self.gameState.scoresByUserId[dieRollerUserId] = (self.gameState.scoresByUserId[dieRollerUserId] or 0) + dieRoll

    self:checkForWinner(dieRollerUserId)

    self.gameState.currentPlayerIndex = 1 + (self.gameState.currentPlayerIndex) % #self.gameState.playerIdsInTurnOrder

    return true, dieRoll
end

return ServerGameInstance