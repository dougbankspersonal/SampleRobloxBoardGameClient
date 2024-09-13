local GameStartup = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCServer
local SRBGCServer = script.Parent.Parent.Parent
local ServerEventManagement = require(SRBGCServer.Modules.MockGame.ServerEventManagement)
local GameInstance = require(SRBGCServer.Modules.MockGame.GameInstance)

GameStartup.onPlay = function(gameInstanceGUID: CommonTypes.GameInstanceGUID, tableDescription: CommonTypes.TableDescription)
    -- Should be nothing with this GUID yet.
    local existingGameInstance = GameInstance.findGameInstance(gameInstanceGUID)
    assert(existingGameInstance == nil, "Game instance already exists with GUID " .. gameInstanceGUID)

    -- Make the game, broadcast state.
    local gameInstance = GameInstance.new(gameInstanceGUID, tableDescription)

    -- Setup events for the game.
    ServerEventManagement.setupGameInstanceEvents(gameInstanceGUID)

    -- Broadcast initial games state.
    ServerEventManagement.broadcastGameState(gameInstance)
end

return GameStartup