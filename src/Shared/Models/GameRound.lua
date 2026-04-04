local GameRound = {}
GameRound.__index = GameRound

function GameRound.new()
    local self = setmetatable({}, GameRound)
    self.Room = nil
    self.State = "Clue Phase"
    self.CurrentTurn = require(script.Parent.Parent.Enums.Team).RED
    self.ActiveRole = require(script.Parent.Parent.Enums.Role).SPYMASTER
    self.TurnTimer = 60
    self.ScoreRed = 0
    self.ScoreBlue = 0
    self.Winner = nil
    self.ClueLog = {} 
    return self
end

function GameRound:Associate_Room(room)
    self.Room = room
end

function GameRound:Validate_Operative_Turn(player)
    local RoleEnum = require(script.Parent.Parent.Enums.Role)
    local pModel = nil
    for _, p in ipairs(self.Room.Players) do
        if tostring(p.UserId) == tostring(player.UserId) then pModel = p break end
    end
    
    if not pModel then return false end
    return pModel.Role == RoleEnum.OPERATIVE and pModel.Team == self.CurrentTurn
end

function GameRound:Validate_Spymaster_Turn(player)
    local RoleEnum = require(script.Parent.Parent.Enums.Role)
    local pModel = nil
    for _, p in ipairs(self.Room.Players) do
        if tostring(p.UserId) == tostring(player.UserId) then pModel = p break end
    end
    
    if not pModel then return false end
    return pModel.Role == RoleEnum.SPYMASTER and pModel.Team == self.CurrentTurn
end

function GameRound:Increment_Score()
    local TeamEnum = require(script.Parent.Parent.Enums.Team)
    if self.CurrentTurn == TeamEnum.RED then
        self.ScoreRed = self.ScoreRed + 1
    else
        self.ScoreBlue = self.ScoreBlue + 1
    end
end

function GameRound:Set_State(newState)
    self.State = newState
end

function GameRound:Switch_Turn()
    local TeamEnum = require(script.Parent.Parent.Enums.Team)
    local RoleEnum = require(script.Parent.Parent.Enums.Role)
    
    if self.ActiveRole == RoleEnum.OPERATIVE then
        self.CurrentTurn = (self.CurrentTurn == TeamEnum.RED) and TeamEnum.BLUE or TeamEnum.RED
    end
    
    self.ActiveRole = (self.ActiveRole == RoleEnum.SPYMASTER) and RoleEnum.OPERATIVE or RoleEnum.SPYMASTER
    self.TurnTimer = 60
end

-- US-5.3: Upgraded to distribute Economy Rewards
function GameRound:Set_Winner(teamEnum)
    self.Winner = teamEnum
    self.State = "GameOver"
    
    if self.Room then
        for _, p in ipairs(self.Room.Players) do
            if p.Team == teamEnum then
                p:Increment_Win()
                p:Add_Coins(50)
            elseif p.Team ~= "None" then
                p:Reset_Streak()
                p:Add_Coins(10)
            end
        end
    end
end

-- US-5.2: Disconnect Handling
function GameRound:AbortGame()
    self.State = "Aborted"
    self.Winner = nil
    
    -- Compensate players
    if self.Room then
        for _, p in ipairs(self.Room.Players) do
             if p.Team ~= "None" then
                 p:Add_Coins(25) 
             end
        end
    end
end

function GameRound:Append_ClueLog(word, number)
    table.insert(self.ClueLog, {Word = word, Number = number})
end

function GameRound:Get_Turn_String()
    return tostring(self.CurrentTurn) .. tostring(self.ActiveRole)
end

return GameRound