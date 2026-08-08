--!strict

--[[
	Server Bootstrap

	Entry point for server startup.
	This file wires the architecture together without creating gameplay mechanics.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = ServerScriptService:WaitForChild("Services")

local moduleNames = {
	"PlayerData",
	"CombatSystem",
	"CrystalSystem",
	"QuestSystem",
	"NPCSystem",
	"InventorySystem",
	"SaveSystem",
}

local serviceNames = {
	"PlayerService",
	"CombatService",
	"DamageService",
	"QuestService",
	"CrystalService",
	"NPCService",
	"XPService",
	"EconomyService",
	"InventoryService",
}

local loadedModules = {}
local startupOrder = {}

for _, moduleName in moduleNames do
	local moduleScript = Modules:WaitForChild(moduleName)
	local module = require(moduleScript)
	loadedModules[moduleName] = module
	table.insert(startupOrder, module)
end

for _, serviceName in serviceNames do
	local serviceScript = Services:WaitForChild(serviceName)
	local service = require(serviceScript)
	loadedModules[serviceName] = service
	table.insert(startupOrder, service)
end

for _, module in startupOrder do
	if type(module.Init) == "function" then
		module.Init()
	end
end

for _, module in startupOrder do
	if type(module.Start) == "function" then
		module.Start()
	end
end
