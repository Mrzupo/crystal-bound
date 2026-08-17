local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local CraftingService = require(script.Parent.Services.CraftingService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("CraftingRequest") or Instance.new("RemoteEvent")
remote.Name = "CraftingRequest"
remote.Parent = remotes

remote.OnServerEvent:Connect(function(player, action, outputId, amount)
	if action ~= "Craft" then return end
	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	local ok, message = CraftingService.Craft(profile, outputId, amount, InventoryService)
	player:SetAttribute("CraftingMessage", message)
	if ok then
		PlayerService.Sync(player)
		remotes.InventoryChanged:FireClient(player, profile.Inventory)
	end
end)
