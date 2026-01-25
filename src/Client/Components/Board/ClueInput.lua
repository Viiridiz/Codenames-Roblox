local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

local ClueInput = Roact.Component:extend("ClueInput")

function ClueInput:init()
	self:setState({ number = 1, text = "" })
end

function ClueInput:render()
	if not self.props.IsVisible then return nil end

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(0.45, 0.14),
		Position = UDim2.fromScale(0.5, 0.94),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
		
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0.03, 0),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		
		WordInput = Roact.createElement("TextBox", {
			Size = UDim2.fromScale(0.4, 0.6),
			PlaceholderText = "TYPE CLUE",
			Text = self.state.text,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			TextColor3 = Color3.new(0,0,0),
			Font = Enum.Font.GothamBlack,
			TextSize = 18,
			ClearTextOnFocus = false,
			
			[Roact.Change.Text] = function(rbx)
				local cleaned = rbx.Text:gsub("%s+", ""):upper()
				if cleaned ~= rbx.Text then rbx.Text = cleaned end
				self:setState({ text = cleaned })
			end
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) })
		}),

		CounterFrame = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.3, 0.6),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			
			Minus = Roact.createElement("TextButton", {
				Text = "-",
				Size = UDim2.fromScale(0.3, 1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				[Roact.Event.Activated] = function()
					if self.state.number > 0 then
						self:setState({ number = self.state.number - 1 })
					end
				end
			}),
			
			NumDisplay = Roact.createElement("TextLabel", {
				Text = tostring(self.state.number),
				Size = UDim2.fromScale(0.4, 1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(80, 200, 255),
				Font = Enum.Font.GothamBlack,
				TextSize = 22,
			}),

			Plus = Roact.createElement("TextButton", {
				Text = "+",
				Size = UDim2.fromScale(0.3, 1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				[Roact.Event.Activated] = function()
					if self.state.number < 9 then
						self:setState({ number = self.state.number + 1 })
					end
				end
			}),
		}),

		SubmitBtn = Roact.createElement("TextButton", {
			Text = "CONFIRM",
			Size = UDim2.fromScale(0.2, 0.6),
			BackgroundColor3 = Color3.fromRGB(80, 220, 100),
			TextColor3 = Color3.new(1,1,1),
			Font = Enum.Font.GothamBlack,
			TextSize = 12,
			
			[Roact.Event.Activated] = function()
				print("ClueInput: Confirm Clicked with text:", self.state.text) -- DEBUG
				if self.state.text ~= "" and self.props.OnSubmit then
					self.props.OnSubmit(self.state.text, self.state.number)
					self:setState({ text = "", number = 1 })
				end
			end
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) })
		})
	})
end

return ClueInput