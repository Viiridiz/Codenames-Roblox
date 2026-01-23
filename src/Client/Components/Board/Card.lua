local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

local Card = Roact.Component:extend("Card")

--PALETTE
local COLOR_MAP = {
	Red = Color3.fromRGB(235, 87, 87),      -- Soft Red
	Blue = Color3.fromRGB(47, 128, 237),    -- Soft Blue
	Neutral = Color3.fromRGB(240, 230, 200),-- Beige (Sand)
	Assassin = Color3.fromRGB(50, 50, 50),  -- Dark Grey
}

function Card:render()
	local word = self.props.Word or "TBD"
	local colorName = self.props.Color or "Neutral"
	
	local finalColor = COLOR_MAP[colorName] or COLOR_MAP.Neutral
	
	local textColor = Color3.new(0,0,0) -- Default Black
	if colorName == "Assassin" then
		textColor = Color3.new(1,1,1) -- White
	end

	return Roact.createElement("TextButton", {
		Text = word,
		TextSize = 14,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		
		BackgroundColor3 = finalColor,
		TextColor3 = textColor,
		
		[Roact.Ref] = self.ref,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0.1, 0),
		})
	})
end

return Card