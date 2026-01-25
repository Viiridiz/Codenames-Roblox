local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local RoomService = Knit.CreateService {
	Name = "RoomService",
	Client = {
		RoomUpdate = Knit.CreateSignal(),
		GameStarted = Knit.CreateSignal()
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
			RedSpymaster = nil, RedOperative = nil,
			BlueSpymaster = nil, BlueOperative = nil
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
	
	local recipients = getRoomPlayers(room)
	if #recipients > 0 then
		self.Client.RoomUpdate:FireFor(recipients, room.Slots, room.Host.Name)
	end
	return true
end

function RoomService:JoinSlot(player, code, slotName)
	local room = activeRooms[code]
	if not room then return false end

	if room.Slots[slotName] == player.Name then
		room.Slots[slotName] = nil
	else
		for slot, owner in pairs(room.Slots) do
			if owner == player.Name then room.Slots[slot] = nil end
		end
		if room.Slots[slotName] == nil then
			room.Slots[slotName] = player.Name
		end
	end
	
	local recipients = getRoomPlayers(room)
	if #recipients > 0 then
		self.Client.RoomUpdate:FireFor(recipients, room.Slots, room.Host.Name)
	end
	return true
end

function RoomService:StartGame(player, code)
	local room = activeRooms[code]
	if not room then return false end
	if room.Host ~= player then return false end

	room.State = "Playing"
	print("RoomService: STARTING GAME...")
	
	-- [[ CRITICAL: WAKE UP GAMESERVICE ]] --
	local GameService = Knit.GetService("GameService")
	if GameService then
		print("RoomService: Calling GameService:StartGame()")
		GameService:StartGame() 
	else
		warn("RoomService: GameService NOT FOUND")
	end
	
	local recipients = getRoomPlayers(room)
	if #recipients > 0 then
		self.Client.GameStarted:FireFor(recipients)
	end
	
	return true
end

-- [[ FIX: EXPLICITLY DEFINE GETROOM FOR TESTS ]] --
function RoomService:GetRoom(code)
	return activeRooms[code]
end

-- CLIENT METHODS
function RoomService.Client:CreateRoom(player) return self.Server:CreateRoom(player) end
function RoomService.Client:JoinRoom(player, code) return self.Server:JoinRoom(player, code) end
function RoomService.Client:JoinSlot(player, code, slot) return self.Server:JoinSlot(player, code, slot) end
function RoomService.Client:StartGame(player, code) return self.Server:StartGame(player, code) end

return RoomService