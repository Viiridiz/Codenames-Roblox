local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)

local Lobby = require(script.Parent.Parent.Components.Lobby)
local WaitingRoom = require(script.Parent.Parent.Components.WaitingRoom)
local Board = require(script.Parent.Parent.Components.Board.Board)

local GameController = Knit.CreateController { Name = "GameController" }

function GameController:KnitStart()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameUI"
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	self.ScreenGui = screenGui
	self.CurrentRoomCode = nil
	self.MyRole = "None"
	
	local RoomService = Knit.GetService("RoomService")
	self.GameService = Knit.GetService("GameService")

	RoomService.GameStarted:Connect(function()
		print("Controller: Game Started Signal")
		self:MountBoard()
	end)
	
	self:MountLobby()
end

function GameController:MountLobby()
	if self.Handle then Roact.unmount(self.Handle) end
	local RoomService = Knit.GetService("RoomService")

	local element = Roact.createElement(Lobby, {
		OnCreate = function()
			RoomService:CreateRoom():andThen(function(code)
				self.CurrentRoomCode = code
				self:MountWaitingRoom()
			end)
		end,
		OnJoin = function(code)
			RoomService:JoinRoom(code):andThen(function(success)
				if success then
					self.CurrentRoomCode = code
					self:MountWaitingRoom()
				end
			end)
		end
	})
	self.Handle = Roact.mount(element, self.ScreenGui)
end

function GameController:MountWaitingRoom()
	if self.Handle then Roact.unmount(self.Handle) end
	local RoomService = Knit.GetService("RoomService")
	
	local element = Roact.createElement(WaitingRoom, {
		RoomCode = self.CurrentRoomCode,
		OnSelectSlot = function(slotName)
			self.MyRole = slotName 
			RoomService:JoinSlot(self.CurrentRoomCode, slotName)
		end,
		OnStartGame = function()
			RoomService:StartGame(self.CurrentRoomCode)
		end,
		OnLeave = function()
			self.CurrentRoomCode = nil
			self.MyRole = "None"
			self:MountLobby()
		end
	})
	self.Handle = Roact.mount(element, self.ScreenGui)
end

function GameController:MountBoard()
	if self.Handle then Roact.unmount(self.Handle) end
	
	local element = Roact.createElement(Board, {
		MyRole = self.MyRole, 
		
		OnCardClick = function(cardId)
			self.GameService:GuessWord(cardId)
		end,
		
		OnGiveClue = function(word, number)
			print("Controller: Sending Clue ->", word, number)
			self.GameService:GiveClue(word, number)
		end,

		OnExit = function()
			self.CurrentRoomCode = nil
			self.MyRole = "None"
			self:MountLobby()
		end
	})

	self.Handle = Roact.mount(element, self.ScreenGui)
end

return GameController