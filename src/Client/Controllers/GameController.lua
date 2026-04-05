local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)

local Lobby = require(script.Parent.Parent.Components.Lobby)
local WaitingRoom = require(script.Parent.Parent.Components.WaitingRoom)
local Board = require(script.Parent.Parent.Components.Board.Board)

local GameController = Knit.CreateController { Name = "GameController" }

function GameController:KnitStart()

    local TextChatService = game:GetService("TextChatService")
    TextChatService.OnIncomingMessage = function(message)
        local props = Instance.new("TextChatMessageProperties")
        if message.TextSource then
            local player = game:GetService("Players"):GetPlayerByUserId(message.TextSource.UserId)
            if player then
                local tag = player:GetAttribute("EquippedTag")
                if tag then
                    local color = "#FFFFFF"
                    if tag == "NEON TAG" then color = "#9b59b6"
                    elseif tag == "GOLD TAG" then color = "#f1c40f"
                    elseif tag == "RUBY TAG" then color = "#e74c3c"
                    elseif tag == "DIAMOND TAG" then color = "#3498db" end
                    
                    props.PrefixText = "<font color='" .. color .. "'>[" .. tag .. "]</font> " .. message.PrefixText
                end
            end
        end
        return props
    end
    
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
        OnCreate = function(difficulty, wordPack, isPublic)
            RoomService:CreateRoom(difficulty, wordPack, isPublic):andThen(function(code)
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