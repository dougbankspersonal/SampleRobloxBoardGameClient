local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameTypes = {}

export type GameState = {
    scoresByUserId: { [CommonTypes.UserId]: number },
    gameOver: boolean,
}

return GameTypes