local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)

local Lobby = require(script.Parent.Parent.Components.Lobby)
local WaitingRoom = require(script.Parent.Parent.Components.WaitingRoom)
local Board = require(script.Parent.Parent.Components.Board.Board)

-- ==========================================
-- CINEMATIC INTRO COMPONENT
-- ==========================================
local IntroScreen = Roact.Component:extend("IntroScreen")

function IntroScreen:init()
    self.bgRef = Roact.createRef()
    self.textRef = Roact.createRef()
    self.dotRef = Roact.createRef()
end

function IntroScreen:didMount()
    local bg = self.bgRef:getValue()
    local text = self.textRef:getValue()
    local dot = self.dotRef:getValue()

    TweenService:Create(text, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        TextTransparency = 0, 
        Position = UDim2.fromScale(0.5, 0.5)
    }):Play()
    
    TweenService:Create(dot, TweenInfo.new(1.5), {BackgroundTransparency = 0}):Play()

    local pulseTween = TweenService:Create(dot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 0.5
    })
    pulseTween:Play()

    task.delay(4.5, function()
        TweenService:Create(text, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            TextTransparency = 1, 
            Position = UDim2.fromScale(0.5, 0.45)
        }):Play()
        
        TweenService:Create(dot, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.52)
        }):Play()
        
        task.wait(0.4)
        pulseTween:Cancel()

        local slideUp = TweenService:Create(bg, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
            Position = UDim2.fromScale(0, -1) -- Moves it entirely off the top of the screen
        })
        slideUp:Play()
        slideUp.Completed:Wait()
        
        if self.props.OnComplete then
            self.props.OnComplete()
        end
    end)
end

function IntroScreen:render()
    return Roact.createElement("Frame", {
        [Roact.Ref] = self.bgRef,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        ZIndex = 100,
    }, {
        Text = Roact.createElement("TextLabel", {
            [Roact.Ref] = self.textRef,
            Text = "made with love by akeyla, ping and kevin.",
            Font = Enum.Font.GothamMedium,
            TextSize = 28,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            TextTransparency = 1,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.54),
            ZIndex = 105,
        }),
        
        LoadingDot = Roact.createElement("Frame", {
            [Roact.Ref] = self.dotRef,
            Size = UDim2.fromOffset(12, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.58),
            BackgroundColor3 = Color3.fromRGB(52, 152, 219),
            BackgroundTransparency = 1,
            ZIndex = 105,
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
        })
    })
end

-- ==========================================
-- GAME CONTROLLER
-- ==========================================
local GameController = Knit.CreateController { Name = "GameController" }

function GameController:KnitStart()
    task.spawn(function()
        local success = false
        while not success do
            success, _ = pcall(function()
                StarterGui:SetCore("ResetButtonCallback", false)
            end)
            task.wait(0.2)
        end
    end)

    local function freezePlayer(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.UseJumpPower = true
        end
    end
    
    if Players.LocalPlayer.Character then 
        freezePlayer(Players.LocalPlayer.Character) 
    end
    Players.LocalPlayer.CharacterAdded:Connect(freezePlayer)

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
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    self.ScreenGui = screenGui
    self.CurrentRoomCode = nil
    self.MyTeam = "None"
    self.MyRole = "None"
    
    local RoomService = Knit.GetService("RoomService")
    self.GameService = Knit.GetService("GameService")

    self.GameService.GameStarted:Connect(function()
        self:MountBoard()
    end)
    
    self:MountLobby()
    self:MountIntro()
end

function GameController:MountIntro()
    if self.IntroHandle then Roact.unmount(self.IntroHandle) end
    
    local element = Roact.createElement(IntroScreen, {
        OnComplete = function()
            if self.IntroHandle then
                Roact.unmount(self.IntroHandle)
                self.IntroHandle = nil
            end
        end
    })
    
    self.IntroHandle = Roact.mount(element, self.ScreenGui)
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
            RoomService:JoinRoom(code, "None", "None"):andThen(function(success)
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