
local ColorEnum = require(script.Parent.Parent.Enums.Color)
local Card = {}
Card.__index = Card

function Card.new(id, word)
    local self = setmetatable({}, Card)
    self.Id = id
    self.Word = word
    self.RealColor = ColorEnum.BEIGE
    self.IsRevealed = false
    return self
end

function Card:Get_IsRevealed() 
    return self.IsRevealed 
end

function Card:Set_IsRevealed(status) 
    self.IsRevealed = status 
end

function Card:Get_RealColor() 
    return self.RealColor 
end

return Card