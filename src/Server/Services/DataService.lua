local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerDataStore = DataStoreService:GetDataStore("Codenames_Data_V1")

local DataService = Knit.CreateService({
    Name = "DataService",
    Client = {},
})

DataService.Cache = {}

function DataService:KnitStart()
    Players.PlayerRemoving:Connect(function(player)
        self.Cache[player.UserId] = nil
    end)
end

function DataService:LoadPlayerData(player)
    local userId = tostring(player.UserId)

    if self.Cache[userId] then 
        local cachedData = self.Cache[userId]
        if cachedData.EquippedTag then
            player:SetAttribute("EquippedTag", cachedData.EquippedTag)
        end
        return cachedData 
    end

    local success, data = pcall(function()
        return PlayerDataStore:GetAsync(userId)
    end)

    if success and data then
        self.Cache[userId] = data
        
        if data.EquippedTag then
            player:SetAttribute("EquippedTag", data.EquippedTag)
        end
        
        return data
    else
        local newData = { Coins = 0, Wins = 0, Streak = 0, EquippedTag = nil }
        self.Cache[userId] = newData
        return newData
    end
end

function DataService:SavePlayerStats(playerModel)
    local userId = tostring(playerModel.UserId)
    
    local existingTag = nil
    if self.Cache[userId] and self.Cache[userId].EquippedTag then
        existingTag = self.Cache[userId].EquippedTag
    end

    local dataToSave = {
        Coins = playerModel.Coins,
        Wins = playerModel.Wins,
        Streak = playerModel.Streak,
        EquippedTag = existingTag
    }

    Knit.GetService("LeaderboardService"):UpdatePlayerScore(userId, playerModel.Wins)
    self.Cache[userId] = dataToSave

    task.spawn(function()
        local success, err = pcall(function()
            PlayerDataStore:SetAsync(userId, dataToSave)
        end)
        if not success then warn("Failed to save: " .. tostring(err)) end
    end)
end

-- ==========================================
-- SHOP & UI CLIENT ENDPOINTS
-- ==========================================

function DataService.Client:GetMyData(player)
    return self.Server:LoadPlayerData(player)
end

function DataService.Client:BuyItem(player, itemName, cost)
    local data = self.Server:LoadPlayerData(player)
    
    if data.Coins >= cost then
        data.Coins = data.Coins - cost
        data.EquippedTag = itemName
        player:SetAttribute("EquippedTag", itemName)
        
        self.Server.Cache[tostring(player.UserId)] = data
        
        local mockPlayer = { UserId = player.UserId, UserName = player.Name, Coins = data.Coins, Wins = data.Wins, Streak = data.Streak, EquippedTag = itemName }
        self.Server:SavePlayerStats(mockPlayer)
        return true, data.Coins
    end
    return false, data.Coins
end

return DataService