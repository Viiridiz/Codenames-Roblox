local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local SoundController = Knit.CreateController({ Name = "SoundController" })

function SoundController:KnitStart()
    -- Start Background Music Loop
    self.BGM = Instance.new("Sound")
    self.BGM.SoundId = "rbxassetid://135242814447458"
    self.BGM.Looped = true
    self.BGM.Volume = 0.3
    self.BGM.Parent = SoundService
    self.BGM:Play()

    -- Cache Sound Effects for zero-latency playback
    self.SFX = {
        Click = "rbxassetid://88442833509532",
        Correct = "rbxassetid://94194254972246",
        Wrong = "rbxassetid://8466981206",
        GameOver = "rbxassetid://2126858630"
    }

    self.CachedSounds = {}
    for name, id in pairs(self.SFX) do
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Parent = SoundService
        self.CachedSounds[name] = s
    end

    self.CachedSounds["Correct"].Volume = 0.4

    -- Automatically listen for the Game Over event!
    Knit.GetService("GameService").GameOver:Connect(function()
        self:Play("GameOver")
    end)
end

function SoundController:Play(soundName)
    if self.CachedSounds[soundName] then
        self.CachedSounds[soundName]:Play()
    end
end

return SoundController