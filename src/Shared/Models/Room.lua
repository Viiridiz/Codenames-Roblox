local Room = {}
Room.__index = Room

function Room.new(code, difficulty, wordPack, isPublic)
    local self = setmetatable({}, Room)
    self.Code = code
    self.HostName = ""
    self.State = "Waiting"
    self.Difficulty = difficulty or "Normal"
    self.WordPack = wordPack or "Standard"
    self.IsPublic = isPublic or false
    self.Players = {}
    return self
end

function Room:Set_Host(robloxPlayer) self.HostName = robloxPlayer.Name end
function Room:Add_Member(playerModel) table.insert(self.Players, playerModel) end
function Room:Remove_Member(userIdStr)
    for i, p in ipairs(self.Players) do
        if p.UserId == userIdStr then table.remove(self.Players, i); break end
    end
end
function Room:Get_Player_Count() return #self.Players end
function Room:Set_State(newState) self.State = newState end
function Room:Check_Host(robloxPlayer) return self.HostName == robloxPlayer.Name end
function Room:Assign_Role(playerModel, roleEnum) playerModel.Role = roleEnum end
function Room:Assign_Team(playerModel, teamEnum) playerModel.Team = teamEnum end
function Room:Update_Player_List(playerModel)
    for i, p in ipairs(self.Players) do
        if p.UserId == playerModel.UserId then self.Players[i] = playerModel; break end
    end
end

function Room:GetRoomData()
    return {
        Code = self.Code,
        HostName = self.HostName,
        Difficulty = self.Difficulty,
        PlayerCount = self:Get_Player_Count(),
        IsPublic = self.IsPublic,
        State = self.State
    }
end

return Room