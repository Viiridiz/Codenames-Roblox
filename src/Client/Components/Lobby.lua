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
        if scale then TweenService:Create(scale, TWEEN_INFO, { Scale = 1.05 }):Play() end
    end

    self.onHoverLeave = function()
        if self.props.Disabled then return end
        local scale = self.scaleRef:getValue()
        if scale then TweenService:Create(scale, TWEEN_INFO, { Scale = 1 }):Play() end
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
        if self.props.OnClick then 
            -- Safely play sound if controller exists
            pcall(function()
                Knit.GetController("SoundController"):Play("Click")
            end)
            self.props.OnClick() 
        end
    end
end

function AnimatedButton:render()
    return Roact.createElement("TextButton", {
        Text = self.props.Text, Size = self.props.BaseSize, Position = self.props.Position, AnchorPoint = self.props.AnchorPoint,
        BackgroundColor3 = self.props.Color, TextColor3 = self.props.TextColor or Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold, TextSize = self.props.TextSize or 22, AutoButtonColor = false,
        LayoutOrder = self.props.LayoutOrder, ZIndex = self.props.ZIndex or 1,
        [Roact.Event.MouseEnter] = self.onHoverEnter, [Roact.Event.MouseLeave] = self.onHoverLeave, [Roact.Event.Activated] = self.onActivate,
    }, {
        Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.scaleRef, Scale = 1 }),
        Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) })
    })
end

local Lobby = Roact.Component:extend("Lobby")

function Lobby:init()
    self.createScaleRef = Roact.createRef()
    self.browseScaleRef = Roact.createRef()
    self.shopScaleRef = Roact.createRef()
    self.leaderboardScaleRef = Roact.createRef()
    
    self.state = {
        inputText = "", errorMessage = nil,
        createModalVisible = false, browseModalVisible = false, shopModalVisible = false, leaderboardModalVisible = false,
        selectedDifficulty = "Normal", selectedWordPack = "Standard", isPublic = false,
        publicRooms = {}, leaderboardData = {}, coins = 0, wins = 0, streak = 0
    }

    self.openModal = function(modalName, ref)
        self:setState({ [modalName] = true })
        task.defer(function()
            local scale = ref:getValue()
            if scale then
                scale.Scale = 0
                TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            end
        end)
    end

    self.closeModal = function(modalName, ref)
        local scale = ref:getValue()
        if scale then
            local t = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Scale = 0 })
            t:Play()
            t.Completed:Connect(function() self:setState({ [modalName] = false }) end)
        else
            self:setState({ [modalName] = false })
        end
    end

    -- FIXED: Added 'itemName' to arguments
    self.buyItem = function(itemName, cost)
        Knit.GetService("DataService"):BuyItem(itemName, cost):andThen(function(success, newBal)
            if success then
                self:setState({ coins = newBal, errorMessage = "PURCHASE SUCCESSFUL!" })
            else
                self:setState({ errorMessage = "NOT ENOUGH COINS" })
            end
            task.delay(2, function() self:setState({ errorMessage = Roact.None }) end)
        end)
    end
end

function Lobby:didMount()
    local DataService = Knit.GetService("DataService")
    
    DataService:GetMyData():andThen(function(data)
        if data then
            self:setState({ coins = data.Coins or 0, wins = data.Wins or 0, streak = data.Streak or 0 })
        end
    end):catch(function(err)
        warn("Lobby: Error fetching data:", tostring(err))
    end)

    pcall(function()
        local LBService = Knit.GetService("LeaderboardService")
        self.lbConn = LBService.LeaderboardUpdated:Connect(function(data)
            self:setState({ leaderboardData = data or {} })
        end)
        LBService:GetTop10():andThen(function(data)
            if data then self:setState({ leaderboardData = data }) end
        end)
    end)
end

function Lobby:willUnmount()
    if self.lbConn then self.lbConn:Disconnect() end
end

function Lobby:handleJoin()
    local code = self.state.inputText
    if code == "" then return end
    if self.props.OnJoin then self.props.OnJoin(code) end
end

function Lobby:render()
    print("UI IS RENDERING!")
    local isAnyModalOpen = self.state.createModalVisible or self.state.browseModalVisible or self.state.shopModalVisible or self.state.leaderboardModalVisible
    
    local roomElements = { Layout = Roact.createElement("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center }) }
    if #self.state.publicRooms == 0 then
        roomElements.NoRooms = Roact.createElement("TextLabel", { Text = "NO PUBLIC MISSIONS AVAILABLE", Size = UDim2.fromScale(1, 0.2), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 18 })
    else
        for i, r in ipairs(self.state.publicRooms) do
            roomElements["Room" .. i] = Roact.createElement("Frame", { Size = UDim2.new(0.95, 0, 0, 50), BackgroundColor3 = Color3.fromRGB(40, 40, 45) }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }),
                Info = Roact.createElement("TextLabel", { Text = "HOST: " .. r.HostName .. "  |  " .. r.Difficulty:upper() .. "  |  " .. tostring(r.PlayerCount) .. "/4", Size = UDim2.fromScale(0.7, 1), Position = UDim2.fromScale(0.05, 0), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 60 }),
                JoinBtn = Roact.createElement(AnimatedButton, { Text = "JOIN", BaseSize = UDim2.fromScale(0.2, 0.7), Position = UDim2.fromScale(0.95, 0.5), AnchorPoint = Vector2.new(1, 0.5), Color = Color3.fromRGB(46, 204, 113), TextSize = 14, ZIndex = 60, OnClick = function() self.props.OnJoin(r.Code) end })
            })
        end
    end

    local shopItems = {
        {Name = "NEON TAG", Price = 100, Color = Color3.fromRGB(155, 89, 182)},
        {Name = "GOLD TAG", Price = 250, Color = Color3.fromRGB(241, 196, 15)},
        {Name = "RUBY TAG", Price = 500, Color = Color3.fromRGB(231, 76, 60)},
        {Name = "DIAMOND TAG", Price = 1000, Color = Color3.fromRGB(52, 152, 219)}
    }
    local shopElements = { Layout = Roact.createElement("UIGridLayout", { CellSize = UDim2.new(0.45, 0, 0.4, 0), CellPadding = UDim2.new(0.05, 0, 0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }) }
    for i, item in ipairs(shopItems) do
        shopElements["Item"..i] = Roact.createElement("Frame", { BackgroundColor3 = Color3.fromRGB(40, 40, 45) }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.1, 0) }),
            Title = Roact.createElement("TextLabel", { Text = item.Name, Size = UDim2.fromScale(1, 0.4), Position = UDim2.fromScale(0, 0.1), BackgroundTransparency = 1, TextColor3 = item.Color, Font = Enum.Font.GothamBlack, TextSize = 18, ZIndex = 52 }),
            BuyBtn = Roact.createElement(AnimatedButton, { Text = "💰 " .. item.Price, BaseSize = UDim2.fromScale(0.8, 0.3), Position = UDim2.fromScale(0.5, 0.8), AnchorPoint = Vector2.new(0.5, 0.5), Color = Color3.fromRGB(46, 204, 113), TextSize = 16, ZIndex = 55, OnClick = function() self.buyItem(item.Name, item.Price) end })
        })
    end

    local lbElements = { Layout = Roact.createElement("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }) }
    local lbData = self.state.leaderboardData or {} 
    
    if #lbData == 0 then
        lbElements.NoData = Roact.createElement("TextLabel", { Text = "FETCHING RANKINGS...", Size = UDim2.fromScale(1, 0.2), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 18 })
    else
        for i, d in ipairs(lbData) do
            local tColor = Color3.fromRGB(200, 200, 200)
            if i == 1 then tColor = Color3.fromRGB(241, 196, 15)
            elseif i == 2 then tColor = Color3.fromRGB(189, 195, 199)
            elseif i == 3 then tColor = Color3.fromRGB(205, 127, 50) end

            lbElements["R"..i] = Roact.createElement("Frame", { Size = UDim2.new(0.95, 0, 0, 45), BackgroundColor3 = Color3.fromRGB(40, 40, 45) }, {
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }),
                Rank = Roact.createElement("TextLabel", { Text = "#" .. (d.Rank or i), Size = UDim2.fromScale(0.15, 1), Position = UDim2.fromScale(0.05, 0), BackgroundTransparency = 1, TextColor3 = tColor, Font = Enum.Font.GothamBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52 }),
                Name = Roact.createElement("TextLabel", { Text = d.Name or "Unknown", Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.2, 0), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52 }),
                Wins = Roact.createElement("TextLabel", { Text = "🏆 " .. (d.Wins or 0), Size = UDim2.fromScale(0.25, 1), Position = UDim2.fromScale(0.7, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(52, 152, 219), Font = Enum.Font.GothamBlack, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 52 })
            })
        end
    end

    return Roact.createElement("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 20, 25) }, {
        TopHUD = Roact.createElement("Frame", { 
            Size = UDim2.fromScale(0.5, 0.05), Position = UDim2.fromScale(0.5, 0.02), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1 
        }, {
            Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
            Coins = Roact.createElement("TextLabel", { Text = "💰 " .. self.state.coins, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.fromRGB(241, 196, 15), BackgroundTransparency = 1 }),
            Wins = Roact.createElement("TextLabel", { Text = "🏆 " .. self.state.wins, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.fromRGB(52, 152, 219), BackgroundTransparency = 1 }),
            Streak = self.state.streak > 0 and Roact.createElement("TextLabel", { Text = "🔥 " .. self.state.streak, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.fromRGB(231, 76, 60), BackgroundTransparency = 1 })
        }),

        MainContainer = Roact.createElement("Frame", { Size = UDim2.fromScale(0.35, 0.6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }, {
            Layout = Roact.createElement("UIListLayout", { Padding = UDim.new(0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
            Title = Roact.createElement("TextLabel", { Text = "CODENAMES", Size = UDim2.fromScale(1, 0.2), Font = Enum.Font.GothamBlack, TextSize = 55, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, LayoutOrder = 1 }),
            CreateBtn = Roact.createElement(AnimatedButton, { Text = "CREATE ROOM", BaseSize = UDim2.fromScale(1, 0.15), Color = Color3.fromRGB(46, 204, 113), LayoutOrder = 2, Disabled = isAnyModalOpen, OnClick = function() self.openModal("createModalVisible", self.createScaleRef) end }),
            JoinContainer = Roact.createElement("Frame", { Size = UDim2.fromScale(1, 0.15), BackgroundTransparency = 1, LayoutOrder = 3 }, {
                Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.03, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
                CodeInput = Roact.createElement("TextBox", { PlaceholderText = "CODE", Text = self.state.inputText, Size = UDim2.fromScale(0.4, 1), BackgroundColor3 = Color3.fromRGB(35, 35, 40), TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Gotham, TextSize = 22, [Roact.Change.Text] = function(rbx) local cleanText = string.upper(rbx.Text):sub(1, 4); rbx.Text = cleanText; self:setState({ inputText = cleanText, errorMessage = Roact.None }) end }, { Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }) }),
                JoinBtn = Roact.createElement(AnimatedButton, { Text = "JOIN", BaseSize = UDim2.fromScale(0.25, 1), Color = Color3.fromRGB(52, 152, 219), Disabled = isAnyModalOpen, OnClick = function() self:handleJoin() end }),
                BrowseBtn = Roact.createElement(AnimatedButton, { Text = "BROWSE", BaseSize = UDim2.fromScale(0.29, 1), Color = Color3.fromRGB(155, 89, 182), Disabled = isAnyModalOpen, OnClick = function() Knit.GetService("RoomService"):GetPublicRooms():andThen(function(r) self:setState({ publicRooms = r }) end); self.openModal("browseModalVisible", self.browseScaleRef) end })
            }),
            ErrorLabel = self.state.errorMessage and Roact.createElement("TextLabel", { Text = self.state.errorMessage, Size = UDim2.fromScale(1, 0.05), TextColor3 = Color3.fromRGB(231, 76, 60), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, LayoutOrder = 4 }),
            BottomMenu = Roact.createElement("Frame", { Size = UDim2.fromScale(1, 0.15), BackgroundTransparency = 1, LayoutOrder = 5 }, {
                Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0) }),
                LeaderboardBtn = Roact.createElement(AnimatedButton, { Text = "LEADERBOARD", BaseSize = UDim2.fromScale(0.475, 1), Color = Color3.fromRGB(100, 100, 105), TextSize = 18, Disabled = isAnyModalOpen, OnClick = function() self.openModal("leaderboardModalVisible", self.leaderboardScaleRef) end }),
                ShopBtn = Roact.createElement(AnimatedButton, { Text = "SHOP", BaseSize = UDim2.fromScale(0.475, 1), Color = Color3.fromRGB(241, 196, 15), TextColor = Color3.fromRGB(20, 20, 20), TextSize = 18, Disabled = isAnyModalOpen, OnClick = function() self.openModal("shopModalVisible", self.shopScaleRef) end })
            })
        }),

        CreateOverlay = self.state.createModalVisible and Roact.createElement("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.6, Text = "", AutoButtonColor = false, Active = true, ZIndex = 50, [Roact.Event.Activated] = function() self.closeModal("createModalVisible", self.createScaleRef) end }, {
            ModalBox = Roact.createElement("Frame", { Size = UDim2.fromScale(0.35, 0.65), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 30, 35), ZIndex = 51 }, {
                Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.createScaleRef, Scale = 0 }),
                Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.05, 0) }), Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(60, 60, 65), Thickness = 2 }), Padding = Roact.createElement("UIPadding", { PaddingTop = UDim.new(0.02, 0), PaddingBottom = UDim.new(0.05, 0) }),
                Layout = Roact.createElement("UIListLayout", { Padding = UDim.new(0.03, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
                Title = Roact.createElement("TextLabel", { Text = "ROOM SETTINGS", Size = UDim2.fromScale(1, 0.1), Font = Enum.Font.GothamBlack, TextSize = 26, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 1 }),
                DiffLabel = Roact.createElement("TextLabel", { Text = "DIFFICULTY", Size = UDim2.fromScale(1, 0.05), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 2 }),
                DiffButtons = Roact.createElement("Frame", { Size = UDim2.fromScale(0.9, 0.12), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 3 }, { Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }), Easy = Roact.createElement(AnimatedButton, { Text = "EASY", BaseSize = UDim2.fromScale(0.3, 1), TextSize = 16, Color = self.state.selectedDifficulty == "Easy" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedDifficulty = "Easy" }) end }), Normal = Roact.createElement(AnimatedButton, { Text = "NORMAL", BaseSize = UDim2.fromScale(0.3, 1), TextSize = 16, Color = self.state.selectedDifficulty == "Normal" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedDifficulty = "Normal" }) end }), Hard = Roact.createElement(AnimatedButton, { Text = "HARD", BaseSize = UDim2.fromScale(0.3, 1), TextSize = 16, Color = self.state.selectedDifficulty == "Hard" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedDifficulty = "Hard" }) end }) }),
                PackLabel = Roact.createElement("TextLabel", { Text = "WORD PACK", Size = UDim2.fromScale(1, 0.05), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 4 }),
                
                PackButtons = Roact.createElement("ScrollingFrame", { Size = UDim2.fromScale(0.9, 0.12), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 5, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150) }, { 
                    Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Left }), 
                    Standard = Roact.createElement(AnimatedButton, { Text = "STANDARD", BaseSize = UDim2.new(0, 120, 1, 0), TextSize = 16, Color = self.state.selectedWordPack == "Standard" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedWordPack = "Standard" }) end }), 
                    Gaming = Roact.createElement(AnimatedButton, { Text = "GAMING", BaseSize = UDim2.new(0, 120, 1, 0), TextSize = 16, Color = self.state.selectedWordPack == "Gaming" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedWordPack = "Gaming" }) end }),
                    Food = Roact.createElement(AnimatedButton, { Text = "FOOD", BaseSize = UDim2.new(0, 120, 1, 0), TextSize = 16, Color = self.state.selectedWordPack == "Food" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedWordPack = "Food" }) end }),
                    Movies = Roact.createElement(AnimatedButton, { Text = "MOVIES", BaseSize = UDim2.new(0, 120, 1, 0), TextSize = 16, Color = self.state.selectedWordPack == "Movies" and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ selectedWordPack = "Movies" }) end })
                    }),
                    
                PrivacyLabel = Roact.createElement("TextLabel", { Text = "PRIVACY", Size = UDim2.fromScale(1, 0.05), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 6 }),
                PrivacyButtons = Roact.createElement("Frame", { Size = UDim2.fromScale(0.9, 0.12), BackgroundTransparency = 1, ZIndex = 52, LayoutOrder = 7 }, { Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }), Private = Roact.createElement(AnimatedButton, { Text = "PRIVATE", BaseSize = UDim2.fromScale(0.4, 1), TextSize = 16, Color = not self.state.isPublic and Color3.fromRGB(155, 89, 182) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ isPublic = false }) end }), Public = Roact.createElement(AnimatedButton, { Text = "PUBLIC", BaseSize = UDim2.fromScale(0.4, 1), TextSize = 16, Color = self.state.isPublic and Color3.fromRGB(155, 89, 182) or Color3.fromRGB(50, 50, 55), ZIndex = 55, OnClick = function() self:setState({ isPublic = true }) end }) }),
                ConfirmBtn = Roact.createElement(AnimatedButton, { Text = "CONFIRM & CREATE", BaseSize = UDim2.fromScale(0.9, 0.15), Color = Color3.fromRGB(46, 204, 113), LayoutOrder = 8, ZIndex = 55, OnClick = function() self.closeModal("createModalVisible", self.createScaleRef); if self.props.OnCreate then self.props.OnCreate(self.state.selectedDifficulty, self.state.selectedWordPack, self.state.isPublic) end end })
            })
        }),

        BrowseOverlay = self.state.browseModalVisible and Roact.createElement("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.6, Text = "", AutoButtonColor = false, Active = true, ZIndex = 50, [Roact.Event.Activated] = function() self.closeModal("browseModalVisible", self.browseScaleRef) end }, {
            ModalBox = Roact.createElement("Frame", { Size = UDim2.fromScale(0.4, 0.6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 30, 35), ZIndex = 51 }, {
                Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.browseScaleRef, Scale = 0 }), Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.05, 0) }), Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(60, 60, 65), Thickness = 2 }), Padding = Roact.createElement("UIPadding", { PaddingTop = UDim.new(0.05, 0), PaddingBottom = UDim.new(0.05, 0), PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0) }),
                Title = Roact.createElement("TextLabel", { Text = "PUBLIC MISSIONS", Size = UDim2.fromScale(1, 0.15), Position = UDim2.fromScale(0, 0), Font = Enum.Font.GothamBlack, TextSize = 26, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, ZIndex = 52 }),
                RoomList = Roact.createElement("ScrollingFrame", { Size = UDim2.fromScale(1, 0.85), Position = UDim2.fromScale(0, 0.15), BackgroundTransparency = 1, ZIndex = 52, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150) }, roomElements)
            })
        }),

        ShopOverlay = self.state.shopModalVisible and Roact.createElement("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.6, Text = "", AutoButtonColor = false, Active = true, ZIndex = 50, [Roact.Event.Activated] = function() self.closeModal("shopModalVisible", self.shopScaleRef) end }, {
            ModalBox = Roact.createElement("Frame", { Size = UDim2.fromScale(0.5, 0.6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 30, 35), ZIndex = 51 }, {
                Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.shopScaleRef, Scale = 0 }), Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.05, 0) }), Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(241, 196, 15), Thickness = 2 }), Padding = Roact.createElement("UIPadding", { PaddingTop = UDim.new(0.05, 0), PaddingBottom = UDim.new(0.05, 0), PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0) }),
                Title = Roact.createElement("TextLabel", { Text = "COSMETIC SHOP", Size = UDim2.fromScale(1, 0.15), Position = UDim2.fromScale(0, 0), Font = Enum.Font.GothamBlack, TextSize = 30, TextColor3 = Color3.fromRGB(241, 196, 15), BackgroundTransparency = 1, ZIndex = 52 }),
                ItemsGrid = Roact.createElement("Frame", { Size = UDim2.fromScale(1, 0.85), Position = UDim2.fromScale(0, 0.15), BackgroundTransparency = 1, ZIndex = 52 }, shopElements)
            })
        }),

        LeaderboardOverlay = self.state.leaderboardModalVisible and Roact.createElement("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.6, Text = "", AutoButtonColor = false, Active = true, ZIndex = 50, [Roact.Event.Activated] = function() self.closeModal("leaderboardModalVisible", self.leaderboardScaleRef) end }, {
            ModalBox = Roact.createElement("Frame", { Size = UDim2.fromScale(0.4, 0.7), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 30, 35), ZIndex = 51 }, {
                Scale = Roact.createElement("UIScale", { [Roact.Ref] = self.leaderboardScaleRef, Scale = 0 }), Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.05, 0) }), Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(155, 89, 182), Thickness = 2 }), Padding = Roact.createElement("UIPadding", { PaddingTop = UDim.new(0.05, 0), PaddingBottom = UDim.new(0.05, 0), PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0) }),
                Title = Roact.createElement("TextLabel", { Text = "GLOBAL TOP 10", Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, 0), Font = Enum.Font.GothamBlack, TextSize = 26, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, ZIndex = 52 }),
                ListFrame = Roact.createElement("ScrollingFrame", { Size = UDim2.fromScale(1, 0.88), Position = UDim2.fromScale(0, 0.12), BackgroundTransparency = 1, ZIndex = 52, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150) }, lbElements)
            })
        })
    })
end

return Lobby