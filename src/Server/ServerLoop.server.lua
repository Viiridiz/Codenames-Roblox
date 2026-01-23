local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local servicesFolder = ServerScriptService.Server.Services

Knit.AddServices(servicesFolder)

Knit.Start():andThen(function()
    print("Knit Server Started")
    print("Sync Works!")
end):catch(warn)