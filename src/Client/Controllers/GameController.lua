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
    self.MyTeam = "None"
    self.MyRole = "None"
    
    local RoomService = Knit.GetService("RoomService")
    self.GameService = Knit.GetService("GameService")

    self.GameService.GameStarted:Connect(function()
        print("Controller: Game Started Signal")
        self:MountBoard()
    end)
    
    self:MountLobby()
end

function GameController:MountLobby()
    if self.Handle then Roact.unmount(self.Handle) end
    local RoomService = Knit.GetService("RoomService")

    local element = Roact.createElement(Lobby, {
        -- US-5.1: Now accepts dynamic difficulty and wordpack from the modal
        OnCreate = function(difficulty, wordPack)
            RoomService:CreateRoom(difficulty, wordPack):andThen(function(code)
                if code then
                    self.CurrentRoomCode = code
                    self:MountWaitingRoom()
                end
            end)
        end,
        OnJoin = function(code)
            RoomService:JoinRoom(code, "None", "Operative"):andThen(function(success)
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
        OnSelectSlot = function(teamName, roleName)
            self.MyTeam = teamName
            self.MyRole = roleName 
            RoomService:JoinRoom(self.CurrentRoomCode, teamName, roleName)
        end,
        OnStartGame = function()
            self.GameService:StartGame(self.CurrentRoomCode)
        end,
        OnLeave = function()
            RoomService:LeaveRoom(self.CurrentRoomCode)
            self.CurrentRoomCode = nil
            self.MyTeam = "None"
            self.MyRole = "None"
            self:MountLobby()
        end
    })
    self.Handle = Roact.mount(element, self.ScreenGui)
end

function GameController:MountBoard()
    if self.Handle then Roact.unmount(self.Handle) end
    
    local element = Roact.createElement(Board, {
        MyTeam = self.MyTeam,
        MyRole = self.MyRole, 
        
        OnCardClick = function(cardId)
            self.GameService:SelectCard(cardId)
        end,
        
        OnGiveClue = function(word, number)
            print("Controller: Sending Clue ->", word, number)
            self.GameService:SubmitClue(word, number)
        end,

        OnExit = function()
            self.CurrentRoomCode = nil
            self.MyTeam = "None"
            self.MyRole = "None"
            self:MountLobby()
        end
    })

    self.Handle = Roact.mount(element, self.ScreenGui)
end

return GameController