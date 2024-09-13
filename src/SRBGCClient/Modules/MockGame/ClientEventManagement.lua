--[[
Client side event management: listening to events from the server, sending events to server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ClientEventManagement = {}

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
if not gameEvents then
    assert(false, "GameEvents missing")
    return
end
local gameFunctions = ReplicatedStorage:WaitForChild("GameFunctions")
if not gameFunctions then
    assert(false, "GameFunctions missing")
    return
end

ClientEventManagement.listenToServerEvents = function(onTableCreated: (tableDescription: CommonTypes.TableDescription) -> nil,
    onTableDestroyed: (tableId: CommonTypes.TableId) -> nil,
    onTableUpdated: (tableDescription: CommonTypes.TableDescription) -> nil,
    onHostAbortedGame: (tableId: CommonTypes.TableId) -> nil,
    onPlayerLeftTable: (tableId: CommonTypes.TableId, userId: CommonTypes.UserId) -> nil)

    assert(onTableCreated, "tableCreated must be provided")
    assert(onTableDestroyed, "tableDestroyed must be provided")
    assert(onTableUpdated, "tableUpdated must be provided")

    local event
    event = gameEvents:WaitForChild("TableCreated")
    assert(event, "TableCreated event missing")
    event.OnClientEvent:Connect(function(...)
        onTableCreated(...)
    end)

    event = gameEvents:WaitForChild("TableDestroyed")
    assert(event, "TableDestroyed event missing")
    event.OnClientEvent:Connect(onTableDestroyed)

    event = gameEvents:WaitForChild("TableUpdated")
    assert(event, "TableUpdated event missing")
    event.OnClientEvent:Connect(onTableUpdated)

    event = gameEvents:WaitForChild("HostAbortedGame")
    assert(event, "HostAbortedGame event missing")
    event.OnClientEvent:Connect(onHostAbortedGame)

    event = gameEvents:WaitForChild("PlayerLeftTable")
    assert(event, "PlayerLeftTable event missing")
    event.OnClientEvent:Connect(onPlayerLeftTable)
end

local gameInstanceGUID = nil
ClientEventManagement.setGameInstanceGUID = function(_gameInstanceGUID: string)
    assert(_gameInstanceGUID, "setGameInstanceGUID must be provided")
    gameInstanceGUID = _gameInstanceGUID
end

ClientEventManagement.clearsetGameInstanceGUID = function()
    gameInstanceGUID = nil
end

ClientEventManagement.getEventFolderForCurrentGame = function(): Folder
    assert(gameInstanceGUID, "setGameInstanceGUID must be set")
    local folderName = "GameEvents_" .. gameInstanceGUID
    local folder = ReplicatedStorage:WaitForChild(folderName)
    assert(folder, "Folder not found: " .. folderName)
    return folder
end

ClientEventManagement.getEventForCurrentGame = function(eventName: string): RemoteEvent
    local folder = ClientEventManagement.getEventFolderForCurrentGame()
    local event = folder:WaitForChild(eventName)
    assert(event, "Event not found: " .. eventName)
    return event
end

ClientEventManagement.requestRollDie = function(userId: CommonTypes.UserId)
    local event = ClientEventManagement.getEventForCurrentGame("RollDie")
    assert(event, "RollDie event missing")
    event:FireServer(userId)
end



return ClientEventManagement