--[[
    Server-concept only.
    Class for an instance of the mock die roll game.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local DieTypes = require(SRBGCShared.Modules.MockGame.DieTypes)
local GameUtils = require(SRBGCShared.Modules.MockGame.GameUtils)
local GameState = require(SRBGCShared.Modules.MockGame.GameState)
local ActionTypes = require(SRBGCShared.Modules.MockGame.ActionTypes)

-- SRBGCServer
local SRBGCServer = script.Parent.Parent.Parent
local ServerEventManagement = require(SRBGCServer.Modules.MockGame.ServerEventManagement)
local ServerTypes = require(SRBGCServer.Modules.MockGame.ServerTypes)
local ServerGameInstanceStorage = require(SRBGCServer.Modules.MockGame.ServerGameInstanceStorage)

local maxScore = 50

local ServerGameInstance = {}
ServerGameInstance.__index = ServerGameInstance

local function makeDieRollActionDescription(actorUserId: CommonTypes.UserId, dieType: GameTypes.DieType, dieRoll: number): GameTypes.ActionDescription
    local dieRollDetails: GameTypes.ActionDetailsDieRoll     = {
        dieType = dieType,
        rollResult = dieRoll
    }
    local actionDescription: GameTypes.ActionDescription = {
        actionType = ActionTypes.DieRoll,
        actorUserId = actorUserId,
        actionDetails = dieRollDetails
    }
    return actionDescription
end


ServerGameInstance.new = function(tableDescription: CommonTypes.TableDescription): ServerTypes.ServerGameInstance
    TableDescription.sanityCheck(tableDescription)

    local self = {}
    setmetatable(self, ServerGameInstance)

    self.tableDescription = tableDescription

    ServerGameInstanceStorage.storeServerGameInstance(self)

    ServerEventManagement.setupGameInstanceEventsAndFunctions(tableDescription.gameInstanceGUID)
    self.gameState = GameState.createNewGameState(self.tableDescription)

    return self
end

function ServerGameInstance:sanityCheck()
    assert(self.tableDescription, "tableDescription is nil")
    assert(self.gameState, "gameState is nil")
    TableDescription.sanityCheck(self.tableDescription)
    GameState.sanityCheck(self.gameState)
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
    return self.tableDescription.gameInstanceGUID
end

function ServerGameInstance:getGameState(): GameTypes.GameState
    return self.gameState
end

function ServerGameInstance:isPlayerOverMax(userId: CommonTypes.UserId): boolean
    assert(self.tableDescription.memberUserIds[userId], "User " .. userId .. " is not a member of game " .. self:getGameInstanceGUID())
    local score = self.gameState.scoresByUserId[userId] or 0
    return score >= maxScore
end

function ServerGameInstance:getCurrentPlayerUserId(): CommonTypes.UserId
    return GameState.getCurrentPlayerUserId(self.gameState)
end

function ServerGameInstance:isPlayerInGame(userId: CommonTypes.UserId) : boolean
    return self.tableDescription.memberUserIds[userId]
end

function ServerGameInstance:getGameOptions(): CommonTypes.NonDefaultGameOptions
    return self.tableDescription.opt_nonDefaultGameOptions or {}
end

function ServerGameInstance:checkForEndGame(): boolean
    for userId, _ in self.gameState.scoresByUserId do
        if self:isPlayerOverMax(userId) then
            self.gameState.opt_winnerUserId = userId
            return true
        end
    end
    return false
end

function ServerGameInstance:dieRoll(rollRequesterUserId: CommonTypes.UserId, dieType: GameTypes.DieType): (boolean, GameTypes.ActionDescription?)
    assert(rollRequesterUserId, "rollRequesterUserId is nil")
    assert(dieType, "dieType is nil")

    Utils.debugPrint("GamePlay", "ServerGameInstance.dieRoll 001")

    -- Better be a member of the game.
    if not self.tableDescription.memberUserIds[rollRequesterUserId] then
        Utils.debugPrint("GamePlay", "ServerGameInstance.dieRoll 002")
        return false
    end

    -- Whose turn is it.
    local currentPlayerUserId = self:getCurrentPlayerUserId()

    -- Either this is the player requesting the roll, or it's a mock and the player requesting the roll is the host.
    if not GameUtils.firstUserCanPlayAsSecondUser(self.tableDescription, rollRequesterUserId, currentPlayerUserId) then
        Utils.debugPrint("GamePlay", "ServerGameInstance.dieRoll 003")
        return false
    end

    -- Roll a die, update game state.
    local dieRoll = math.random(1, 6)
    Utils.debugPrint("GamePlay", "ServerGameInstance.dieRoll 004")

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
        return false
    end

    self.gameState.scoresByUserId[currentPlayerUserId] = (self.gameState.scoresByUserId[currentPlayerUserId] or 0) + dieRoll

    -- Check for the end of the game.
    if gameOptions.Evalaute_At_End_Of_Round then
        if self.gameState.currentPlayerIndex == #self.gameState.playerIdsInTurnOrder then
            self:checkForEndGame()
        end
    else
        self:checkForEndGame()
    end

    Utils.debugPrint("GamePlay", "ServerGameInstance.dieRoll 005")

    local actionDescription = makeDieRollActionDescription(currentPlayerUserId, dieType, dieRoll)

    self.gameState.currentPlayerIndex = 1 + (self.gameState.currentPlayerIndex) % #self.gameState.playerIdsInTurnOrder

    return true, actionDescription
end

return ServerGameInstance