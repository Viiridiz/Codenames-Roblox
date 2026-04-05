local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local WinsLeaderboard = DataStoreService:GetOrderedDataStore("Codenames_Wins_Leaderboard_V1")

local LeaderboardService = Knit.CreateService({
    Name = "LeaderboardService",
    Client = {
        LeaderboardUpdated = Knit.CreateSignal()
    },
})

function LeaderboardService:KnitStart()
    self.Top10Cache = {}

    task.spawn(function()
        while true do
            self:UpdateLeaderboardCache()
            task.wait(60)
        end
    end)
end

function LeaderboardService:UpdatePlayerScore(userId, wins)
    task.spawn(function()
        pcall(function()
            WinsLeaderboard:SetAsync(tostring(userId), wins)
        end)
    end)
end

function LeaderboardService:UpdateLeaderboardCache()
    local success, errorMessage = pcall(function()
        local pages = WinsLeaderboard:GetSortedAsync(false, 10)
        local top10 = pages:GetCurrentPage()
        
        local formattedLeaderboard = {}
        for rank, data in ipairs(top10) do
            local name = "Unknown"
            pcall(function()
                name = Players:GetNameFromUserIdAsync(tonumber(data.key))
            end)

            table.insert(formattedLeaderboard, {
                Rank = rank,
                Name = name,
                Wins = data.value
            })
        end
        
        self.Top10Cache = formattedLeaderboard
        self.Client.LeaderboardUpdated:FireAll(self.Top10Cache)
    end)

    if not success then
        warn("Leaderboard fetch failed: " .. tostring(errorMessage))
    end
end

function LeaderboardService.Client:GetTop10()
    return self.Server.Top10Cache
end

return LeaderboardService