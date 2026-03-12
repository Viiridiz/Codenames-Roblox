-- PLAYER FROM DOMAIN MODEL
local PlayerModel = {}
PlayerModel.__index = PlayerModel

function PlayerModel.new(robloxPlayer, team, role)
    local self = setmetatable({}, PlayerModel)
    self.UserId = tostring(robloxPlayer.UserId)
    self.UserName = robloxPlayer.Name
    self.Team = team
    self.Role = role
    self.Coins = 0
    return self
end

function PlayerModel:IsPlayer(robloxPlayer)
    return self.UserId == tostring(robloxPlayer.UserId)
end

function PlayerModel:GetFullName()
    return tostring(self.Team) .. tostring(self.Role)
end

return PlayerModel