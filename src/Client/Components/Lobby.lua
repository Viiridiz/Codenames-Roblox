local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Packages.Roact)
local Knit = require(ReplicatedStorage.Packages.Knit)

local AnimatedButton = Roact.Component:extend("AnimatedButton")

function AnimatedButton:init()
    self.scaleRef = Roact.createRef()
    local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

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

function AnimatedButton:render()
    return Roact.createElement("TextButton", {
        Text = self.props.Text,
        Size = self.props.BaseSize,
        BackgroundColor3 = self.props.Color,
        TextColor3 = self.props.TextColor or Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = self.props.TextSize or 22,
        AutoButtonColor = false,
        LayoutOrder = self.props.LayoutOrder,
        ZIndex = self.props.ZIndex or 1,
        
        [Roact.Event.MouseEnter] = self.onHoverEnter,
        [Roact.Event.MouseLeave] = self.onHoverLeave,
        [Roact.Event.Activated] = self.onActivate,
    }, {
        Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.scaleRef, Scale = 1 }),
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) })
    })
end

local Lobby = Roact.Component:extend("Lobby")

function Lobby:init()
    self.scaleRef = Roact.createRef()
    
    self.state = {
        inputText = "",
        errorMessage = nil,
        modalVisible = false,
        selectedDifficulty = "Normal",
        selectedWordPack = "Standard"
    }

    self.openModal = function()
        self:setState({ modalVisible = true })
        task.defer(function()
            local scale = self.scaleRef:getValue()
            if scale then
                scale.Scale = 0
                TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            end
        end)
    end

    self.closeModal = function()
        local scale = self.scaleRef:getValue()
        if scale then
            local t = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Scale = 0 })
            t:Play()
            t.Completed:Connect(function()
                self:setState({ modalVisible = false })
            end)
        else
            self:setState({ modalVisible = false })
        end
    end
end

function Lobby:handleJoin()
    local code = self.state.inputText
    if code == "" then return end
    local RoomService = Knit.GetService("RoomService")

    RoomService:JoinRoom(code):andThen(function(success)
        if success then
            self:setState({ errorMessage = Roact.None })
            if self.props.OnJoin then self.props.OnJoin(code) end
        else
            self:setState({ errorMessage = "INVALID ROOM CODE" })
        end
    end)
end

function Lobby:render()
    local isModalOpen = self.state.modalVisible

    return Roact.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25), 
    }, {
        MainContainer = Roact.createElement("Frame", {
            Size = UDim2.fromScale(0.35, 0.6),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            Layout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0.05, 0),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder
            }),

            Title = Roact.createElement("TextLabel", {
                Text = "CODENAMES",
                Size = UDim2.fromScale(1, 0.2),
                Font = Enum.Font.GothamBlack,
                TextSize = 55,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                LayoutOrder = 1
            }),

            CreateBtn = Roact.createElement(AnimatedButton, {
                Text = "CREATE ROOM",
                BaseSize = UDim2.fromScale(1, 0.15),
                Color = Color3.fromRGB(46, 204, 113),
                LayoutOrder = 2,
                Disabled = isModalOpen,
                OnClick = self.openModal
            }),

            JoinContainer = Roact.createElement("Frame", {
                Size = UDim2.fromScale(1, 0.15),
                BackgroundTransparency = 1,
                LayoutOrder = 3
            }, {
                Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0) }),
                
                CodeInput = Roact.createElement("TextBox", {
                    PlaceholderText = "ROOM CODE",
                    Text = self.state.inputText,
                    Size = UDim2.fromScale(0.65, 1),
                    BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Font = Enum.Font.Gotham,
                    TextSize = 22,
                    [Roact.Change.Text] = function(rbx)
                        local cleanText = string.upper(rbx.Text):sub(1, 4)
                        rbx.Text = cleanText 
                        self:setState({ inputText = cleanText, errorMessage = Roact.None })
                    end
                }, { Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }) }),

                JoinBtn = Roact.createElement(AnimatedButton, {
                    Text = "JOIN",
                    BaseSize = UDim2.fromScale(0.3, 1),
                    Color = Color3.fromRGB(52, 152, 219),
                    Disabled = isModalOpen,
                    OnClick = function() self:handleJoin() end
                })
            }),

            ErrorLabel = self.state.errorMessage and Roact.createElement("TextLabel", {
                Text = self.state.errorMessage,
                Size = UDim2.fromScale(1, 0.05),
                TextColor3 = Color3.fromRGB(231, 76, 60),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                LayoutOrder = 4
            }),

            BottomMenu = Roact.createElement("Frame", {
                Size = UDim2.fromScale(1, 0.15),
                BackgroundTransparency = 1,
                LayoutOrder = 5
            }, {
                Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0) }),
                
                LeaderboardBtn = Roact.createElement(AnimatedButton, {
                    Text = "LEADERBOARD",
                    BaseSize = UDim2.fromScale(0.475, 1),
                    Color = Color3.fromRGB(155, 89, 182),
                    TextSize = 18,
                    Disabled = isModalOpen,
                    OnClick = function() print("Leaderboard Open") end
                }),
                
                ShopBtn = Roact.createElement(AnimatedButton, {
                    Text = "SHOP",
                    BaseSize = UDim2.fromScale(0.475, 1),
                    Color = Color3.fromRGB(241, 196, 15),
                    TextColor = Color3.fromRGB(20, 20, 20),
                    TextSize = 18,
                    Disabled = isModalOpen,
                    OnClick = function() print("Shop Open") end
                })
            })
        }),

        Overlay = isModalOpen and Roact.createElement("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.6,
            Text = "", 
            AutoButtonColor = false,
            Active = true,
            ZIndex = 50, 
            [Roact.Event.Activated] = self.closeModal
        }, {
            ModalBox = Roact.createElement("Frame", {
                Size = UDim2.fromScale(0.35, 0.55),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(30, 30, 35),
                ZIndex = 51,
            }, {
                Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.scaleRef, Scale = 0 }),
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.05, 0) }),
                Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(60, 60, 65), Thickness = 2 }),
                
                Padding = Roact.createElement("UIPadding", { 
                    PaddingTop = UDim.new(0.02, 0), 
                    PaddingBottom = UDim.new(0.05, 0) 
                }),
                
                Layout = Roact.createElement("UIListLayout", { Padding = UDim.new(0.03, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),

                Title = Roact.createElement("TextLabel", { Text = "ROOM SETTINGS", Size = UDim2.fromScale(1, 0.12), Font = Enum.Font.GothamBlack, TextSize = 26, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 1 }),

                DiffLabel = Roact.createElement("TextLabel", { Text = "DIFFICULTY", Size = UDim2.fromScale(1, 0.06), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 2 }),
                DiffButtons = Roact.createElement("Frame", { Size = UDim2.fromScale(0.9, 0.15), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 3 }, {
                    Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                    Easy = Roact.createElement(AnimatedButton, { Text = "EASY", BaseSize = UDim2.fromScale(0.3, 1), TextSize = 16, Color = self.state.selectedDifficulty == "Easy" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedDifficulty = "Easy" }) end }),
                    Normal = Roact.createElement(AnimatedButton, { Text = "NORMAL", BaseSize = UDim2.fromScale(0.3, 1), TextSize = 16, Color = self.state.selectedDifficulty == "Normal" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedDifficulty = "Normal" }) end }),
                    Hard = Roact.createElement(AnimatedButton, { Text = "HARD", BaseSize = UDim2.fromScale(0.3, 1), TextSize = 16, Color = self.state.selectedDifficulty == "Hard" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedDifficulty = "Hard" }) end }),
                }),

                PackLabel = Roact.createElement("TextLabel", { Text = "WORD PACK", Size = UDim2.fromScale(1, 0.06), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 4 }),
                
                PackButtons = Roact.createElement("ScrollingFrame", { 
                    Size = UDim2.fromScale(0.9, 0.15), 
                    BackgroundTransparency = 1, 
                    ZIndex = 52, 
                    LayoutOrder = 5,
                    CanvasSize = UDim2.new(0, 0, 0, 0), 
                    AutomaticCanvasSize = Enum.AutomaticSize.X,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
                }, {
                    Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Left }),
                    Standard = Roact.createElement(AnimatedButton, { Text = "STANDARD", BaseSize = UDim2.new(0, 120, 1, 0), TextSize = 16, Color = self.state.selectedWordPack == "Standard" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedWordPack = "Standard" }) end }),
                    Roblox = Roact.createElement(AnimatedButton, { Text = "ROBLOX", BaseSize = UDim2.new(0, 120, 1, 0), TextSize = 16, Color = self.state.selectedWordPack == "Roblox" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedWordPack = "Roblox" }) end }),
                    Gaming = Roact.createElement(AnimatedButton, { Text = "GAMING", BaseSize = UDim2.new(0, 120, 1, 0), TextSize = 16, Color = self.state.selectedWordPack == "Gaming" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedWordPack = "Gaming" }) end }),
                }),

                ConfirmBtn = Roact.createElement(AnimatedButton, {
                    Text = "CONFIRM & CREATE",
                    BaseSize = UDim2.fromScale(0.9, 0.15),
                    Color = Color3.fromRGB(46, 204, 113),
                    LayoutOrder = 6,
                    ZIndex = 55, 
                    OnClick = function()
                        self.closeModal()
                        if self.props.OnCreate then self.props.OnCreate(self.state.selectedDifficulty, self.state.selectedWordPack) end
                    end
                })
            })
        })
    })
end

return Lobby