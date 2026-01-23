local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local RoomService = Knit.CreateService {
	Name = "RoomService",
	Client = {
		RoomUpdate = Knit.CreateSignal(),
		GameStarted = Knit.CreateSignal() -- NEW SIGNAL
	},
}

local activeRooms = {}

local function generateCode()
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local code = ""
	for _ = 1, 4 do
		local rand = math.random(1, #charset)
		code = code .. string.sub(charset, rand, rand)
	end
	return code
end

local function getRoomPlayers(room)
	local players = {}
	for player, _ in pairs(room.Players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			table.insert(players, player)
		end
	end
	return players
end

function RoomService:CreateRoom(hostPlayer)
	local code = generateCode()
	while activeRooms[code] do code = generateCode() end

	local newRoom = {
		Code = code,
		Host = hostPlayer,
		Players = { [hostPlayer] = true },
		Slots = {
			RedSpymaster = nil,
			RedOperative = nil,
			BlueSpymaster = nil,
			BlueOperative = nil
		},
		State = "Waiting"
	}

	activeRooms[code] = newRoom
	print("ROOM MADE: " .. code)
	return code
end

function RoomService:JoinRoom(player, code)
	local room = activeRooms[code]
	if not room then return false end

	room.Players[player] = true
	print("JOINED: " .. code)

	local recipients = getRoomPlayers(room)
	if #recipients > 0 then
		self.Client.RoomUpdate:FireFor(recipients, room.Slots, room.Host.Name)
	end

	return true
end

function RoomService:JoinSlot(player, code, slotName)
	local room = activeRooms[code]
	if not room then return false end

	for slot, owner in pairs(room.Slots) do
		if owner == player.Name then room.Slots[slot] = nil end
	end

	if room.Slots[slotName] == nil then
		room.Slots[slotName] = player.Name
		print("SLOT TAKEN: " .. slotName)

		local recipients = getRoomPlayers(room)
		if #recipients > 0 then
			self.Client.RoomUpdate:FireFor(recipients, room.Slots, room.Host.Name)
		end

		return true
	end
	return false
end

function RoomService:StartGame(player, code)
	local room = activeRooms[code]
	if not room then return false end
	if room.Host ~= player then return false end

	room.State = "Playing"
	print("GAME STARTED: " .. code)
	
	-- SIGNAL TO EVERYONE TO MOVE TO BOARD
	local recipients = getRoomPlayers(room)
	if #recipients > 0 then
		self.Client.GameStarted:FireFor(recipients)
	end
	
	return true
end

function RoomService:GetRoom(code)
	return activeRooms[code]
end

-- CLIENT EXPOSED METHODS
function RoomService.Client:CreateRoom(player)
	return self.Server:CreateRoom(player)
end

function RoomService.Client:JoinRoom(player, code)
	return self.Server:JoinRoom(player, code)
end

function RoomService.Client:JoinSlot(player, code, slotName)
	return self.Server:JoinSlot(player, code, slotName)
end

function RoomService.Client:StartGame(player, code)
	return self.Server:StartGame(player, code)
end

function RoomService:KnitStart()
	print("ROOM SERVICE STARTED")
end

return RoomService