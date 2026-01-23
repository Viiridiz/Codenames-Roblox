return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	
	local BoardService = require(ServerScriptService.Server.Services.BoardService)

	describe("BoardService Game Board Generation", function()
		
		it("should generate a board with exactly 25 cards", function()
			local board = BoardService:GenerateBoard()
			expect(#board).to.equal(25)
		end)

		it("should have the correct color distribution", function()
			local board = BoardService:GenerateBoard()
			
			local counts = {
				Red = 0,
				Blue = 0,
				Neutral = 0,
				Assassin = 0
			}

			for _, card in ipairs(board) do
				if counts[card.Color] then
					counts[card.Color] += 1
				end
			end

			-- Codenames Standard Distribution
			expect(counts.Red).to.equal(9)
			expect(counts.Blue).to.equal(8)
			expect(counts.Neutral).to.equal(7)
			expect(counts.Assassin).to.equal(1)
		end)

        it("should assign valid words to cards", function()
			local board = BoardService:GenerateBoard()
			for _, card in ipairs(board) do
				expect(typeof(card.Word)).to.equal("string")
				expect(#card.Word).to.be.ok() -- Checks string is not empty
				expect(card.Word).never.to.equal("TBD")
			end
		end)
	end)
end