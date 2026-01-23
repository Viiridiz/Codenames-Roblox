local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Import the word list
local Words = require(ReplicatedStorage.Shared.Words)

local BoardService = Knit.CreateService {
    Name = "BoardService",
    Client = {},
}

-- Shuffle Method
local function shuffle(t)
    local n = #t
    local newTable = table.clone(t) -- Clone
    for i = n, 2, -1 do
        local j = math.random(i)
        newTable[i], newTable[j] = newTable[j], newTable[i]
    end
    return newTable
end

function BoardService:GenerateBoard()
    -- 1. Setup Colors (9 Red, 8 Blue, 7 Neutral, 1 Assassin)
    local colors = {}
    for _ = 1, 9 do table.insert(colors, "Red") end
    for _ = 1, 8 do table.insert(colors, "Blue") end
    for _ = 1, 7 do table.insert(colors, "Neutral") end
    table.insert(colors, "Assassin")

    local shuffledColors = shuffle(colors)
    local shuffledWords = shuffle(Words) -- Shuffles

    local board = {}
    for i = 1, 25 do
        table.insert(board, {
            Id = i,
            Word = shuffledWords[i], -- Pick the first 25 words
            Color = shuffledColors[i],
            IsRevealed = false
        })
    end

    return board
end

function BoardService:KnitStart()
    print("BoardService Started")
end

function BoardService:KnitInit()
    print("BoardService Initialized")
end

return BoardService