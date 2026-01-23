local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

local Lobby = Roact.Component:extend("Lobby")

function Lobby:init()
	self.state = {
		inputText = ""
	}
end

function Lobby:render()
	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	}, {
		Container = Roact.createElement("Frame", {
			Size = UDim2.fromScale(0.4, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Layout = Roact.createElement("UIListLayout", {
				Padding = UDim.new(0.05, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),

			-- TITLE
			Title = Roact.createElement("TextLabel", {
				Text = "CODENAMES",
				Size = UDim2.fromScale(1, 0.3),
				Font = Enum.Font.GothamBlack,
				TextSize = 40,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
			}),

			-- CREATE
			CreateButton = Roact.createElement("TextButton", {
				Text = "CREATE ROOM",
				Size = UDim2.fromScale(1, 0.2),
				BackgroundColor3 = Color3.fromRGB(46, 204, 113), -- Green
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				
				[Roact.Event.Activated] = function()
					self.props.OnCreate()
				end
			}),

			-- JOIN INPUT
			CodeInput = Roact.createElement("TextBox", {
				PlaceholderText = "ENTER CODE",
				Text = self.state.inputText,
				Size = UDim2.fromScale(1, 0.2),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.Gotham,
				TextSize = 24,
				
				[Roact.Change.Text] = function(rbx)
					self:setState({ inputText = rbx.Text })
				end
			}),

			-- JOIN
			JoinButton = Roact.createElement("TextButton", {
				Text = "JOIN ROOM",
				Size = UDim2.fromScale(1, 0.2),
				BackgroundColor3 = Color3.fromRGB(52, 152, 219), -- Blue
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				
				[Roact.Event.Activated] = function()
					self.props.OnJoin(self.state.inputText)
				end
			})
		})
	})
end

return Lobby