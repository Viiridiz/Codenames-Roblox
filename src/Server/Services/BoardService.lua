local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Words = require(ReplicatedStorage.Shared.Words)
local BoardModel = require(ReplicatedStorage.Shared.Models.Board)

local BoardService = Knit.CreateService {
    Name = "BoardService",
    Client = {
    },
}

BoardService.CurrentBoard = nil

-- US-2.2
function BoardService:GenerateBoard(gameRound)
    local shuffledWords = table.clone(Words)
    for i = #shuffledWords, 2, -1 do
        local j = math.random(i)
        shuffledWords[i], shuffledWords[j] = shuffledWords[j], shuffledWords[i]
    end

    -- 1.10: b = Create(gr, words)
    local board = BoardModel.new(gameRound, shuffledWords)
    
    -- 1.10.1 to 1.10.3: Loop 25 times
    board:Generate_Cards(shuffledWords)
    
    -- 1.10.4: Assign_Colors
    board:Assign_Colors(9, 8, 7, 1)
    
    self.CurrentBoard = board
    return board
end

function BoardService:GetActiveBoard()
    return self.CurrentBoard
end

function BoardService:KnitInit()
    print("BoardService: Initialized")
end

function BoardService:KnitStart() 
end

return BoardService