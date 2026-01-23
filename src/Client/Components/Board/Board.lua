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
	
	-- 2. Ask for the Board Data (Async)
	BoardService:GetBoard():andThen(function(serverBoard)
		self:setState({
			cards = serverBoard
		})
		print("Board Loaded from Server!")
	end):catch(warn)
end

function Board:render()

	local children = {}
	
	children.Layout = Roact.createElement("UIGridLayout", {
		CellSize = UDim2.new(0.18, 0, 0.18, 0), -- 5 cards per row
		CellPadding = UDim2.new(0.02, 0, 0.02, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	for _, cardData in ipairs(self.state.cards) do
		children["Card_" .. cardData.Id] = Roact.createElement(Card, {
			Word = cardData.Word,
			Color = cardData.Color
		})
	end

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(0.8, 0.8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	}, children)
end

return Board