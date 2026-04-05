local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Roact = require(ReplicatedStorage.Packages.Roact)
local Knit = require(ReplicatedStorage.Packages.Knit)

local AnimatedSlot = Roact.Component:extend("AnimatedSlot")

function AnimatedSlot:init()
    self.scaleRef = Roact.createRef()
    local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    self.onHoverEnter = function()
        if self.props.Disabled then return end
        local scale = self.scaleRef:getValue()
        if scale then
            TweenService:Create(scale, TWEEN_INFO, { Scale = 1.05 }):Play()
        end
    end

    self.onHoverLeave = function()
        if self.props.Disabled then return end
        local scale = self.scaleRef:getValue()
        if scale then
            TweenService:Create(scale, TWEEN_INFO, { Scale = 1 }):Play()
        end
    end

    self.onActivate = function()
        if self.props.Disabled then return end
        
        pcall(function() 
            require(game:GetService("ReplicatedStorage").Packages.Knit).GetController("SoundController"):Play("Click") 
        end)

        local scale = self.scaleRef:getValue()
        if scale then
            local tDown = TweenService:Create(scale, TweenInfo.new(0.05), { Scale = 0.95 })
            tDown:Play()
            tDown.Completed:Wait()
            TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
        end
        if self.props.OnClick then self.props.OnClick() end
    end
end

function AnimatedSlot:render()
    return Roact.createElement("TextButton", {
        Text = self.props.Text,
        Size = self.props.Size,
        BackgroundColor3 = self.props.Color,
        BackgroundTransparency = self.props.Transparency,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        AutoButtonColor = false,
        Active = not self.props.Disabled,
        
        [Roact.Event.MouseEnter] = self.onHoverEnter,
        [Roact.Event.MouseLeave] = self.onHoverLeave,
        [Roact.Event.Activated] = self.onActivate,
    }, {
        Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.scaleRef, Scale = 1 }),
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }),
        Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.5 })
    })
end

local WaitingRoom = Roact.Component:extend("WaitingRoom")

local function formatRole(roleName)
    if not roleName then return "OPEN" end
    return roleName:gsub("Red", ""):gsub("Blue", ""):upper()
end

function WaitingRoom:init()
    self.state = {
        slots = {
            RedSpymaster = nil,
            RedOperative = nil,
            BlueSpymaster = nil,
            BlueOperative = nil
        },
        hostName = ""
    }
end

function WaitingRoom:didMount()
    local RoomService = Knit.GetService("RoomService")
    self.connection = RoomService.RoomUpdate:Connect(function(updatedSlots, hostName)
        self:setState({
            slots = updatedSlots,
            hostName = hostName or ""
        })
    end)
end

function WaitingRoom:willUnmount()
    if self.connection then
        self.connection:Disconnect()
    end
end

function WaitingRoom:RenderSlotButton(role, color)
    local occupantName = self.state.slots[role]
    local isTaken = occupantName ~= nil
    local displayRole = formatRole(role)
    
    local text = displayRole .. "\n" .. (isTaken and occupantName or "[ OPEN ]")
    local transparency = isTaken and 0.5 or 0
    
    return Roact.createElement(AnimatedSlot, {
        Text = text,
        Size = UDim2.fromScale(1, 0.45),
        Color = color,
        Transparency = transparency,
        Disabled = false,
        OnClick = function()
            local team = string.match(role, "Red") and "Red" or "Blue"
            local roleType = string.match(role, "Spymaster") and "Spymaster" or "Operative"
            self.props.OnSelectSlot(team, roleType)
        end
    })
end

function WaitingRoom:render()
    local myName = Players.LocalPlayer.Name
    local amIHost = (myName == self.state.hostName)
    local startBtnColor = amIHost and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(80, 80, 85)
    local startBtnText = amIHost and "INITIATE MISSION" or "WAITING FOR HOST..."

    return Roact.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
    }, {
        MainContainer = Roact.createElement("Frame", {
            Size = UDim2.fromScale(0.5, 0.7),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            Layout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0.05, 0),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder
            }),

            Header = Roact.createElement("Frame", {
                Size = UDim2.fromScale(1, 0.2),
                BackgroundTransparency = 1,
                LayoutOrder = 1
            }, {
                Layout = Roact.createElement("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                Title = Roact.createElement("TextLabel", { Text = "MISSION LOGISTICS", Size = UDim2.fromScale(1, 0.6), Font = Enum.Font.GothamBlack, TextSize = 40, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1 }),
                SubTitle = Roact.createElement("TextLabel", { Text = "ROOM: " .. (self.props.RoomCode or "????") .. "  |  HOST: " .. self.state.hostName, Size = UDim2.fromScale(1, 0.4), Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1 })
            }),

            Dashboard = Roact.createElement("Frame", {
                Size = UDim2.fromScale(1, 0.5),
                BackgroundTransparency = 1,
                LayoutOrder = 2
            }, {
                Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                
                RedTeam = Roact.createElement("Frame", { Size = UDim2.fromScale(0.45, 1), BackgroundTransparency = 1 }, {
                    Layout = Roact.createElement("UIListLayout", { Padding = UDim.new(0.1, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                    Spy = self:RenderSlotButton("RedSpymaster", Color3.fromRGB(231, 76, 60)),
                    Op = self:RenderSlotButton("RedOperative", Color3.fromRGB(231, 76, 60))
                }),

                BlueTeam = Roact.createElement("Frame", { Size = UDim2.fromScale(0.45, 1), BackgroundTransparency = 1 }, {
                    Layout = Roact.createElement("UIListLayout", { Padding = UDim.new(0.1, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                    Spy = self:RenderSlotButton("BlueSpymaster", Color3.fromRGB(52, 152, 219)),
                    Op = self:RenderSlotButton("BlueOperative", Color3.fromRGB(52, 152, 219))
                })
            }),

            Controls = Roact.createElement("Frame", {
                Size = UDim2.fromScale(1, 0.15),
                BackgroundTransparency = 1,
                LayoutOrder = 3
            }, {
                Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                
                AbortBtn = Roact.createElement(AnimatedSlot, {
                    Text = "ABORT",
                    Size = UDim2.fromScale(0.25, 1),
                    Color = Color3.fromRGB(60, 60, 65),
                    Transparency = 0,
                    Disabled = false,
                    OnClick = self.props.OnLeave
                }),

                StartBtn = Roact.createElement(AnimatedSlot, {
                    Text = startBtnText,
                    Size = UDim2.fromScale(0.65, 1),
                    Color = startBtnColor,
                    Transparency = 0,
                    Disabled = not amIHost,
                    OnClick = function() if amIHost then self.props.OnStartGame() end end
                })
            })
        })
    })
end

return WaitingRoom