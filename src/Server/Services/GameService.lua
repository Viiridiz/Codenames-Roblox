local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local TURN_DURATION = 60
local ROLES = {
	SPYMASTER = "RedSpymaster",
	OPERATIVE = "RedOperative",
}

local GameService = Knit.CreateService({
	Name = "GameService",
	Client = {
		TurnChanged = Knit.CreateSignal(),
		TimerUpdate = Knit.CreateSignal(),
		ScoreUpdate = Knit.CreateSignal(),
		ClueGiven = Knit.CreateSignal(),
		GameOver = Knit.CreateSignal(),
		
		-- [[ 1. GET STATE ]] --
		GetState = function(self, player)
			local server = self.Server
			return {
				Turn = server.CurrentTurn,
				Time = math.ceil(server.TimeRemaining or 0),
				Score = server.Score or 0,
				Clue = server.CurrentClue,
				Winner = server.Winner -- Send winner if game is over
			}
		end,

		GiveClue = function(self, player, word, number)
			local server = self.Server
			if server.Winner then return end -- No clues if game over

			if not server.IsGameRunning then server:StartGame() end
			if server.CurrentTurn ~= ROLES.SPYMASTER then return end

			server.CurrentClue = { Word = word, Number = number }
			server.Client.ClueGiven:FireAll(word, number)
			server:SetTurn(ROLES.OPERATIVE)
		end,

		-- [[ 3. GUESS WORD ]] --
		GuessWord = function(self, player, cardId)
			local server = self.Server
			if server.Winner then return end -- No guessing if game over
			if server.CurrentTurn ~= ROLES.OPERATIVE then return end

			local revealedColor = server.BoardService:RevealCard(cardId)
			if not revealedColor then return end 

			-- [[ WIN/LOSS LOGIC ]] --
			if revealedColor == "Assassin" then
				-- Instant Loss: If Red hits it, Blue Wins
				server:EndGame("Blue")
				return
			
			elseif revealedColor == "Red" then
				server.Score += 1
				server.CurrentGuesses += 1
				server.CardsLeft.Red -= 1
				server.Client.ScoreUpdate:FireAll(server.Score)
				
				if server.CardsLeft.Red <= 0 then
					server:EndGame("Red")
					return
				end
				
			elseif revealedColor == "Blue" then
				-- Hit Enemy Card -> Turn Ends
				server.CardsLeft.Blue -= 1
				if server.CardsLeft.Blue <= 0 then
					server:EndGame("Blue")
					return
				end
				server:SetTurn(ROLES.SPYMASTER)
				
			elseif revealedColor == "Neutral" then
				-- Hit Civilian -> Turn Ends
				server:SetTurn(ROLES.SPYMASTER)
			end
		end
	},
})

function GameService:KnitInit()
	self.CurrentTurn = nil
	self.TimeRemaining = 0
	self.Score = 0
	self.IsGameRunning = false
	self.Winner = nil
	self.CurrentGuesses = 0
	self.CurrentClue = { Word = "", Number = 0 }
	self.CardsLeft = { Red = 9, Blue = 8 } -- Standard Codenames counts
	
	task.spawn(function()
		while true do
			task.wait(1)
			if self.IsGameRunning and self.TimeRemaining > 0 and not self.Winner then
				self.TimeRemaining = self.TimeRemaining - 1
				self.Client.TimerUpdate:FireAll(self.TimeRemaining)
				if self.TimeRemaining <= 0 then self:HandleTimeout() end
			end
		end
	end)
end

function GameService:KnitStart()
	self.BoardService = Knit.GetService("BoardService")
end

function GameService:StartGame()
	print("GameService: STARTING FRESH GAME")
	self.IsGameRunning = true
	self.Winner = nil
	self.Score = 0
	self.CardsLeft = { Red = 9, Blue = 8 }
	
	self.BoardService:GenerateBoard()
	
	self.CurrentClue = { Word = "", Number = 0 }
	self.Client.ClueGiven:FireAll("", 0)
	
	-- Notify clients to clear Game Over screens
	self.Client.GameOver:FireAll(nil) 
	
	self:SetTurn(ROLES.SPYMASTER)
end

function GameService:EndGame(winningTeam)
	print("GAME OVER! Winner:", winningTeam)
	self.Winner = winningTeam
	self.IsGameRunning = false
	self.Client.GameOver:FireAll(winningTeam)
end

function GameService:SetTurn(role)
	self.CurrentTurn = role
	self.TimeRemaining = TURN_DURATION
	self.CurrentGuesses = 0 
	self.Client.TurnChanged:FireAll(role)
	self.Client.ScoreUpdate:FireAll(self.Score)
	
	if role == ROLES.SPYMASTER then
		self.CurrentClue = { Word = "", Number = 0 }
		self.Client.ClueGiven:FireAll("", 0)
	end
end

function GameService:HandleTimeout()
	if self.Winner then return end
	if self.CurrentTurn == ROLES.SPYMASTER then
		self:SetTurn(ROLES.OPERATIVE)
	else
		self:SetTurn(ROLES.SPYMASTER)
	end
end

return GameService