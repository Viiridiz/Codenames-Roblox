-- CLUE MODEL
local Clue = {}
Clue.__index = Clue
function Clue.new(word, number)
    local self = setmetatable({}, Clue)
    self.Word = word
    self.Number = number
    return self
end
function Clue:Set_Word(word) self.Word = word end
function Clue:Set_Number(number) self.Number = number end
return Clue