return function()
	-- 1. REQUIRE THE SERVICE
	local GameService = require(game:GetService("ServerScriptService").Server.Services.GameService)

	GameService.BoardService = {
		GenerateBoard = function() 
			-- Do nothing, just pretend we generated a board
			return {} 
		end,
		RevealCard = function() return "Red" end
	}
	
	-- We also need to fake the Signals because they are usually created by Knit
	GameService.Client = {
		TurnChanged = { FireAll = function() end },
		ScoreUpdate = { FireAll = function() end },
		TimerUpdate = { FireAll = function() end },
		ClueGiven = { FireAll = function() end }
	}

	describe("GameService Game Loop", function()
		
		it("should initialize the game correctly", function()
			-- Now this won't crash because we mocked BoardService!
			GameService:StartGame()
			
			expect(GameService.Score).to.equal(0)
			expect(GameService.CurrentTurn).to.equal("RedSpymaster")
			expect(GameService.TimeRemaining).to.be.ok()
		end)

		it("should allow state transitions", function()
			-- Simulate ending Spymaster turn
			GameService:SetTurn("RedOperative")
			expect(GameService.CurrentTurn).to.equal("RedOperative")
		end)
	end)
end