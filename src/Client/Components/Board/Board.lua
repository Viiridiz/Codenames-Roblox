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
		score = 0,
		currentClue = nil,
		winner = nil, 
	}
	self.isActive = true
end

function Board:didMount()
	local BoardService = Knit.GetService("BoardService")
	local GameService = Knit.GetService("GameService")

	local function updateBoard()
		if not self.isActive then return end
		BoardService:GetBoard():andThen(function(serverBoard)
			if not self.isActive then return end
			self:setState({ cards = serverBoard })
		end)
	end

	-- 1. Initial Load
	updateBoard()

	-- 2. SYNC LOOP
	task.spawn(function()
		while self.isActive do
			if GameService.GetState then
				GameService:GetState():andThen(function(state)
					if not self.isActive then return end
					
					self.setTimeText("TIME: " .. tostring(state.Time))

					self:setState({
						currentTurn = state.Turn,
						score = state.Score,
						currentClue = state.Clue,
						winner = state.Winner
					})
				end):catch(function() end)
			end
			task.wait(1)
		end
	end)

	-- 3. LISTENERS
	if BoardService.CardRevealed then
		self.revealConn = BoardService.CardRevealed:Connect(function(cardId, newColor)
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
	end

	if GameService.GameOver then
		self.gameOverConn = GameService.GameOver:Connect(function(winner)
			self:setState({ winner = winner })
		end)
	end
end

function Board:willUnmount()
	self.isActive = false
	if self.revealConn then self.revealConn:Disconnect() end
	if self.gameOverConn then self.gameOverConn:Disconnect() end
end

local function PlayerIcon(props)
	local color = props.Team == "Red" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 160, 255)
	local isMe = (props.FullRoleName == props.MyRole)
	local isTurn = (props.FullRoleName == props.CurrentTurn)

	local bgTransparency = isMe and 0 or 0.8 
	local strokeColor = isTurn and Color3.new(1,1,1) or (isMe and Color3.new(1,1,1) or color)
	local strokeTransparency = (isMe or isTurn) and 0 or 0.6
	local strokeThickness = isTurn and 4 or 2

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(0.8, 0.45),
		BackgroundColor3 = color,
		BackgroundTransparency = bgTransparency,
		BorderSizePixel = 0,
	}, {
		Stroke = Roact.createElement("UIStroke", {
			Color = strokeColor,
			Thickness = strokeThickness,
			Transparency = strokeTransparency,
		}),
		Label = Roact.createElement("TextLabel", {
			Text = props.RoleLabel,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = (isMe or isTurn) and Color3.new(1,1,1) or color,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
		}),
		Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) })
	})
end

function Board:render()
	local children = {}
	local myRole = self.props.MyRole or "None"
	local currentTurn = self.state.currentTurn
	local isSpymaster = string.find(myRole, "Spymaster") ~= nil
	local isMyTurn = (myRole == currentTurn) and (self.state.winner == nil)

	children.Layout = Roact.createElement("UIGridLayout", {
		-- [[ FIX: Spacing Overhaul ]]
		-- Decreased CellSize to 0.18 to allow for gaps
		CellSize = UDim2.new(0.18, 0, 0.18, 0),
		-- Increased Padding to 0.02 for separation
		CellPadding = UDim2.new(0.02, 0, 0.02, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	for _, cardData in ipairs(self.state.cards) do
		local canClick = (isMyTurn and not isSpymaster)

		children["Card_" .. cardData.Id] = Roact.createElement(Card, {
			Id = cardData.Id,
			Word = cardData.Word,
			Color = cardData.Color,
			IsRevealed = cardData.IsRevealed,
			IsSpymaster = isSpymaster,
			OnClick = canClick and self.props.OnCardClick or nil
		})
	end

	local clueText = "WAITING FOR CLUE..."
	if self.state.currentClue and self.state.currentClue.Word ~= "" then
		clueText = string.format("CLUE: %s (%d)", self.state.currentClue.Word, self.state.currentClue.Number)
	end

	local gameOverElement = nil
	if self.state.winner then
		local winColor = self.state.winner == "Red" and Color3.fromRGB(235, 87, 87) or Color3.fromRGB(47, 128, 237)
		gameOverElement = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0,0,0),
			BackgroundTransparency = 0.3,
			ZIndex = 100,
		}, {
			Container = Roact.createElement("Frame", {
				Size = UDim2.fromScale(0.5, 0.3),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderSizePixel = 0,
				ZIndex = 101,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.1, 0) }),
				Label = Roact.createElement("TextLabel", {
					Text = self.state.winner .. " WINS!",
					Size = UDim2.fromScale(1, 0.6),
					BackgroundTransparency = 1,
					TextColor3 = winColor,
					Font = Enum.Font.GothamBlack,
					TextSize = 40,
					ZIndex = 102,
				}),
				Restart = Roact.createElement("TextButton", {
					Text = "RETURN TO LOBBY",
					Size = UDim2.fromScale(0.6, 0.25),
					Position = UDim2.fromScale(0.5, 0.7),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.fromRGB(80, 80, 80),
					TextColor3 = Color3.new(1,1,1),
					Font = Enum.Font.GothamBold,
					TextSize = 18,
					ZIndex = 102,
					[Roact.Event.Activated] = self.props.OnExit
				}, {
					Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.3, 0) })
				})
			})
		})
	end

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BorderSizePixel = 0,
	}, {
		TopBar = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 0.08),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,
		}, {
			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.05, 0)
			}),
			TurnDisp = Roact.createElement("TextLabel", {
				Text = formatRole(currentTurn),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromScale(0, 0.8),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 200, 80),
				Font = Enum.Font.GothamBlack,
				TextSize = 20,
			}),
			TimeDisp = Roact.createElement("TextLabel", {
				Text = self.timeText, 
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromScale(0, 0.8),
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.GothamBold,
				TextSize = 18,
			}),
			ScoreDisp = Roact.createElement("TextLabel", {
				Text = "SCORE: " .. self.state.score,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromScale(0, 0.8),
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.GothamBold,
				TextSize = 18,
			}),
		}),

		ClueBanner = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.4, 0.05),
			Position = UDim2.fromScale(0.5, 0.1),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Label = Roact.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = clueText,
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.GothamBlack,
				TextSize = 16,
			})
		}),

		LeftPanel = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.1, 0.65),
			Position = UDim2.fromScale(0.05, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			List = Roact.createElement("UIListLayout", { Padding = UDim.new(0.05, 0), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
			P1 = Roact.createElement(PlayerIcon, { Team = "Red", RoleLabel = "SPY", FullRoleName = "RedSpymaster", MyRole = myRole, CurrentTurn = currentTurn }),
			P2 = Roact.createElement(PlayerIcon, { Team = "Red", RoleLabel = "OP", FullRoleName = "RedOperative", MyRole = myRole, CurrentTurn = currentTurn }),
		}),

		GameBoard = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.6, 0.55),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45), 
			BackgroundTransparency = 1,
			ZIndex = 5,
		}, children),

		RightPanel = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.1, 0.65),
			Position = UDim2.fromScale(0.95, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
		}, {
			List = Roact.createElement("UIListLayout", { Padding = UDim.new(0.05, 0), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
			P3 = Roact.createElement(PlayerIcon, { Team = "Blue", RoleLabel = "SPY", FullRoleName = "BlueSpymaster", MyRole = myRole, CurrentTurn = currentTurn }),
			P4 = Roact.createElement(PlayerIcon, { Team = "Blue", RoleLabel = "OP", FullRoleName = "BlueOperative", MyRole = myRole, CurrentTurn = currentTurn }),
		}),

		ClueHUD = Roact.createElement(ClueInput, {
			IsVisible = (isMyTurn and isSpymaster),
			OnSubmit = self.props.OnGiveClue 
		}),

		MenuButton = Roact.createElement("TextButton", {
			Text = "⚙️",
			Size = UDim2.fromScale(0.04, 0.06),
			Position = UDim2.fromScale(0.98, 0.02), 
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			TextColor3 = Color3.new(1,1,1),
			Font = Enum.Font.GothamBold,
			TextSize = 18,
			AutoButtonColor = false,
			[Roact.Event.Activated] = function()
				if self.props.OnExit then self.props.OnExit() end
			end
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) })
		}),

		GameOverModal = gameOverElement,
	})
end

return Board