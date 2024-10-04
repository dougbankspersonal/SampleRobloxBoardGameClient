--[[
Game-specific setup for the client side.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)
local TableDescription= require(RobloxBoardGameShared.Modules.TableDescription)

-- RobloxBoardGameClient
local RobloxBoardGameClient = script.Parent.Parent.Parent.Parent.RobloxBoardGameClient
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local RBGClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local MessageLog = require(RobloxBoardGameClient.Modules.MessageLog)
local GuiConstants = require(RobloxBoardGameClient.Modules.GuiConstants)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local GameUtils = require(SRBGCShared.Modules.MockGame.GameUtils)
local DieTypes = require(SRBGCShared.Modules.MockGame.DieTypes)
local ActionTypes = require(SRBGCShared.Modules.MockGame.ActionTypes)
local GameState = require(SRBGCShared.Modules.MockGame.GameState)

-- SRBGCClient
local SRBGCClient = script.Parent.Parent.Parent
local ClientEventManagement = require(SRBGCClient.Modules.MockGame.ClientEventManagement)

local ClientGameInstance = {}
ClientGameInstance.__index = ClientGameInstance

local dieRollWidth = 100
local dieRollHeight = 100

export type ClientGameInstance = {
    -- members
    tableDescription: CommonTypes.TableDescription,
    gameState: GameTypes.GameState,
    localUserId: CommonTypes.UserId,
    messageLog: MessageLog.MessageLog,
    scoreContent: Frame,
    dieRollContainer: Frame,
    dieRollAnimationContent: TextLabel,
    buttonsByUserId: { [CommonTypes.UserId]: { TextButton } },
    scoreLabelsByUserId: { [CommonTypes.UserId]: TextLabel },

    -- Static functions.
    -- ctor.
    new: (gameInstanceGUID: CommonTypes.GameInstanceGUID, tableDescription: CommonTypes.TableDescription) -> ClientGameInstance,
    -- accessor.
    get: () -> ClientGameInstance?,

    -- The functions any ClientGameInstance needs to implement to work with RBG library.
    destroy: (ClientGameInstance) -> nil,
    onPlayerLeftTable: (ClientGameInstance, CommonTypes.UserId) -> boolean,
    notifyThatHostEndedGame: (ClientGameInstance, CommonTypes.GameEndDetails) -> boolean,
    sanityCheck: (ClientGameInstance) -> nil,

    -- Other "private" functions.
    asyncBuildUI: (ClientGameInstance, Frame) -> nil,
    buildUIInternal: (ClientGameInstance, Frame) -> nil,
    addDieRollAnimationSection: (ClientGameInstance, Frame) -> nil,
    addScoreSection: (ClientGameInstance, Frame) -> nil,
    maybeAddRowForUser: (ClientGameInstance, Frame, CommonTypes.UserId) -> Frame?,
    addScoreForUser: (ClientGameInstance, CommonTypes.UserId) -> TextLabel,
    updateScores: (ClientGameInstance) -> nil,
    onGameStateUpdated: (ClientGameInstance, GameTypes.ActionDescription?) -> nil,
    updateButtonActiveStates: (ClientGameInstance) -> nil,
    displayNewTurnOrGameEnd: (ClientGameInstance) -> nil,
    notifyDieRollStart: (ClientGameInstance, CommonTypes.UserId, GameTypes.ActionDetailsDieRoll, () -> ()) -> nil,
    animateDieRoll: (ClientGameInstance, GameTypes.ActionDetailsDieRoll, () ->()) -> nil,
    notifyDieRollFinished: (GameTypes.ActionDetailsDieRoll, () -> ()) -> nil,
    disableAllButtons: (ClientGameInstance) -> nil,
    getGameInstanceGUID: (ClientGameInstance) -> CommonTypes.GameInstanceGUID,
}

-- Local helper functions.
local addButtonForDie = function(gameInstanceGUID: CommonTypes.GameInstanceGUID, parent: Frame, dieType: GameTypes.DieType)
    local callback = function()
        ClientEventManagement.requestDieRoll(gameInstanceGUID, dieType)
    end

    local _, button = GuiUtils.addStandardTextButtonInContainer(parent, "DieButton", callback, {
        Text = GameUtils.getDieName(dieType),
        Active = false,
        LayoutOrder = 10 + dieType,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
    })

    return button
end

-- There should only ever be one or zero.
local _clientGameInstance = nil

ClientGameInstance.get = function(): ClientGameInstance?
    return _clientGameInstance
end

function ClientGameInstance:destroy()
    Utils.debugPrint("GamePlay", "ClientGameInstance destroy")
    _clientGameInstance = nil
    -- Anything else to clean up here?
end

function ClientGameInstance:onPlayerLeftTable(userId: CommonTypes.UserId): boolean
    -- No one but the host gets anything special.
    if self.tableDescription.hostUserId ~= userId then
        return false
    end

    task.spawn(function()
        local userName = PlayerUtils.getName(userId)
        local message = GuiUtils.bold(userName) .. " left the table. End the game?"
        DialogUtils.showConfirmationDialog(userName, message, function()
            RBGClientEventManagement.endGame(self.tableDescription.tableId)
        end, "Yes", "No")
    end)
    return true
end

function ClientGameInstance:notifyThatHostEndedGame(gameEndDetails: CommonTypes.GameEndDetails): boolean
    assert(gameEndDetails, "gameEndDetails is nil")
    Utils.debugPrint("GamePlay", "ClientGameInstance:notifyThatHostEndedGame gameEndDetails = ", gameEndDetails)

    -- Talk to users about why game ended.
    local gameSpecificDetails = gameEndDetails.gameSpecificDetails
    if not gameSpecificDetails then
        return
    end

    -- We could look into gameState to figure out what's up but there may be weird timing issues.
    -- Safer to just read details passed in.
    -- Normal case: game was played to completion and someone won.
    -- In that case everyone (including host) can see a "congrats" message.
    if gameSpecificDetails.winnerUserId then
        Utils.debugPrint("GamePlay", "ClientGameInstance:notifyThatHostEndedGame gameEndDetails.winnerUserId = ", gameEndDetails.winnerUserId)
        local winnerUserId = gameSpecificDetails.winnerUserId
        -- Normal game end situation: game is over because someone won.
        local winnerName = PlayerUtils.getName(winnerUserId)
        local winnerScore = gameSpecificDetails.winnerScore
        Utils.debugPrint("GamePlay", "ClientGameInstance:notifyThatHostEndedGame winnerName = ", winnerName)
        Utils.debugPrint("GamePlay", "ClientGameInstance:notifyThatHostEndedGame winnerScore = ", winnerScore)
        local title = "Congratulations " .. winnerName .. "!"
        local message = winnerName .. " won the game with a score of " .. winnerScore .. " points."
        task.spawn(function()
            DialogUtils.showAckDialog(title, message)
        end)
        -- No need for system-level messaging: return true.
        Utils.debugPrint("GamePlay", "ClientGameInstance:notifyThatHostEndedGame returning true")
        return true
    end

    -- Other reasons the game might end:
    -- * Host used a control to end the game prematurely.
    -- * Host left the table.
    -- Both of these are handled at system level.  This game instances doesn't care to say
    -- anything different: just return false.
    return false
end

function ClientGameInstance:sanityCheck()
    local tableDescription = self.tableDescription
    TableDescription.sanityCheck(tableDescription)

    -- Table Description should be playing and have a GUID.
    assert(tableDescription.gameInstanceGUID, "clientGameInstance.tableDescription.gameInstanceGUID is nil")
    assert(tableDescription.gameTableState == GameTableStates.Playing, "clientGameInstance.tableDescription.gameTableState is not Playing")

    GameState.sanityCheck(self.gameState)
end

ClientGameInstance.new = function(tableDescription: CommonTypes.TableDescription): ClientGameInstance
    assert(tableDescription, "tableDescription is nil")
    assert(tableDescription.gameInstanceGUID, "tableDescription.gameInstanceGUID is nil")

    assert(_clientGameInstance == nil, "There should only ever be one or zero ClientGameInstance")

    local self = {}
    setmetatable(self, ClientGameInstance)

    self.tableDescription = tableDescription
    self.buttonsByUserId = {}
    self.scoreLabelsByUserId = {}

    self.gameState = GameState.createNewGameState(tableDescription)

    local onGameStateUpdated = function(gameState: GameTypes.GameState, opt_actionDescription: GameTypes.ActionDescription?)
        self.gameState = gameState
        self:onGameStateUpdated(opt_actionDescription)
    end

    ClientEventManagement.listenToServerEvents(self.tableDescription.gameInstanceGUID, onGameStateUpdated)

    _clientGameInstance = self

    return self
end

function ClientGameInstance:asyncBuildUI(parent: Frame)
    task.spawn(function()
        self.gameState = ClientEventManagement.getGameStateAsync(self.tableDescription.gameInstanceGUID)
        self:buildUIInternal(parent)
    end)
end

function ClientGameInstance:buildUIInternal(parent: Frame)
    assert(parent, "parent is nil")
    self.localUserId = Players.LocalPlayer.UserId

    GuiUtils.addUIListLayout(parent, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    self.messageLog = MessageLog.new(parent)
    self.messageLog.scrollingFrame.LayoutOrder = GuiUtils.getNextLayoutOrder(parent)

    self:addScoreSection(parent)

    task.spawn(function()
        self.gameState = ClientEventManagement.getGameStateAsync(self.tableDescription.gameInstanceGUID)

        for _, userId in self.gameState.playerIdsInTurnOrder do
            -- Iff local player can act on this user's behalf, add controls for taking actions as this user.
            self:maybeAddRowForUser(parent, userId)
            -- Always add a score for the user.
            self:addScoreForUser(userId)
        end

        self:addDieRollAnimationSection(parent)

        self:onGameStateUpdated()
    end)

end

function ClientGameInstance:addDieRollAnimationSection(parent: Frame)
    assert(parent, "parent is nil")
    self.dieRollContainer = GuiUtils.addRowAndReturnRowContent(parent, "DieRow")
    self.dieRollContainer.Visible = false

    local dieRollAnimationHolder = Instance.new("Frame")
    dieRollAnimationHolder.Name = "DieRollAnimationHolder"
    dieRollAnimationHolder.Parent = self.dieRollContainer
    dieRollAnimationHolder.Size = UDim2.fromOffset(dieRollWidth, dieRollHeight)
    dieRollAnimationHolder.BackgroundTransparency = 1

    self.dieRollAnimationContent = Instance.new("TextLabel")
    self.dieRollAnimationContent.Name = "DieRollAnimationContent"
    self.dieRollAnimationContent.Parent = dieRollAnimationHolder
    self.dieRollAnimationContent.Size = UDim2.fromScale(1, 1)
    self.dieRollAnimationContent.Font = Enum.Font.SourceSansBold
    self.dieRollAnimationContent.TextSize = 36
    GuiUtils.centerInParent(self.dieRollAnimationContent)

    GuiUtils.addCorner(self.dieRollAnimationContent)

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "TweenScaling"
    uiScale.Parent = self.dieRollAnimationContent
end

function ClientGameInstance:addScoreSection(parent: Frame)
    assert(parent, "parent is nil")
    self.scoreContent = GuiUtils.addRowAndReturnRowContent(parent, "ScoreRow", {
        labelText = "Scores",
        fillDirection = Enum.FillDirection.Vertical
    })
end

function ClientGameInstance:maybeAddRowForUser(parent: Frame, userId: CommonTypes.UserId): Frame?
    if not Utils.firstUserCanPlayAsSecondUser(self.tableDescription, self.localUserId, userId) then
        return
    end

    local content = GuiUtils.addRowAndReturnRowContent(parent, "UserRow", {
        labelText = "Roll for " .. PlayerUtils.getName(userId),
        horizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    self.buttonsByUserId[userId] = {}
    for _, dieType in DieTypes do
        local textButton = addButtonForDie(self.tableDescription.gameInstanceGUID, content, dieType)
        table.insert(self.buttonsByUserId[userId], textButton)
    end

    return content
end

function ClientGameInstance:addScoreForUser(userId: CommonTypes.UserId): TextLabel
    local content = GuiUtils.addRowAndReturnRowContent(self.scoreContent, "ScoreRow" .. userId, {
        labelText = PlayerUtils.getName(userId) .. ":",
        horizontalAlignment = Enum.HorizontalAlignment.Left,
    })
    local scoreLabel = GuiUtils.addTextLabel(content, "0", {
        Name = "Score",
        RichText = true,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
    })
    self.scoreLabelsByUserId[userId] = scoreLabel
    return scoreLabel
end

function ClientGameInstance:updateScores()
    Utils.debugPrint("Mocks",  "updateScores 001")
    Utils.debugPrint("Mocks", "self.gameState = ", self.gameState)
    for userId, scoreLabel in pairs(self.scoreLabelsByUserId) do
        scoreLabel.Text = tostring(self.gameState.scoresByUserId[userId])
    end
end

local waitTime = GuiConstants.messageQueueTransparencyTweenTime + GuiConstants.scrollingFrameSlideTweenTime

function ClientGameInstance:onGameStateUpdated(opt_actionDescription: GameTypes.ActionDescription?)
    Utils.debugPrint("MessageLog", "onGameStateUpdated 001")

    -- if there's a description, first play it out/animate it.
    if opt_actionDescription then
        Utils.debugPrint("MessageLog", "onGameStateUpdated 002")
        -- Disable controls while animating.
        self:disableAllButtons()

        local actionType = opt_actionDescription.actionType
        local actorUserId = opt_actionDescription.actorUserId
        local actionDetails = opt_actionDescription.actionDetails
        assert(actionType, "actionType is nil")
        assert(actionDetails, "actionDetails is nil")

        Utils.debugPrint("MessageLog", "onGameStateUpdated 003")
        if actionType == ActionTypes.DieRoll then
            Utils.debugPrint("MessageLog", "onGameStateUpdated calling notifyDieRollStart")
            self:notifyDieRollStart(actorUserId, actionDetails, function()
                task.wait(waitTime)
                Utils.debugPrint("MessageLog", "onGameStateUpdated calling animateDieRoll")
                self:animateDieRoll(actionDetails, function()
                    task.wait(waitTime)
                    Utils.debugPrint("MessageLog", "onGameStateUpdated calling notifyDieRollFinished")
                    self:notifyDieRollFinished(actorUserId, actionDetails, function()
                        task.wait(waitTime)
                        Utils.debugPrint("MessageLog", "onGameStateUpdated calling updateScores")
                        self:updateScores()

                        -- Give everyone a second to digest this.
                        task.wait(waitTime)
                        self:displayNewTurnOrGameEnd()
                    end)
                end)
            end)
        end
    else
        self:updateScores()
        self:displayNewTurnOrGameEnd()
    end
end

function ClientGameInstance:updateButtonActiveStates()
    local currentPlayerId = GameState.getCurrentPlayerUserId(self.gameState)
    for userId, buttonSet in pairs(self.buttonsByUserId) do
        local canPlay = false
        if not self.gameState.opt_winnerUserId then
            if userId == currentPlayerId then
                canPlay = Utils.firstUserCanPlayAsSecondUser(self.tableDescription, self.localUserId, userId)
            end
        end
        for _, button in buttonSet do
            button.Active = canPlay
        end
    end
end

function ClientGameInstance:displayNewTurnOrGameEnd()
    -- Someone's turn, or game over/winner?
    local message
    if not self.gameState.opt_winnerUserId then
        local currentPlayerId = GameState.getCurrentPlayerUserId(self.gameState)
        local currentPlayerName = PlayerUtils.getName(currentPlayerId)
        message = GuiUtils.bold(currentPlayerName) .. ": It's your turn."
    else
        local winnerName = PlayerUtils.getName(self.gameState.opt_winnerUserId)
        local score = self.gameState.scoresByUserId[self.gameState.opt_winnerUserId]
        message = GuiUtils.bold(winnerName) .. " wins with a score of " .. score .. " points!"
    end
    self.messageLog:enqueueMessage(message)

    -- Update all the buttons.
    self:updateButtonActiveStates()
end

function ClientGameInstance:notifyDieRollStart(actorUserId: CommonTypes.UserId, actionDetailsDieRoll: GameTypes.ActionDetailsDieRoll, onNotificationShown: () -> ())
    assert(actionDetailsDieRoll, "actionDetailsDieRoll is nil")
    assert(onNotificationShown, "onDieRollFinished is nil")

    local actorPlayerName = PlayerUtils.getName(actorUserId)
    local message = actorPlayerName .. " is rolling the " .. GameUtils.getDieName(actionDetailsDieRoll.dieType) .. " die."
    -- Wait until message displays to continue...
    self.messageLog:enqueueMessage(message, onNotificationShown)
end

function ClientGameInstance:animateDieRoll(actionDetailsDieRoll: GameTypes.ActionDetailsDieRoll, onAnimationFinished: () -> ())
    self.dieRollContainer.Visible = true

    if actionDetailsDieRoll.dieType == DieTypes.Standard then
        self.dieRollAnimationContent.BackgroundColor3 = Color3.fromRGB(255, 230, 240)
    elseif actionDetailsDieRoll.dieType == DieTypes.Smushed then
        self.dieRollAnimationContent.BackgroundColor3 = Color3.fromRGB(230, 255, 240)
    else
        self.dieRollAnimationContent.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
    end

    self.dieRollAnimationContent.Text = tostring(actionDetailsDieRoll.rollResult)

    -- Animate it in
    local uiScale  = self.dieRollAnimationContent:FindFirstChild("TweenScaling")
    assert(uiScale, "No uiScale found")
    uiScale.Scale = 0
    self.dieRollAnimationContent.Rotation = 980

    local scaleTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, 0)
    local rotateTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
    local t1 = TweenService:Create(uiScale, scaleTweenInfo, {Scale = 1})
    local t2 = TweenService:Create(self.dieRollAnimationContent, rotateTweenInfo, {Rotation = 0})
    t1:Play()
    t2:Play()
    t1.Completed:Connect(onAnimationFinished)
end

function ClientGameInstance:notifyDieRollFinished(actorUserId:CommonTypes.UserId, actionDetailsDieRoll: GameTypes.ActionDetailsDieRoll, onNotifyFinished: () -> ())
    local actorName = PlayerUtils.getName(actorUserId)

    local _message = actorName .. " rolled a " .. tostring(actionDetailsDieRoll.rollResult)
    self.messageLog:enqueueMessage(_message, onNotifyFinished)
end

function ClientGameInstance:disableAllButtons()
    for _, buttonSet in pairs(self.buttonsByUserId) do
        for _, button in buttonSet do
            button.Active = false
        end
    end
end


function ClientGameInstance:getGameInstanceGUID(): CommonTypes.GameInstanceGUID
    assert(self.tableDescription, "tableDescription is nil")
    assert(self.tableDescription.gameInstanceGUID, "gameInstanceGUID is nil")
    return self.tableDescription.gameInstanceGUID
end

return ClientGameInstance