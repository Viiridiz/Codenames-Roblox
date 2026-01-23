local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Words = require(ReplicatedStorage.Shared.Words)

local BoardService = Knit.CreateService {
    Name = "BoardService",
    Client = {},
}

-- This holds the single game board for everyone
local currentBoard = {}

local function shuffle(t)
    local newTable = table.clone(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        newTable[i], newTable[j] = newTable[j], newTable[i]
    end
    return newTable
end

function BoardService:GenerateBoard()
    local colors = {}
    for _ = 1, 9 do table.insert(colors, "Red") end
    for _ = 1, 8 do table.insert(colors, "Blue") end
    for _ = 1, 7 do table.insert(colors, "Neutral") end
    table.insert(colors, "Assassin")

    local shuffledColors = shuffle(colors)
    local shuffledWords = shuffle(Words)

    local board = {}
    for i = 1, 25 do
        table.insert(board, {
            Id = i,
            Word = shuffledWords[i],
            Color = shuffledColors[i],
            IsRevealed = false -- Hidden by default
        })
    end
    
    -- SAVE IT to the private memory
    currentBoard = board
    return board
end

--The UI calls this to "Download" the board
function BoardService.Client:GetBoard(player)
    return currentBoard
end

function BoardService:KnitInit()
    -- Generate the board immediately when the server starts
    self:GenerateBoard()
    print("BoardService: Initial Board Generated.")
end

function BoardService:KnitStart()
    print("BoardService Started")
end

return BoardService