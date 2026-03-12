local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Lobby = Roact.Component:extend("Lobby")

function Lobby:init()
	self.state = {
		inputText = "",
		errorMessage = nil 
	}
end

function Lobby:handleJoin()
	local code = self.state.inputText
	if code == "" then return end
	local RoomService = Knit.GetService("RoomService")

	RoomService:JoinRoom(code):andThen(function(success)
		if success then
			self:setState({ errorMessage = Roact.None })
			if self.props.OnJoin then
				self.props.OnJoin(code)
			end
		else
			self:setState({ errorMessage = "INVALID ROOM CODE" })
		end
	end)
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
				BackgroundColor3 = Color3.fromRGB(46, 204, 113),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				
				[Roact.Event.Activated] = function()
					if self.props.OnCreate then self.props.OnCreate() end
				end
			}),

			-- JOIN
			CodeInput = Roact.createElement("TextBox", {
				PlaceholderText = "ENTER CODE",
				Text = self.state.inputText,
				Size = UDim2.fromScale(1, 0.2),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.Gotham,
				TextSize = 24,
				
				[Roact.Change.Text] = function(rbx)
					-- FORCE UPPERCASE & LIMIT LENGTH
					local cleanText = string.upper(rbx.Text):sub(1, 4)
					rbx.Text = cleanText 
					
					self:setState({ 
						inputText = cleanText,
						errorMessage = Roact.None 
					})
				end
			}),

			-- ERROR MESSAGE
			ErrorLabel = self.state.errorMessage and Roact.createElement("TextLabel", {
				Text = self.state.errorMessage,
				Size = UDim2.fromScale(1, 0.1),
				TextColor3 = Color3.fromRGB(231, 76, 60), -- Red
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 18
			}),

			-- JOIN BUTTON
			JoinButton = Roact.createElement("TextButton", {
				Text = "JOIN ROOM",
				Size = UDim2.fromScale(1, 0.2),
				BackgroundColor3 = Color3.fromRGB(52, 152, 219),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				
				[Roact.Event.Activated] = function()
					self:handleJoin()
				end
			})
		})
	})
end

return Lobby