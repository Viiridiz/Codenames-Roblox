local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Roact = require(ReplicatedStorage.Packages.Roact)
local Knit = require(ReplicatedStorage.Packages.Knit)

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
		print("UI RECEIVED UPDATE:", updatedSlots, "HOST:", hostName)
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

function WaitingRoom:RenderSlotButton(role, color, position, isDisabled)
	local occupantName = self.state.slots[role]
	local isTaken = occupantName ~= nil
	
	local displayRole = formatRole(role)
	
	local text = displayRole
	if isTaken then
		text = displayRole .. "\n" .. occupantName
	else
		text = displayRole .. "\n[ OPEN ]"
	end

	-- Visual settings for Disabled state
	local transparency = (isTaken or isDisabled) and 0.6 or 0
	local activeState = not isDisabled 
	
	return Roact.createElement("TextButton", {
		Text = text,
		Size = UDim2.fromScale(0.4, 0.15),
		Position = position,
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.new(1,1,1),
		AutoButtonColor = activeState, 
		Active = activeState, 
		BorderSizePixel = 0,
		
		[Roact.Event.Activated] = function()
			if not isDisabled then
				self.props.OnSelectSlot(role)
			end
		end
	}, {
		Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.1, 0) })
	})
end

function WaitingRoom:render()
	local myName = Players.LocalPlayer.Name
	local amIHost = (myName == self.state.hostName)
	
	local startBtnColor = amIHost and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(60, 60, 60)
	local startBtnText = amIHost and "INITIATE" or "WAITING FOR HOST..."

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	}, {
		Title = Roact.createElement("TextLabel", {
			Text = "MISSION: " .. (self.props.RoomCode or "????") .. "\nHOST: " .. self.state.hostName,
			Size = UDim2.fromScale(1, 0.15),
			Position = UDim2.fromScale(0, 0.05),
			Font = Enum.Font.GothamBlack,
			TextSize = 24,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			BackgroundTransparency = 1,
		}),

		-- RED TEAM (Enabled)
		RedSpy = self:RenderSlotButton("RedSpymaster", Color3.fromRGB(180, 40, 40), UDim2.fromScale(0.05, 0.3), false),
		RedOp = self:RenderSlotButton("RedOperative", Color3.fromRGB(180, 40, 40), UDim2.fromScale(0.05, 0.5), false),

		-- BLUE TEAM (Disabled)
		BlueSpy = self:RenderSlotButton("BlueSpymaster", Color3.fromRGB(40, 90, 180), UDim2.fromScale(0.55, 0.3), true),
		BlueOp = self:RenderSlotButton("BlueOperative", Color3.fromRGB(40, 90, 180), UDim2.fromScale(0.55, 0.5), true),

		-- START BUTTON
		StartButton = Roact.createElement("TextButton", {
			Text = startBtnText,
			Size = UDim2.fromScale(0.3, 0.1),
			Position = UDim2.fromScale(0.35, 0.8),
			BackgroundColor3 = startBtnColor,
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = amIHost and Color3.new(0,0,0) or Color3.fromRGB(150,150,150),
			AutoButtonColor = false,
			Active = amIHost, 
			
			[Roact.Event.Activated] = function()
				if amIHost then
					self.props.OnStartGame()
				end
			end
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) })
		}),
		
		BackButton = Roact.createElement("TextButton", {
			Text = "ABORT",
			Size = UDim2.fromScale(0.1, 0.05),
			Position = UDim2.fromScale(0.88, 0.92),
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			TextColor3 = Color3.new(0.8,0.8,0.8),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			AutoButtonColor = false,
			
			[Roact.Event.Activated] = self.props.OnLeave
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) })
		})
	})
end

return WaitingRoom