local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerService = require(script.Parent.Services.PlayerService)
local CombatService = require(script.Parent.Services.CombatService)

local function ensureRemote(className, name)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local existing = remotes:FindFirstChild(name)
	if existing then return existing end

	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes
	return remote
end

for _, name in ipairs({ "CombatRequest", "QuestRequest", "NPCRequest", "InventoryRequest", "XPChanged", "LevelUp", "MoneyChanged", "InventoryChanged" }) do
	ensureRemote("RemoteEvent", name)
end
ensureRemote("RemoteFunction", "GetPlayerData")
ensureRemote("RemoteFunction", "GetQuestData")

local combatRemote = ReplicatedStorage.Remotes.CombatRequest
combatRemote.OnServerEvent:Connect(function(player, action, target)
	CombatService.HandleRequest(player, action, target)
end)

local function makeDummy()
	local npcs = Workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	npcs.Name = "NPCs"
	npcs.Parent = Workspace
	if npcs:FindFirstChild("TrainingDummy") then return end

	local model = Instance.new("Model")
	model.Name = "TrainingDummy"
	model.Parent = npcs

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = Vector3.new(0, 4, -12)
	root.Anchored = false
	root.Transparency = 1
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(3, 4, 2)
	torso.Position = Vector3.new(0, 5, -12)
	torso.Anchored = false
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Position = Vector3.new(0, 8, -12)
	head.Anchored = false
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model

	local weld1 = Instance.new("WeldConstraint")
	weld1.Part0 = root
	weld1.Part1 = torso
	weld1.Parent = root
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = torso
	weld2.Part1 = head
	weld2.Parent = torso

	model.PrimaryPart = root
	humanoid.Died:Connect(function()
		task.delay(3, function()
			if model.Parent then
				local current = model:FindFirstChildOfClass("Humanoid")
				if current then
					current.Health = current.MaxHealth
				end
			end
		end)
	end)
end

makeDummy()

Players.PlayerAdded:Connect(function(player)
	PlayerService.Load(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	PlayerService.Load(player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerService.Remove(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerService.Save(player)
	end
end)