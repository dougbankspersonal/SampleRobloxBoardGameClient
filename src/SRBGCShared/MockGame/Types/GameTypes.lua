local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameTypes = {}

export type GameState = {
    scoresByUserId: { [CommonTypes.UserId]: number },
    playerIdsInTurnOrder: {CommonTypes.UserId},
    currentPlayerIndex: number,
    opt_winnerUserId: CommonTypes.UserId?,
}

export type DieType = number
export type DieTypes = {
    Standard: DieType,
    Smushed: DieType,
    Advantage: DieType,
}

export type ActionType = number
export type ActionTypes = {
    DieRoll: ActionType,
}

export type ActionDetailsDieRoll = {
    dieType: DieType,
    dieRollResult: number,
}

-- If there were other action types, 'or' them together here.
export type ActionDetails = ActionDetailsDieRoll

export type ActionDescription = {
    actionType: ActionType,
    actorUserId: CommonTypes.UserId,
    actionDetails: ActionDetails,
}


return GameTypes