-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local ServerScriptService = game:GetService("ServerScriptService")
-- local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

-- local serverFolder = ServerScriptService:FindFirstChild("Server")
-- local testsFolder = serverFolder and serverFolder:FindFirstChild("Tests")

-- if testsFolder then
-- 	print("STARTING TESTS...")
-- 	TestEZ.TestBootstrap:run({testsFolder}, TestEZ.Reporters.TextReporter)
-- else
-- 	warn("CRITICAL: Could not find 'Tests' folder in ServerScriptService.Server")
-- end