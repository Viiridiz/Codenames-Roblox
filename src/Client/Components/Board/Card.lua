local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Packages.Roact)

local Card = Roact.PureComponent:extend("Card")

local COLOR_MAP = {
	Red = Color3.fromRGB(255, 80, 80), 
	Blue = Color3.fromRGB(80, 160, 255), 
	Neutral = Color3.fromRGB(245, 235, 215), 
	Assassin = Color3.fromRGB(30, 30, 30), 
	Unknown = Color3.fromRGB(255, 255, 255)
}

function Card:init()
	self.buttonRef = Roact.createRef()
	self.hovered = false
	
	-- [[ ANIMATION HELPERS ]] --
	self.tween = function(props, time, style)
		local btn = self.buttonRef:getValue()
		if not btn then return end
		TweenService:Create(btn, TweenInfo.new(time, style, Enum.EasingDirection.Out), props):Play()
	end

	self.onHoverEnter = function()
		if self.props.IsRevealed then return end
		self.hovered = true
		self.tween({ Size = UDim2.fromScale(1.08, 1.08) }, 0.2, Enum.EasingStyle.Quad)
	end

	self.onHoverLeave = function()
		self.hovered = false
		self.tween({ Size = UDim2.fromScale(1, 1) }, 0.2, Enum.EasingStyle.Quad)
	end
	
	self.onActivate = function()
		if self.props.OnClick and not self.props.IsRevealed then
			local btn = self.buttonRef:getValue()
			if btn then
				local t = TweenService:Create(btn, TweenInfo.new(0.05), { Size = UDim2.fromScale(0.9, 0.9) })
				t:Play()
				t.Completed:Wait()
				TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), { Size = UDim2.fromScale(1, 1) }):Play()
			end
			self.props.OnClick(self.props.Id)
		end
	end
end

function Card:render()
	local word = self.props.Word or "???"
	local isRevealed = self.props.IsRevealed
	local isSpymaster = self.props.IsSpymaster
	local realColor = self.props.Color
	
	local displayColor
	local showDarkenOverlay = false
	
	if isSpymaster then
		displayColor = COLOR_MAP[realColor] or COLOR_MAP.Neutral
		if isRevealed then showDarkenOverlay = true end
	else
		if isRevealed then
			displayColor = COLOR_MAP[realColor] or COLOR_MAP.Neutral
		else
			displayColor = COLOR_MAP.Unknown
		end
	end

	local textColor = Color3.fromRGB(50, 50, 50)
	if (displayColor == COLOR_MAP.Red or displayColor == COLOR_MAP.Blue or displayColor == COLOR_MAP.Assassin) then
		textColor = Color3.fromRGB(255, 255, 255)
	end

	return Roact.createElement("TextButton", {
		Text = word,
		TextSize = 15, 
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = displayColor,
		TextColor3 = textColor,
		AutoButtonColor = false,
		ZIndex = 5,
		[Roact.Ref] = self.buttonRef,
		[Roact.Event.Activated] = self.onActivate,
		[Roact.Event.MouseEnter] = self.onHoverEnter,
		[Roact.Event.MouseLeave] = self.onHoverLeave,
	}, {
		Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }),
		Shadow = Roact.createElement("Frame", {
			ZIndex = 4,
			BackgroundColor3 = Color3.fromRGB(0,0,0),
			BackgroundTransparency = 0.8,
			Size = UDim2.new(1, 0, 1, 6),
			Position = UDim2.new(0, 0, 0, 0),
		}, {
			Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) })
		}),
		Darken = showDarkenOverlay and Roact.createElement("Frame", {
			Size = UDim2.fromScale(1,1),
			BackgroundColor3 = Color3.new(0,0,0),
			BackgroundTransparency = 0.6,
			ZIndex = 6,
		}, {
			Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) })
		})
	})
end

return Card