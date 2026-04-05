-- PLAYER FROM DOMAIN MODEL
local PlayerModel = {}
PlayerModel.__index = PlayerModel

function PlayerModel.new(robloxPlayer, team, role)
    local self = setmetatable({}, PlayerModel)
    self.UserId = tostring(robloxPlayer.UserId)
    self.UserName = robloxPlayer.Name
    self.Team = team
    self.Role = role
    
    -- US-5.3: Persistence & Economy Additions
    self.Coins = 0
    self.Wins = 0
    self.Streak = 0
    
    return self
end

function PlayerModel:IsPlayer(robloxPlayer)
    return self.UserId == tostring(robloxPlayer.UserId)
end

function PlayerModel:GetFullName()
    return tostring(self.Team) .. tostring(self.Role)
end

-- US-5.3: Economy Methods
function PlayerModel:Add_Coins(amount)
    self.Coins = self.Coins + amount
end

function PlayerModel:Increment_Win()
    self.Wins = self.Wins + 1
    self.Streak = self.Streak + 1
end

function PlayerModel:Reset_Streak()
    self.Streak = 0
end

function PlayerModel:LoadData(savedData)
    if not savedData then return end
    self.Coins = savedData.Coins or 0
    self.Wins = savedData.Wins or 0
    self.Streak = savedData.Streak or 0
end

return PlayerModel