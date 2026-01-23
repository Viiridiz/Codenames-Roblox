local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)

local Board = require(script.Parent.Components.Board.Board)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameUI"
screenGui.Parent = playerGui

Knit.Start():andThen(function()
    print("Knit Client Started")

    Roact.mount(Roact.createElement(Board), screenGui, "BoardHandle")
    
end):catch(warn)