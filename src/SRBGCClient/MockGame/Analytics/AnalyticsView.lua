--[[
Rendering game analytics.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cryo = require(ReplicatedStorage.Cryo)

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- RobloxBoardGameClient
local RobloxBoardGameClient = script.Parent.Parent.Parent.Parent.RobloxBoardGameClient
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local AnalyticsEventTypes = require(SRBGCShared.MockGame.Globals.AnalyticsEventTypes)

local AnalyticsView = {}

export type PlayerIndex = number
export type WinCount = number
export type NumPlayers = number

export type NthPlayerWins = {
    [PlayerIndex]: WinCount
}

export type NthPlayerWinsByNumPlayers = {
    [NumPlayers]: NthPlayerWins
}

local function filterRecordsForMatchingGameOptions(records: {CommonTypes.AnalyticsGameRecord}, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions)
    local filteredRecords = {}
    for _, record in records do
        local gameDescription = record.gameDescription
        local optionsMatch = Utils.tablesMatch(gameDescription.nonDefaultGameOptions, nonDefaultGameOptions)
        if optionsMatch then
            table.insert(filteredRecords, record)
        end
    end
    return filteredRecords
end

local function getNthPlayerWinsByNumPlayers(gameDetails: CommonTypes.GameDetails, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions, analyticsGameRecords: {CommonTypes.AnalyticsGameRecord})
    local filteredRecords = filterRecordsForMatchingGameOptions(analyticsGameRecords, nonDefaultGameOptions)
    local nthPlayerWinsByNumPlayers = {} :: NthPlayerWinsByNumPlayers
    -- Init the table.
    for i = gameDetails.minPlayers, gameDetails.maxPlayers do
        nthPlayerWinsByNumPlayers[i] = {}
        for j = 1, gameDetails.maxPlayers do
            nthPlayerWinsByNumPlayers[i][j] = 0
        end
    end

    for gameRecord in filteredRecords do
        local numPlayers = #gameRecord.gameDescription.memberUserIds
        if not nthPlayerWinsByNumPlayers[numPlayers] then
            nthPlayerWinsByNumPlayers[numPlayers] = {}
        end
        local nthPlayerWins = nthPlayerWinsByNumPlayers[numPlayers]
        for event in gameRecord.events do
            if event.eventType == AnalyticsEventTypes.GameWin then
                local winnerIndex = event.details.winnerIndex
                if not nthPlayerWins[winnerIndex] then
                    nthPlayerWins[winnerIndex] = 0
                end
                nthPlayerWins[winnerIndex] = nthPlayerWins[winnerIndex] + 1
                break
            end
        end
    end
    return nthPlayerWinsByNumPlayers
end

local function makeTable(parent: GuiObject, title:string, rows, numColumns)
    Utils.debugPrint("Analytics", "makeTable 001")
    Utils.debugPrint("Analytics", "makeTable title = ", title)
    Utils.debugPrint("Analytics", "makeTable rows = ", rows)
    Utils.debugPrint("Analytics", "makeTable numColumns = ", numColumns)
    local titleRow = GuiUtils.addRowAndReturnRowContent(parent, "TableTitle", {
        horizontalAlignment = Enum.HorizontalAlignment.Left,
    })

    GuiUtils.addTextLabel(titleRow, title, {
        Name = "Title",
        Font = Enum.Font.SourceSansBold,
        TextSize = 18,
    })

    for _, row in rows do
        local thisRowContnet = GuiUtils.addRowAndReturnRowContent(parent, "TableRow", {
            horizontalAlignment = Enum.HorizontalAlignment.Left,
        })
        for i = 1, numColumns do
           local message = row[i] or ""
           message = tostring(message)
           GuiUtils.addTextLabel(thisRowContnet, message, {
               Name = "Cell",
               Font = Enum.Font.SourceSans,
               TextSize = 14,
               AutomaticSize = Enum.AutomaticSize.Y,
               Size = UDim2.fromOffset(100, 20),
               BorderSizePixel = 1,
           })
        end
    end
    Utils.debugPrint("Analytics", "makeTable 002")

end

local function addNthPlayerAdvantageTable(gameId: CommonTypes.GameId, parent: Frame, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions, analyticsGameRecords: {CommonTypes.AnalyticsGameRecord})
    local title = "Nth Player Advantage"
    local gameDetails = GameDetails.getGameDetails(gameId)

    local rows = {}
    Utils.debugPrint("Analytics", "addNthPlayerAdvantageTable gameDetails = ", gameDetails)

    local nthPlayerWinsByNumPlayers = getNthPlayerWinsByNumPlayers(gameDetails, nonDefaultGameOptions, analyticsGameRecords)
    Utils.debugPrint("Analytics", "addNthPlayerAdvantageTable nthPlayerWinsByNumPlayers = ", nthPlayerWinsByNumPlayers)

    local topRow = {} :: {string}
    Utils.debugPrint("Analytics", "addNthPlayerAdvantageTable 001 topRow = ", topRow)
    table.insert(topRow, " ")
    Utils.debugPrint("Analytics", "addNthPlayerAdvantageTable 002 topRow = ", topRow)
    for i = 1, gameDetails.maxPlayers do
        table.insert(topRow, "Player " .. tostring(i))
    end
    Utils.debugPrint("Analytics", "addNthPlayerAdvantageTable 003 topRow = ", topRow)
    table.insert(rows, topRow)
    Utils.debugPrint("Analytics", "addNthPlayerAdvantageTable rows = ", rows)

    for numPlayers = gameDetails.minPlayers, gameDetails.maxPlayers do
        local row = {}
        table.insert(row, tostring(numPlayers) .. " Players")
        row = Cryo.List.join(row, nthPlayerWinsByNumPlayers[numPlayers] or {})
        table.insert(rows, row)
    end

    makeTable(parent, title, rows, gameDetails.maxPlayers + 1)
end

function AnalyticsView.renderAnalyticsRecords(gameId: CommonTypes.GameId, parent: Frame, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions, analyticsGameRecords: {CommonTypes.AnalyticsGameRecord})
    local rowName = "MockGameAnalyticsRow"
    -- Clean out anything I might have already had in there.
    local previous = parent:FindFirstChild(rowName)
    if previous then
        previous:Destroy()
    end

    local rowContent = GuiUtils.addRowAndReturnRowContent(parent, rowName, {
        horizontalAlignment = Enum.HorizontalAlignment.Left,
    })

    Utils.debugPrint("Analytics", "renderAnalyticsRecords gameId = ", gameId)
    Utils.debugPrint("Analytics", "renderAnalyticsRecords nonDefaultGameOptions = ", nonDefaultGameOptions)
    Utils.debugPrint("Analytics", "renderAnalyticsRecords analyticsGameRecords = ", analyticsGameRecords)

    -- Put in a max size scrolling frame.
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "AnalyticsScrollingFrame"
    scrollingFrame.Parent = rowContent
    scrollingFrame.Size = UDim2.fromScale(1, 1)
    scrollingFrame.CanvasSize = UDim2.fromScale(0, 0)
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.XY

    addNthPlayerAdvantageTable(gameId, scrollingFrame, nonDefaultGameOptions, analyticsGameRecords)
    -- addDieAdvantageTable(parent, analyticsRecords)
end

return AnalyticsView