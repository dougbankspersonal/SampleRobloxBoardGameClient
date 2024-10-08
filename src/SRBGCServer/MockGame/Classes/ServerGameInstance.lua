--[[
    Server-concept only.
    Class for an instance of the mock die roll game.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)

-- RobloxBoardGameServer
local RobloxBoardGameServer = ServerScriptService.RobloxBoardGameServer
local ServerGameAnalytics = require(RobloxBoardGameServer.Analytics.ServerGameAnalytics)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.MockGame.Types.GameTypes)
local DieTypes = require(SRBGCShared.MockGame.Types.DieTypes)
local GameState = require(SRBGCShared.MockGame.Modules.GameState)
local ActionTypes = require(SRBGCShared.MockGame.Types.ActionTypes)
local AnalyticsEventNames = require(SRBGCShared.MockGame.Globals.AnalyticsEventNames)
local GameOptionIds = require(SRBGCShared.MockGame.Globals.GameOptionIds)

-- SRBGCServer
local SRBGCServer = ServerScriptService.SRBGCServer
local ServerEventManagement = require(SRBGCServer.MockGame.Modules.ServerEventManagement)
local ServerTypes = require(SRBGCServer.MockGame.Types.ServerTypes)
local ServerGameInstanceStorage = require(SRBGCServer.MockGame.Modules.ServerGameInstanceStorage)

local maxScore = 10

local ServerGameInstance = {}
ServerGameInstance.__index = ServerGameInstance

local function makeDieRollActionDescription(actorUserId: CommonTypes.UserId, dieType: GameTypes.DieType, dieRollResult: number): GameTypes.ActionDescription
    local dieRollDetails: GameTypes.ActionDetailsDieRoll     = {
        dieType = dieType,
        dieRollResult = dieRollResult
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

function ServerGameInstance:runMockGame()
    while not self:hasWinner() do
        local dieType = math.random(0, DieTypes.NumDieTypes - 1)
        self:dieRoll(self:getCurrentPlayerUserId(), dieType)
    end
end

function ServerGameInstance:maybeSetWinner(): nil
    local evaluateAtEndOfRound = TableDescription.getOptionValue(self.tableDescription, GameOptionIds.EvaluateAtEndOfRound)
    Utils.debugPrint("Analytics", "maybeSetWinner evaluateAtEndOfRound = ", evaluateAtEndOfRound)
    if evaluateAtEndOfRound then
        Utils.debugPrint("Analytics", "self.gameState.currentPlayerIndex = ", self.gameState.currentPlayerIndex)
        Utils.debugPrint("Analytics", "self.tableDescription.numPlayers = ", self.tableDescription.numPlayers)

        if self.gameState.currentPlayerIndex ~= self.tableDescription.numPlayers then
            return
        end
    end

    for index, userId in self.gameState.playerIdsInTurnOrder do
       if self:isPlayerOverMax(userId) then
            self.gameState.opt_winnerUserId = userId

            -- Do some analytics.
            ServerGameAnalytics.addRecordOfType(self.tableDescription.gameId, self.tableDescription.gameInstanceGUID, AnalyticsEventNames.RecordTypeGameWin, {
                winnerId = userId,
                winnerIndex = index,
                numPlayers = #self.gameState.playerIdsInTurnOrder,
            })
            return
        end
    end
end

function ServerGameInstance:hasWinner(): boolean
    return self.gameState.opt_winnerUserId ~= nil
end

function ServerGameInstance:dieRoll(rollRequesterUserId: CommonTypes.UserId, dieType: GameTypes.DieType): (boolean, GameTypes.ActionDescription?)
    assert(rollRequesterUserId, "rollRequesterUserId is nil")
    assert(dieType, "dieType is nil")

    -- Better be a member of the game.
    if not self.tableDescription.memberUserIds[rollRequesterUserId] then
        return false
    end

    -- Whose turn is it.
    local currentPlayerUserId = self:getCurrentPlayerUserId()

    -- Either this is the player requesting the roll, or it's a mock and the player requesting the roll is the host.
    if not Utils.firstUserCanPlayAsSecondUser(self.tableDescription, rollRequesterUserId, currentPlayerUserId) then
        return false
    end

    -- Roll a die, update game state.
    local dieRollResult = math.random(1, 6)

    local gameOptions = self:getGameOptions()

    if dieType == DieTypes.Types.Smushed then
        if dieRollResult == 1 then
            dieRollResult = 2
        end
        if dieRollResult == 6 then
            dieRollResult = 5
        end
    elseif (not gameOptions.No_Advantage_Die) and dieType == DieTypes.Types.Advantage then
        dieRollResult = dieRollResult + 1
    elseif not dieType == DieTypes.Types.Standard then
        return false
    end

    self.gameState.scoresByUserId[currentPlayerUserId] = (self.gameState.scoresByUserId[currentPlayerUserId] or 0) + dieRollResult

    local actionDescription = makeDieRollActionDescription(currentPlayerUserId, dieType, dieRollResult)

    -- Do some analytics.
    ServerGameAnalytics.addRecordOfType(self.tableDescription.gameId, self.tableDescription.gameInstanceGUID, AnalyticsEventNames.RecordTypeDieRoll, {
        userId = currentPlayerUserId,
        dieType = dieType,
    })

    -- Check for the end of the game.
    self:maybeSetWinner()

    if not self:hasWinner() then
        -- Advance the current player.
        self.gameState.currentPlayerIndex = 1 + (self.gameState.currentPlayerIndex) % #self.gameState.playerIdsInTurnOrder
    end

    return true, actionDescription
end

function ServerGameInstance:getGameSpecificGameEndDetails(): any?
    local gameSpecificGameEndDetails = {}

    -- Did someone win? If so get score and winner id.
    if self.gameState.opt_winnerUserId then
        local score = self.gameState.scoresByUserId[self.gameState.opt_winnerUserId]
        gameSpecificGameEndDetails.winnerUserId = self.gameState.opt_winnerUserId
        gameSpecificGameEndDetails.winnerScore = score
    end
    return gameSpecificGameEndDetails
end

function ServerGameInstance:sanityCheck()
    local tableDescription = self.tableDescription
    TableDescription.sanityCheck(tableDescription)

    -- Table Description should be playing and have a GUID.
    assert(tableDescription.gameInstanceGUID, "clientGameInstance.tableDescription.gameInstanceGUID is nil")
    assert(tableDescription.gameTableState == GameTableStates.Playing, "clientGameInstance.tableDescription.gameTableState is not Playing")

    GameState.sanityCheck(self.gameState)
end


return ServerGameInstance