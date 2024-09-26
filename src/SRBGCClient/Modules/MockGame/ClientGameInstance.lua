--[[
Game-specific setup for the client side.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)

-- RobloxBoardGameClient
local RobloxBoardGameClient = script.Parent.Parent.Parent.Parent.RobloxBoardGameClient
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local RBGClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)
local GameUtils = require(SRBGCShared.Modules.MockGame.GameUtils)
local DieTypes = require(SRBGCShared.Modules.MockGame.DieTypes)
local ActionTypes = require(SRBGCShared.Modules.MockGame.ActionTypes)

-- SRBGCClient
local SRBGCClient = script.Parent.Parent.Parent
local ClientEventManagement = require(SRBGCClient.Modules.MockGame.ClientEventManagement)
local MessageLog = require(SRBGCClient.Modules.MockGame.MessageLog)

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
    layoutOrder: number,
    scoreContent: Frame,
    dieRollAnimationContent: TextLabel,
    gameState: GameTypes.GameState,
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

    -- Other "private" functions.
    setAndIncrementLayoutOrder: (ClientGameInstance, GuiObject) -> nil,
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
    animateDieRoll: (ClientGameInstance, GameTypes.ActionDescription, () -> ()) -> nil,
    disableAllButtons: (ClientGameInstance) -> nil,
    getGameInstanceGUID: (ClientGameInstance) -> CommonTypes.GameInstanceGUID,
}

-- Local helper functions.
local addButtonForDie = function(gameInstanceGUID: CommonTypes.GameInstanceGUID, parent: Frame, dieType: GameTypes.DieType)
    local callback = function()
        ClientEventManagement.requestRollDie(gameInstanceGUID, dieType)
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
    _clientGameInstance = nil
    -- Anything else to clean up here?
end

function ClientGameInstance:onPlayerLeftTable(userId: CommonTypes.UserId): boolean
    -- No one but the host gets anything special.
    if self.tableDescription.hostUserId ~= userId then
        return false
    end

    task.spawn(function()
        local userName = PlayerUtils.getNameAsync(userId)
        local message = GuiUtils.bold(userName) .. " left the table. End the game?"
        DialogUtils.showConfirmationDialog(userName, message, function()
            RBGClientEventManagement.endGame(self.tableDescription.tableId)
        end, "Yes", "No")
    end)
    return true
end

ClientGameInstance.new = function(tableDescription: CommonTypes.TableDescription): ClientGameInstance
    assert(tableDescription, "tableDescription is nil")
    assert(tableDescription.gameInstanceGUID, "tableDescription.gameInstanceGUID is nil")

    assert(_clientGameInstance == nil, "There should only ever be one or zero ClientGameInstance")

    local self = {}
    setmetatable(self, ClientGameInstance)

    self.tableDescription = tableDescription
    self.layoutOrder = 0
    self.buttonsByUserId = {}
    self.scoreLabelsByUserId = {}

    local onGameStateUpdated = function(gameState: GameTypes.GameState, opt_actionDescription: GameTypes.ActionDescription?)
        self.gameState = gameState
        self:onGameStateUpdated(opt_actionDescription)
    end

    ClientEventManagement.listenToServerEvents(self.tableDescription.gameInstanceGUID, onGameStateUpdated)

    _clientGameInstance = self

    return self
end

function ClientGameInstance:setAndIncrementLayoutOrder(guiObject:GuiObject)
    guiObject.LayoutOrder = self.layoutOrder
    self.layoutOrder = self.layoutOrder + 1
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

    Utils.debugPrint("TablePlaying", "Doug: building ui..")

    GuiUtils.addUIListLayout(parent, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    self.messageLog = MessageLog.new(parent)
    self:setAndIncrementLayoutOrder(self.messageLog.scrollingFrame)

    self:addDieRollAnimationSection(parent)

    self:addScoreSection(parent)

    task.spawn(function()
        self.gameState = ClientEventManagement.getGameStateAsync(self.tableDescription.gameInstanceGUID)

        -- add a button for each player the local user can control.
        for _, userId in self.gameState.playerIdsInTurnOrder do
            self:maybeAddRowForUser(parent, userId)
            self:addScoreForUser(userId)
        end

        self:onGameStateUpdated()
    end)

end

function ClientGameInstance:addDieRollAnimationSection(parent: Frame)
    assert(parent, "parent is nil")
    local content = GuiUtils.addRowAndReturnRowContent(parent, "DieRow")
    self:setAndIncrementLayoutOrder(content)

    local dieRollAnimationHolder = Instance.new("Frame")
    dieRollAnimationHolder.Name = "DieRollAnimationHolder"
    dieRollAnimationHolder.Parent = content
    dieRollAnimationHolder.Size = UDim2.fromOffset(dieRollWidth, dieRollHeight)
    dieRollAnimationHolder.BackgroundTransparency = 1

    self.dieRollAnimationContent = Instance.new("TextLabel")
    self.dieRollAnimationContent.Name = "DieRollAnimationContent"
    self.dieRollAnimationContent.Parent = dieRollAnimationHolder
    self.dieRollAnimationContent.Size = UDim2.fromScale(1, 1)
    self.dieRollAnimationContent.Font = Enum.Font.SourceSansBold
    self.dieRollAnimationContent.TextSize = 36
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
    if not GameUtils.firstUserCanPlayAsSecondUser(self.tableDescription, self.localUserId, userId) then
        return
    end

    local content = GuiUtils.addRowAndReturnRowContent(parent, "UserRow", {
        labelText = "Roll for " .. PlayerUtils.getNameAsync(userId),
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
        labelText = PlayerUtils.getNameAsync(userId) .. ":",
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

function ClientGameInstance:onGameStateUpdated(opt_actionDescription: GameTypes.ActionDescription?)
    -- if there's a description, first play it out/animate it.
    if opt_actionDescription then
        -- Disable controls while animating.
        self:disableAllButtons()

        local actionType = opt_actionDescription.actionType
        if actionType == ActionTypes.RollDie then
            self:animateDieRoll(opt_actionDescription, function()
                self:updateScores()

                -- Give everyone a second to digest this.
                task.wait(1)
                self:displayNewTurnOrGameEnd()
            end)
        end
    else
        self:updateScores()
    end
end

function ClientGameInstance:updateButtonActiveStates()
    local currentPlayerId = GameUtils.getCurrentPlayerUserId(self.gameState)
    for userId, buttonSet in pairs(self.buttonsByUserId) do
        local canPlay = false
        if not self.gameState.opt_winnerUserId then
            if userId == currentPlayerId then
                canPlay = GameUtils.firstUserCanPlayAsSecondUser(self.tableDescription, self.localUserId, userId)
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
        local currentPlayerId = GameUtils.getCurrentPlayerUserId(self.gameState)
        local currentPlayerName = PlayerUtils.getNameAsync(currentPlayerId)
        message = GuiUtils.bold(currentPlayerName) .. ": it's your turn."
    else
        local winnerName = PlayerUtils.getNameAsync(self.gameState.opt_winnerUserId)
        local score = self.gameState.scoresByUserId[self.gameState.opt_winnerUserId]
        message = GuiUtils.bold(winnerName) .. " wins with a score of " .. self.gameState.scoresByUserId[score] .. " points!"
    end
    self.messageLog:addMessage(message)

    -- Update all the buttons.
    self:updateButtonActiveStates()
end

function ClientGameInstance:animateDieRoll(actionDescription: GameTypes.ActionDescription, onDieRollFinished: () -> ())
    local currentPlayerId = GameUtils.getCurrentPlayerUserId(self.gameState)
    local currentPlayerName = PlayerUtils.getNameAsync(currentPlayerId)
    local message = currentPlayerName .. " is rolling the " .. GameUtils.getDieName(actionDescription.actionDetails.dieType) .. " die."
    self.messageLog:addMessage(message)

    if actionDescription.dieType == DieTypes.Standard then
        self.dieRollAnimationContent.BackgroundColor3 = Color3.fromRGB(255, 230, 240)
    elseif actionDescription.dieType == DieTypes.Smushed then
        self.dieRollAnimationContent.BackgroundColor3 = Color3.fromRGB(230, 255, 240)
    else
        self.dieRollAnimationContent.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
    end

    self.dieRollAnimationContent.Text = tostring(actionDescription.actionDetails.rollResult)

    -- Animate it in
    local uiScale  = self.dieRollAnimationContent:FindFirstChild("TweenScaling")
    assert(uiScale, "No uiScale found")
    uiScale.Scale = 0
    self.dieRollAnimationContent.Rotation = 980

    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, false, 0)
    local t1 = tweenService:Create(uiScale, tweenInfo, {Scale = 1})
    local t2 = tweenService:Create(self.dieRollAnimationContent, tweenInfo, {Rotation = 0})
    t1.Play()
    t2.Play()
    t1.Completed:Connect(function()
        local _message = currentPlayerName .. " rolled a " .. tostring(actionDescription.actionDetails.rollResult)
        self.messageLog:addMessage(_message)

        onDieRollFinished()
    end)
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