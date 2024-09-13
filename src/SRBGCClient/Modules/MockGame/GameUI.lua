local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)

-- RobloxBoardGameStarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent.Parent.RobloxBoardGameStarterGui
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)

-- SRBGCClient
local SRBGCClient = script.Parent.Parent.Parent
local ClientEventManagement = require(SRBGCClient.Modules.ClientEventManagement)

local Cryo = require(ReplicatedStorage.Cryo)

local GameUI = {}

local latestLabel : TextLabel
local scoreLabel : TextLabel
local scoreByUserId : {[number]: number}

local sortedUserIds : {CommonTypes.UserId}
local playButtons  = {}

local getScoreForUser = function(userId: CommonTypes.UserId): number
    return scoreByUserId[userId] or 0
end

local function makeSortedUserIds(members: {[number]: boolean})
    sortedUserIds = Cryo.Dictionary.getKeys(members)
    table.sort(sortedUserIds, function(a, b)
        local aName = PlayerUtils.getNameAsync(a)
        local bName = PlayerUtils.getNameAsync(b)
        return aName < bName
    end)
end

local function incrementScore(userId: number, amount: number)
    local currentScore = getScoreForUser(userId)
    scoreByUserId[userId] = currentScore + amount
end

local getAllScoresText = function(prefix: string): string
    local finalText = prefix
    for _, userId in sortedUserIds do
        local score = getScoreForUser(userId)
        local line = PlayerUtils.getNameAsync(userId) .. ": " .. tostring(score)
        if not finalText then
            finalText = line
        else
            finalText = finalText .. "\n" .. line
        end
    end
end

local updateScoreWidget = function()
    local finalText = getAllScoresText(GuiUtils.bold("Current scores:"))
    scoreLabel.text = finalText
end

local function addButtonForUser(parent: Frame, userId: number, layoutOrder: number): TextButton
    local userName = PlayerUtils.getNameAsync(userId)
    local button = GuiUtils.addStandardTextButtonInContainer(parent, "MockButton" .. tostring(userId), {
        Text = userName .. " rolls the die",
        LayoutOrder = layoutOrder
    })
    layoutOrder = layoutOrder + 1

    button.Activated:Connect(function()
        ClientEventManagement.requestRollDie(userId)
    end)

    return button
end

GameUI.build = function(parent: Frame, tableDescription: CommonTypes.TableDescription)
    Utils.debugPrint("TablePlaying", "Doug: building ui..")
    GuiUtils.addUIListLayout(parent)

    latestLabel = GuiUtils.addTextLabel(parent, "", {
        LayoutOrder = 100,
        Name = "Latest",
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
    })

    scoreLabel = GuiUtils.addTextLabel(parent, "", {
        LayoutOrder = 200,
        Name = "Score",
        RichText = true,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
    })

    scoreByUserId = {}
    sortedUserIds = {}

    task.spawn(function()
        -- Add some buttons to mock user behavior, game outcome, etc.
        local members = tableDescription.members
        local layoutOrder = 10
        for userId, _ in members do
            local textButton = addButtonForUser(parent, userId, layoutOrder)
            table.insert(playButtons, textButton)
            layoutOrder = layoutOrder + 1
        end
        makeSortedUserIds(members)
        updateScoreWidget()
    end)
end

return GameUI