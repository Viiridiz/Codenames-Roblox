local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Words = require(ReplicatedStorage.Shared.Words)

local BoardService = Knit.CreateService {
	Name = "BoardService",
	Client = {
		CardRevealed = Knit.CreateSignal(),
		
		GetBoard = function(self, player)
			return self.Server.CurrentBoard
		end
	},
}

BoardService.CurrentBoard = {}

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
			IsRevealed = false 
		})
	end
	
	self.CurrentBoard = board
	return board
end

function BoardService:RevealCard(cardId)
	local targetCard = nil
	for _, card in ipairs(self.CurrentBoard) do
		if card.Id == cardId then
			targetCard = card
			break
		end
	end

	if not targetCard or targetCard.IsRevealed then return nil end

	targetCard.IsRevealed = true
	self.Client.CardRevealed:FireAll(targetCard.Id, targetCard.Color)
	return targetCard.Color
end

function BoardService:KnitInit()
	self:GenerateBoard()
	print("BoardService: Initialized")
end

function BoardService:KnitStart() end

return BoardService