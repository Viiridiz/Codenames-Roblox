local CardModel = require(script.Parent.Card)
local ColorEnum = require(script.Parent.Parent.Enums.Color)

local Board = {}
Board.__index = Board

local function shuffle(t)
    local newTable = table.clone(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        newTable[i], newTable[j] = newTable[j], newTable[i]
    end
    return newTable
end

function Board.new(gameRound, wordsList)
    local self = setmetatable({}, Board)
    self.GameRound = gameRound
    self.Cards = {}
    return self
end

-- US-2.2
function Board:Generate_Cards(wordsList)
    for i = 1, 25 do
        local c = CardModel.new(i, wordsList[i])
        table.insert(self.Cards, c)
    end
end

-- US-2.2
function Board:Assign_Colors(redCount, blueCount, beigeCount, blackCount)
    local colors = {}
    for _ = 1, redCount do table.insert(colors, ColorEnum.RED) end
    for _ = 1, blueCount do table.insert(colors, ColorEnum.BLUE) end
    for _ = 1, beigeCount do table.insert(colors, ColorEnum.BEIGE) end
    for _ = 1, blackCount do table.insert(colors, ColorEnum.BLACK) end
    
    local shuffledColors = shuffle(colors)
    
    for i, card in ipairs(self.Cards) do
        card.RealColor = shuffledColors[i]
    end
end

function Board:Get_Card(cardId)
    for _, card in ipairs(self.Cards) do
        if card.Id == cardId then 
            return card 
        end
    end
    return nil
end

-- US-4.3
function Board:Check_Word_Conflict(word)
    local lowerWord = string.lower(word)
    for _, card in ipairs(self.Cards) do
        if string.lower(card.Word) == lowerWord then 
            return true 
        end
    end
    return false
end

-- US-3.2
function Board:Get_Secret_Board_Data()
    local data = {}
    for _, card in ipairs(self.Cards) do
        table.insert(data, {
            Id = card.Id,
            Word = card.Word,
            Color = card.RealColor,
            IsRevealed = card.IsRevealed
        })
    end
    return data
end

return Board