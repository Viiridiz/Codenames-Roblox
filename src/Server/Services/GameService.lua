local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GameRoundModel = require(ReplicatedStorage.Shared.Models.GameRound)
local BoardModel = require(ReplicatedStorage.Shared.Models.Board) 
local Dictionary = require(ReplicatedStorage.Shared.Words) 
local TeamEnum = require(ReplicatedStorage.Shared.Enums.Team)
local ColorEnum = require(ReplicatedStorage.Shared.Enums.Color)
local RoleEnum = require(ReplicatedStorage.Shared.Enums.Role)

local GameService = Knit.CreateService({
    Name = "GameService",
    Client = {
        GameStarted = Knit.CreateSignal(),
        TurnChanged = Knit.CreateSignal(),
        TimerUpdate = Knit.CreateSignal(),
        ScoreUpdate = Knit.CreateSignal(),
        ClueGiven = Knit.CreateSignal(),
        GameOver = Knit.CreateSignal(),
        CardColorDisplayed = Knit.CreateSignal(),
        SecretBoardData = Knit.CreateSignal(),
        LogsUpdated = Knit.CreateSignal(),
        ErrorMessage = Knit.CreateSignal(), 
    },
})

local DataStore = {
    ActiveRound = nil,
    ActiveBoard = nil
}

function DataStore:Get_Room(code) return Knit.GetService("RoomService"):GetRoom(code) end
function DataStore:Save_Game_State(r, gr, b) self.ActiveRound = gr; self.ActiveBoard = b end
function DataStore:Get_Active_Round() return self.ActiveRound end
function DataStore:Get_Active_Board() return self.ActiveBoard end
function DataStore:Get_Room_State(roomId) return self.ActiveRound end
function DataStore:Save_State(gr, b) self.ActiveRound = gr; self.ActiveBoard = b end
function DataStore:Save_Round_State(gr) self.ActiveRound = gr end

function GameService:KnitStart() end

function GameService:Display_message(player, msg) 
    if player then
        self.Client.ErrorMessage:Fire(player, msg)
    else
        warn(msg) 
    end
end

function GameService:Display_Board(b) print("Board UI Update") end

function GameService:Display_CardColor(cardId, color) 
    self.Client.CardColorDisplayed:FireAll(cardId, color) 
end

function GameService:Display_TimerUpdate(gr) self.Client.TimerUpdate:FireAll(gr.TurnTimer) end
function GameService:Display_SecretBoard(data) self.Client.SecretBoardData:FireAll(data) end
function GameService:Display_Logs() self.Client.LogsUpdated:FireAll() end

function GameService:Display_TurnUpdate(gr)
    self.Client.TurnChanged:FireAll(gr:Get_Turn_String())
end

function GameService:Display_ScoreUpdate(gr)
    self.Client.ScoreUpdate:FireAll(gr.ScoreRed, gr.ScoreBlue)
end

function GameService:Cancel_Timer(roomId) print("Timer Cancelled") end
function GameService:Reset_Turn_Timer(gr) gr.TurnTimer = 60 end
function GameService:Lock_Spymaster_Input(player) print("Locked input for", player) end

function GameService:Check_String_Format(word)
    return not string.find(word, " ")
end

-- US-5.3: Player Persistence & Economy
function GameService:SaveGameStats(gr)
    if gr and gr.Room then
        for _, p in ipairs(gr.Room.Players) do
            print("Saving DB -> " .. p.UserName .. ": Coins=" .. p.Coins .. " Wins=" .. p.Wins)
        end
    end
end

-- US-5.2: Disconnect Handling
function GameService:AbortActiveGame(roomId, disconnectedName)
    local gr = DataStore:Get_Room_State(roomId)
    if not gr or gr.State == "GameOver" then return end

    gr:AbortGame()
    self:Cancel_Timer(roomId)

    self:Display_message(nil, "Game Aborted: " .. disconnectedName .. " disconnected.")
    self.Client.GameOver:FireAll("Aborted")
    
    self:SaveGameStats(gr)
end

-- ==========================================
-- US-2.1 / 2.2: Start Game
-- ==========================================
function GameService.Client:StartGame(player, code)
    local selfServer = self.Server
    
    local r = DataStore:Get_Room(code)
    if r == nil then
        selfServer:Display_message(player, "Error: Room not found")
        return false
    end
    
    local isHost = r:Check_Host(player)
    if isHost == false then
        selfServer:Display_message(player, "Error: Only the Host can start")
        return false
    end
    
    local count = r:Get_Player_Count()
    if count < 2 or count > 4 then
        selfServer:Display_message(player, "Error: Need 2-4 players")
        return false
    end
    
    r:Set_State("Playing")
    local gr = GameRoundModel.new()
    gr:Associate_Room(r)
    
    -- US-5.1: (WordPack & Difficulty)
    local pack = r.WordPack or "Standard"
    local words = Dictionary:Get_Random_Words(25, pack)
    local b = BoardModel.new(gr, words)
    b:Generate_Cards(words)
    
    local diff = r.Difficulty or "Normal"
    if diff == "Hard" then
        b:Assign_Colors(9, 8, 6, 2) -- Hard mode: 2 Assassins
    elseif diff == "Easy" then
        b:Assign_Colors(9, 8, 8, 0) -- Easy mode: 0 Assassins
    else
        b:Assign_Colors(9, 8, 7, 1) -- Normal mode: 1 Assassin
    end
    
    DataStore:Save_Game_State(r, gr, b)
    
    selfServer:Display_Board(b)
    self.GameStarted:FireAll() 
    
    selfServer:Display_TurnUpdate(gr)
    selfServer:Display_ScoreUpdate(gr)
    
    task.spawn(function()
        while gr and gr.State ~= "GameOver" and gr.State ~= "Aborted" do
            task.wait(1)
            gr.TurnTimer = gr.TurnTimer - 1
            if gr.TurnTimer <= 0 then
                selfServer:TriggerTimeExpired(code)
            else
                selfServer:Display_TimerUpdate(gr)
            end
        end
    end)
    
    return true
end

-- ==========================================
-- US-3.2: Request Secret Board 
-- ==========================================
function GameService.Client:RequestSecretBoard(player)
    local selfServer = self.Server
    local gr = DataStore:Get_Active_Round()
    
    if gr == nil or gr.State == "GameOver" or gr.State == "Aborted" then
        selfServer:Display_message(player, "Error: Game is not active")
        return
    end

    local b = DataStore:Get_Active_Board()
    if not b then return end
    
    local secretBoardData = b:Get_Secret_Board_Data()
    self.SecretBoardData:Fire(player, secretBoardData)
end

-- ==========================================
-- US-4.1: Select Card 
-- ==========================================
function GameService.Client:SelectCard(player, cardId)
    local selfServer = self.Server
    local gr = DataStore:Get_Active_Round()
    local validTurn = gr:Validate_Operative_Turn(player)
    
    if validTurn == false or gr.State ~= "Guessing Phase" then
        selfServer:Display_message(player, "Error: Not your active turn")
        return
    end
    
    local b = DataStore:Get_Active_Board()
    local c = b:Get_Card(cardId)
    local revealed = c:Get_IsRevealed()
    
    if revealed == true then
        selfServer:Display_message(player, "Error: Card already revealed")
        return
    end
    
    c:Set_IsRevealed(true)
    local color = c:Get_RealColor()
    
    if color == ColorEnum.BLACK then
        local opposingTeam = (gr.CurrentTurn == TeamEnum.RED) and TeamEnum.BLUE or TeamEnum.RED
        gr:Set_Winner(opposingTeam)
        
        -- US-5.3: Save Stats
        selfServer:SaveGameStats(gr)
        self.GameOver:FireAll(tostring(opposingTeam))
        
    elseif color == gr.CurrentTurn then
        gr:Increment_Score()
        selfServer:Display_ScoreUpdate(gr)
        
        local remaining = b:Get_Remaining_Cards(color)
        if remaining == 0 then
            gr:Set_Winner(color)
            selfServer:SaveGameStats(gr)
            self.GameOver:FireAll(tostring(color))
        end
    else 
        gr:Switch_Turn()
        gr:Set_State("Clue Phase")
        selfServer:Reset_Turn_Timer(gr)
        selfServer:Display_TurnUpdate(gr)
    end
    
    DataStore:Save_State(gr, b)
    selfServer:Display_CardColor(cardId, color)
end

-- ==========================================
-- US-4.3: Submit Clue
-- ==========================================
function GameService.Client:SubmitClue(player, word, number)
    local selfServer = self.Server
    local gr = DataStore:Get_Active_Round()
    
    local validTurn = gr:Validate_Spymaster_Turn(player)
    if validTurn == false or gr.State ~= "Clue Phase" then
        selfServer:Display_message(player, "Error: Not your turn to give a clue")
        return
    end

    local formatValid = selfServer:Check_String_Format(word)
    if formatValid == false then
        selfServer:Display_message(player, "Error: Clue must be a single word (no spaces)")
        return
    end

    local b = DataStore:Get_Active_Board()
    local isCheating = b:Check_Word_Conflict(word)
    if isCheating == true then
        selfServer:Display_message(player, "Error: Illegal Clue - Word is on the board")
        return
    end

    gr:Append_ClueLog(word, number)
    gr:Set_State("Guessing Phase")
    gr.ActiveRole = RoleEnum.OPERATIVE

    selfServer:Lock_Spymaster_Input(player)
    selfServer:Reset_Turn_Timer(gr)
    DataStore:Save_Round_State(gr)
    
    selfServer:Display_TurnUpdate(gr)
    selfServer:Display_Logs()
    self.ClueGiven:FireAll(word, number)
end

-- ==========================================
-- US-4.2: Timer System
-- ==========================================
function GameService:TriggerTimeExpired(roomId)
    local gr = DataStore:Get_Room_State(roomId)
    if gr == nil or gr.State == "GameOver" or gr.State == "Aborted" then
        self:Cancel_Timer(roomId)
        return
    end

    gr:Switch_Turn()
    local RoleEnum = require(game:GetService("ReplicatedStorage").Shared.Enums.Role)
    if gr.ActiveRole == RoleEnum.OPERATIVE then
        gr:Set_State("Guessing Phase")
        
    else
        gr:Set_State("Clue Phase")
    end
    self:Reset_Turn_Timer(gr)
    DataStore:Save_Round_State(gr)
    
    self:Display_TurnUpdate(gr)
    self:Display_TimerUpdate(gr)
end

return GameService