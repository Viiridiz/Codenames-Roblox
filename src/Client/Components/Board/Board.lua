local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Card = require(script.Parent.Card)

local Board = Roact.Component:extend("Board")

function Board:init()
	self.state = {
		cards = {}
	}
end

function Board:didMount()
	local BoardService = Knit.GetService("BoardService")
	
	BoardService:GetBoard():andThen(function(serverBoard)
		self:setState({
			cards = serverBoard
		})
		print("BOARD LOADED. MY ROLE:", self.props.MyRole)
	end):catch(warn)
end

local function PlayerIcon(props)
	local color = props.Team == "Red" and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(40, 90, 180)
	
	-- CHECK IF ICON REPRESENT ME
	local isMe = (props.FullRoleName == props.MyRole)
	
	-- STYLE LOGIC
	local bgTransparency = isMe and 0 or 0.8 
	local strokeColor = isMe and Color3.new(1,1,1) or color
	local strokeTransparency = isMe and 0 or 0.5
	local textColor = isMe and Color3.new(1,1,1) or color

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(0.8, 0.45),
		BackgroundColor3 = color,
		BackgroundTransparency = bgTransparency,
		BorderSizePixel = 0,
	}, {
		Stroke = Roact.createElement("UIStroke", {
			Color = strokeColor,
			Thickness = 2,
			Transparency = strokeTransparency,
		}),
		Label = Roact.createElement("TextLabel", {
			Text = props.RoleLabel,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = textColor,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
		}),
		Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) })
	})
end

function Board:render()
	local children = {}
	local myRole = self.props.MyRole or "None"
	local showRealColors = string.find(myRole, "Spymaster") ~= nil
	
	children.Layout = Roact.createElement("UIGridLayout", {
		CellSize = UDim2.new(0.19, 0, 0.19, 0),
		CellPadding = UDim2.new(0.01, 0, 0.01, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	for _, cardData in ipairs(self.state.cards) do
		local displayColor = cardData.Color
		if not showRealColors then
			displayColor = "Neutral"
		end
	
		children["Card_" .. cardData.Id] = Roact.createElement(Card, {
			Word = cardData.Word,
			Color = displayColor
		})
	end

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		BorderSizePixel = 0,
	}, {
		-- LEFT FLANK
		LeftPanel = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.1, 0.65),
			Position = UDim2.fromScale(0.05, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			List = Roact.createElement("UIListLayout", { Padding = UDim.new(0.05, 0), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
			
			P1 = Roact.createElement(PlayerIcon, { Team = "Red", RoleLabel = "SPY", FullRoleName = "RedSpymaster", MyRole = myRole }),
			P2 = Roact.createElement(PlayerIcon, { Team = "Red", RoleLabel = "OP", FullRoleName = "RedOperative", MyRole = myRole }),
		}),

		-- BOARD
		GameBoard = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.6, 0.65),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
		}, children),

		-- RIGHT FLANK
		RightPanel = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.1, 0.65),
			Position = UDim2.fromScale(0.95, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
		}, {
			List = Roact.createElement("UIListLayout", { Padding = UDim.new(0.05, 0), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
			
			P3 = Roact.createElement(PlayerIcon, { Team = "Blue", RoleLabel = "SPY", FullRoleName = "BlueSpymaster", MyRole = myRole }),
			P4 = Roact.createElement(PlayerIcon, { Team = "Blue", RoleLabel = "OP", FullRoleName = "BlueOperative", MyRole = myRole }),
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
		})
	})
end

return Board