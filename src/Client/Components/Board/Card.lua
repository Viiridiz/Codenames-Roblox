local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Packages.Roact)

local Card = Roact.PureComponent:extend("Card")

local COLOR_MAP = {
    Red = Color3.fromRGB(255, 80, 80), 
    Blue = Color3.fromRGB(80, 160, 255), 
    Beige = Color3.fromRGB(245, 235, 215), 
    Black = Color3.fromRGB(30, 30, 30),  
    Unknown = Color3.fromRGB(255, 255, 255)
}

local function darken(c3, amount)
    local h, s, v = c3:ToHSV()
    return Color3.fromHSV(h, s, math.max(0, v - amount))
end

function Card:init()
    self.buttonRef = Roact.createRef()
    local TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    
    self.tween = function(props)
        local btn = self.buttonRef:getValue()
        if not btn then return end
        TweenService:Create(btn, TWEEN_INFO, props):Play()
    end

    self.shake = function()
        task.spawn(function()
            local btn = self.buttonRef:getValue()
            if not btn then return end
            local t1 = TweenService:Create(btn, TweenInfo.new(0.04, Enum.EasingStyle.Sine), { Rotation = 5 })
            local t2 = TweenService:Create(btn, TweenInfo.new(0.04, Enum.EasingStyle.Sine), { Rotation = -5 })
            local t3 = TweenService:Create(btn, TweenInfo.new(0.04, Enum.EasingStyle.Sine), { Rotation = 5 })
            local t4 = TweenService:Create(btn, TweenInfo.new(0.04, Enum.EasingStyle.Sine), { Rotation = 0 })
            t1:Play() t1.Completed:Wait()
            t2:Play() t2.Completed:Wait()
            t3:Play() t3.Completed:Wait()
            t4:Play()
        end)
    end

    self.onHoverEnter = function()
        if self.props.IsRevealed then return end
        local btn = self.buttonRef:getValue()
        if btn then 
            btn.ZIndex = 10 
            local currColor = btn.BackgroundColor3
            local targetColor = darken(currColor, 0.1)
            self.tween({ Size = UDim2.fromScale(1.05, 1.05), BackgroundColor3 = targetColor })
        end
    end

    self.onHoverLeave = function()
        local btn = self.buttonRef:getValue()
        if btn then
            btn.ZIndex = 5 
            self.tween({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = self.currentBaseColor or btn.BackgroundColor3 })
        end
    end
    
    self.onActivate = function()
        if self.props.OnClick and not self.props.IsRevealed then
            local btn = self.buttonRef:getValue()
            if btn then
                local tDown = TweenService:Create(btn, TweenInfo.new(0.04), { Size = UDim2.fromScale(0.95, 0.95) })
                tDown:Play()
                tDown.Completed:Wait()
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Size = UDim2.fromScale(1.05, 1.05) }):Play()
            end
            self.props.OnClick(self.props.Id)
        end
    end
end

function Card:didUpdate(prevProps)
    if self.props.IsRevealed and not prevProps.IsRevealed then
        if not self.props.IsSpymaster then
            local myTeamColor = (self.props.MyTeam == "Red") and "Red" or "Blue"
            if self.props.Color ~= myTeamColor then
                self.shake()
            end
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

    self.currentBaseColor = displayColor
    local textColor = Color3.fromRGB(50, 50, 50)

    if (displayColor == COLOR_MAP.Red or displayColor == COLOR_MAP.Blue or displayColor == COLOR_MAP.Assassin) then
        textColor = Color3.fromRGB(255, 255, 255)
    end
    
    return Roact.createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, {
        Button = Roact.createElement("TextButton", {
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
            Stroke = Roact.createElement("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1.5, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
            Shadow = Roact.createElement("Frame", { ZIndex = 4, BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.8, Size = UDim2.new(1, 0, 1, 6), Position = UDim2.new(0, 0, 0, 0) }, { Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }) }),
            Darken = showDarkenOverlay and Roact.createElement("Frame", { Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.6, ZIndex = 6 }, { Roact.createElement("UICorner", { CornerRadius = UDim.new(0.15, 0) }) })
        })
    })
end

return Card