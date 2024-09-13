--[[
Logic for creating and handling events on the server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameUtils = require(SRBGCShared.Modules.GameUtils)

-- SRBGCServer
local SRBGCServer = script.Parent.Parent.Parent
local GameInstance = require(SRBGCServer.Modules.MockGame.GameInstance)

local ServerEventManagement = {}

-- Notify these players of this event.
local function sendEventForPlayers(event: RemoteEvent, players: {Players}, ...)
    assert(event, "Event not found")
    for _, player in ipairs(players) do
        event:FireClient(player, ...)
    end
end

local function getOrMakeFolderForGameEvents(setGameInstanceGUID: CommonTypes.setGameInstanceGUID): Folder
    local folderName = GameUtils.getGameEventFolderName(setGameInstanceGUID)
    local folder = ReplicatedStorage:FindFirstChild(folderName)
    if folder then
        assert(folder:IsA("Folder"), "Expected folder, got " .. folder.ClassName)
    else
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = ReplicatedStorage
    end
    return folder
end

--[[
Adding a remote event on server.
If no folder with given name, make one.
Make event with given name and handler.
]]
local function createRemoteEvent(setGameInstanceGUID: CommonTypes.setGameInstanceGUID, eventName: string, opt_onServerEvent)
    local folder = getOrMakeFolderForGameEvents(setGameInstanceGUID)
    local event = Instance.new("RemoteEvent")
    event.Name = eventName
    event.Parent = folder
    if opt_onServerEvent then
        event.OnServerEvent:Connect(opt_onServerEvent)
    end
end

local function sendEventForPlayersInGame(gameInstance: GameInstance.GameInstance, eventName: string, ...)
    local folder = getOrMakeFolderForGameEvents(gameInstance:getGUID())
    assert(folder, "Folder not found")
    local players = gameInstance:getPlayers()
    local event = folder:FindFirstChild(eventName)
    assert(event, "Event not found")
    sendEventForPlayers(event, players, ...)
end

ServerEventManagement.broadcastGameState = function(gameInstance:GameInstance.GameInstance, opt_actionDescription: GameTypes.ActionDescription)
    local gameState = gameInstance:getGameState()
    sendEventForPlayersInGame(gameInstance, "GameUpdated", gameState, opt_actionDescription)
end

--[[
Startup Function making all the events where client sends to server.
]]
ServerEventManagement.setupGameInstanceEvents = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    -- Events sent from client to server.
    -- Event to create a new table.
    createRemoteEvent(gameInstanceGUID, "RollDie", function(player: Player, userId: CommonTypes.UserId)
        -- add the logic for die roll here.
        local gameInstance = GameInstance.getGameInstance(gameInstanceGUID)
        assert(gameInstance, "Game instance not found for " .. gameInstanceGUID)
        local result = gameInstance:rollDie(userId)
        local actionDescrition = {
            userId = userId,
            action = "RollDie",
            result = result,
        }
        ServerEventManagement.broadcastGameState(gameInstance, actionDescrition)
    end)

    -- Events sent from server to client.
    -- Notification that a new table was created.
    createRemoteEvent(gameInstanceGUID, "GameUpdated")
end

ServerEventManagement.createServerToClientEvents = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
end


return ServerEventManagement