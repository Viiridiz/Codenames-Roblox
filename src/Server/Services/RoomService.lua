local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local RoomModel = require(ReplicatedStorage.Shared.Models.Room)
local PlayerModel = require(ReplicatedStorage.Shared.Models.Player)

local TeamEnum = require(ReplicatedStorage.Shared.Enums.Team)
local RoleEnum = require(ReplicatedStorage.Shared.Enums.Role)

local RoomService = Knit.CreateService {
    Name = "RoomService",
    Client = {
        RoomUpdate = Knit.CreateSignal(),
        GameStarted = Knit.CreateSignal()
    },
}

local DataStore = {
    ActiveRooms = {}
}

function DataStore:Check_Player_Status(player) return false end
function DataStore:Check_Code(code) return self.ActiveRooms[code] ~= nil end
function DataStore:Save_Room(room) self.ActiveRooms[room.Code] = room end
function DataStore:Get_Room(code) return self.ActiveRooms[code] end
function DataStore:Update_Room(room) self.ActiveRooms[room.Code] = room end

-- US-5.2: Disconnect Handling Hook
function RoomService:KnitStart()
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerDisconnect(player)
    end)
end

function RoomService:Generate_4_Digit_Code()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local code = ""
    for _ = 1, 4 do
        local rand = math.random(1, #charset)
        code = code .. string.sub(charset, rand, rand)
    end
    return code
end

function RoomService:Display_message(msg) warn(msg) end

function RoomService:Display_Lobby(room)
    local slots = {}
    for _, p in ipairs(room.Players) do
        if p.Team and p.Role and p.Team ~= "None" and p.Role ~= "None" then
            slots[p.Team .. p.Role] = p.UserName
        end
    end
    
    for _, p in ipairs(room.Players) do
        local playerInstance = Players:GetPlayerByUserId(tonumber(p.UserId))
        if playerInstance then
            self.Client.RoomUpdate:Fire(playerInstance, slots, room.HostName)
        end
    end
end

-- US-1.1: Create Room
function RoomService:CreateRoom(hostPlayer, difficulty, wordPack)
    local inRoom = DataStore:Check_Player_Status(hostPlayer)
    if inRoom then return nil end

    local code = self:Generate_4_Digit_Code()
    while DataStore:Check_Code(code) do
        code = self:Generate_4_Digit_Code()
    end

    local r = RoomModel.new(code, difficulty, wordPack)
    r:Set_State("Lobby")
    r:Set_Host(hostPlayer)
    
    local hostModel = PlayerModel.new(hostPlayer, "None", "None")
    r:Add_Member(hostModel)

    DataStore:Save_Room(r)
    self:Display_Lobby(r)
    
    return code
end

-- US-1.2: Join Room
function RoomService:JoinRoom(player, code, team, role)
    local r = DataStore:Get_Room(code)
    if r == nil then return false end

    local userIdStr = tostring(player.UserId)

    if team and role and team ~= "None" and role ~= "None" then
        for _, p in ipairs(r.Players) do
            if p.UserId ~= userIdStr and p.Team == team and p.Role == role then
                self:Display_message("Error: Slot already taken")
                return false
            end
        end
    end

    local existingPlayerModel = nil
    for _, p in ipairs(r.Players) do
        if p.UserId == userIdStr then
            existingPlayerModel = p
            break
        end
    end

    if existingPlayerModel then
        if existingPlayerModel.Team == team and existingPlayerModel.Role == role and team ~= "None" then
            r:Assign_Team(existingPlayerModel, "None")
            r:Assign_Role(existingPlayerModel, "None")
        else
            r:Assign_Team(existingPlayerModel, team)
            r:Assign_Role(existingPlayerModel, role)
        end
        r:Update_Player_List(existingPlayerModel)
    else
        if r:Get_Player_Count() >= 4 then return false end
        local pModel = PlayerModel.new(player, team, role)
        r:Add_Member(pModel)
    end

    DataStore:Update_Room(r)
    self:Display_Lobby(r)
    
    return true
end

function RoomService:LeaveRoom(player, code)
    local r = DataStore:Get_Room(code)
    if not r then return false end
    
    local userIdStr = tostring(player.UserId)
    r:Remove_Member(userIdStr) 
    
    DataStore:Update_Room(r)
    self:Display_Lobby(r)
    return true
end

-- US-5.2: Disconnect Logic
function RoomService:HandlePlayerDisconnect(player)
    local userIdStr = tostring(player.UserId)
    for code, r in pairs(DataStore.ActiveRooms) do
        for _, p in ipairs(r.Players) do
            if p.UserId == userIdStr then
                if r.State == "Playing" then
                    Knit.GetService("GameService"):AbortActiveGame(code, player.Name)
                else
                    self:LeaveRoom(player, code)
                end
                return
            end
        end
    end
end

function RoomService:GetRoom(code) return DataStore:Get_Room(code) end

-- CLIENT METHODS
function RoomService.Client:CreateRoom(player, diff, pack) return self.Server:CreateRoom(player, diff, pack) end
function RoomService.Client:JoinRoom(player, code, t, r) return self.Server:JoinRoom(player, code, t, r) end
function RoomService.Client:LeaveRoom(player, code) return self.Server:LeaveRoom(player, code) end

return RoomService