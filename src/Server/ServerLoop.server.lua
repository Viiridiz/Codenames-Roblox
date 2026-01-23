local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Add Services here later

Knit.Start():andThen(function()
    print("Knit Server Started")
end):catch(warn)

print("Sync Works!")