local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Card = require(script.Parent.Card)
local ClueInput = require(script.Parent.ClueInput)

local Board = Roact.Component:extend("Board")

local function formatRole(roleStr)
    if not roleStr then return "..." end
    roleStr = roleStr:gsub("Spymaster", " SPY"):gsub("Operative", " OP")
    return roleStr:upper()
end

function Board:init()
    self.timeText, self.setTimeText = Roact.createBinding("TIME: --")

    self.state = {
        cards = {},
        currentTurn = "Waiting...",
        score = "0 - 0",
        currentClue = nil,
        winner = nil, 
        errorMessage = nil, 
    }
    self.isActive = true
end

function Board:didMount()
    local GameService = Knit.GetService("GameService")

    GameService:RequestSecretBoard()

    self.errorConn = GameService.ErrorMessage:Connect(function(msg)
        self:setState({ errorMessage = msg })
        task.delay(3, function()
            if self.isActive then
                self:setState({ errorMessage = Roact.None })
            end
        end)
    end)

    self.turnConn = GameService.TurnChanged:Connect(function(turnString)
        self:setState({ currentTurn = turnString })
    end)

    self.scoreConn = GameService.ScoreUpdate:Connect(function(scoreRed, scoreBlue)
        self:setState({ score = tostring(scoreRed) .. " - " .. tostring(scoreBlue) })
    end)

    self.timerConn = GameService.TimerUpdate:Connect(function(timeRemaining)
        self.setTimeText("TIME: " .. tostring(timeRemaining))
    end)

    self.clueConn = GameService.ClueGiven:Connect(function(word, number)
        self:setState({ currentClue = {Word = word, Number = number} })
    end)

    self.revealConn = GameService.CardColorDisplayed:Connect(function(cardId, newColor)
        self:setState(function(prevState)
            local newCards = table.clone(prevState.cards)
            for i, card in ipairs(newCards) do
                if card.Id == cardId then
                    local updated = table.clone(card)
                    updated.IsRevealed = true
                    updated.Color = newColor 
                    newCards[i] = updated
                    break
                end
            end
            return { cards = newCards }
        end)
    end)

    self.gameOverConn = GameService.GameOver:Connect(function(winner)
        self:setState({ winner = winner })
    end)
    
    self.secretConn = GameService.SecretBoardData:Connect(function(data)
        self:setState({ cards = data })
    end)
end

function Board:willUnmount()
    self.isActive = false
    if self.errorConn then self.errorConn:Disconnect() end
    if self.turnConn then self.turnConn:Disconnect() end
    if self.scoreConn then self.scoreConn:Disconnect() end
    if self.timerConn then self.timerConn:Disconnect() end
    if self.clueConn then self.clueConn:Disconnect() end
    if self.revealConn then self.revealConn:Disconnect() end
    if self.gameOverConn then self.gameOverConn:Disconnect() end
    if self.secretConn then self.secretConn:Disconnect() end
end

function Board:render()
    local children = {}
    local myRole = self.props.MyRole or "None"
    local myTeam = self.props.MyTeam or "None"
    local currentTurn = self.state.currentTurn
    local isSpymaster = (myRole == "Spymaster")
    
    local myFullRoleString = myTeam .. myRole 
    local isMyTurn = (myFullRoleString == currentTurn) and (self.state.winner == nil)

    local turnTextColor = Color3.new(1,1,1)
    if string.find(currentTurn, "Red") then 
        turnTextColor = Color3.fromRGB(255, 80, 80)
    elseif string.find(currentTurn, "Blue") then 
        turnTextColor = Color3.fromRGB(80, 160, 255) 
    end

    children.Layout = Roact.createElement("UIGridLayout", {
        CellSize = UDim2.new(0.18, 0, 0.18, 0),
        CellPadding = UDim2.new(0.02, 0, 0.02, 0),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    for _, cardData in ipairs(self.state.cards) do
        children["Card_" .. cardData.Id] = Roact.createElement(Card, {
            Id = cardData.Id,
            Word = cardData.Word,
            Color = cardData.Color,
            IsRevealed = cardData.IsRevealed,
            IsSpymaster = isSpymaster,
            OnClick = self.props.OnCardClick 
        })
    end

    local clueText = self.state.currentClue and string.format("CLUE: %s (%d)", self.state.currentClue.Word, self.state.currentClue.Number) or "WAITING FOR CLUE..."

    return Roact.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0,
    }, {
        TopBar = Roact.createElement("Frame", {
            Size = UDim2.fromScale(1, 0.08),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        }, {
            Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.05, 0) }),
            ScoreDisp = Roact.createElement("TextLabel", { Text = "SCORE: " .. self.state.score, Size = UDim2.fromScale(0, 0.8), AutomaticSize = Enum.AutomaticSize.X, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 18, BackgroundTransparency = 1 }),
            TurnDisp = Roact.createElement("TextLabel", { Text = formatRole(currentTurn) .. " TURN", Size = UDim2.fromScale(0, 0.8), AutomaticSize = Enum.AutomaticSize.X, TextColor3 = turnTextColor, Font = Enum.Font.GothamBlack, TextSize = 20, BackgroundTransparency = 1 }),
            TimeDisp = Roact.createElement("TextLabel", { Text = self.timeText, Size = UDim2.fromScale(0, 0.8), AutomaticSize = Enum.AutomaticSize.X, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 18, BackgroundTransparency = 1 }),
        }),

        ClueBanner = Roact.createElement("Frame", {
            Size = UDim2.fromScale(0.4, 0.05),
            Position = UDim2.fromScale(0.5, 0.12),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
            Label = Roact.createElement("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = clueText, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBlack, TextSize = 16 }),
        }),

        GameBoard = Roact.createElement("Frame", {
            Size = UDim2.fromScale(0.6, 0.55),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), 
            BackgroundTransparency = 1,
        }, children),

        ErrorToast = self.state.errorMessage and Roact.createElement("TextLabel", {
            Text = self.state.errorMessage,
            Size = UDim2.fromScale(0.35, 0.05),
            Position = UDim2.fromScale(0.5, 0.83),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(220, 50, 50),
            TextColor3 = Color3.new(1,1,1),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            ZIndex = 50,
        }, {
            Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.3, 0) })
        }),

        ClueHUD = Roact.createElement(ClueInput, {
            IsVisible = (isMyTurn and isSpymaster),
            OnSubmit = self.props.OnGiveClue 
        }),
    })
end

return Board