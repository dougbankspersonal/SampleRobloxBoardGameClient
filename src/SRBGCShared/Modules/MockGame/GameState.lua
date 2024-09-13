local GameState = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- SRBGCShared
local SRBGCShared = ReplicatedStorage.SRBGCShared
local GameTypes = require(SRBGCShared.Modules.MockGame.GameTypes)

GameState.createNewGameState = function(tableDescription: CommonTypes.TableDescription): GameTypes.GameState
    local gameState = {}
    gameState.scoresByUserId = {}
    gameState.gameOver = false
    return gameState
end

return GameState
