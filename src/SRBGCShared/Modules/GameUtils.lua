local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RobloxBoardGameShared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameUtils = {}

GameUtils.getGameEventFolderName = function(setGameInstanceGUID: CommonTypes.setGameInstanceGUID): string
    return "GameEvents_" .. setGameInstanceGUID
end

return GameUtils