local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerService = require(script.Parent.Services.PlayerService)
local CombatService = require(script.Parent.Services.CombatService)
local QuestService = require(script.Parent.Services.QuestService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)

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

local questRemote = ReplicatedStorage.Remotes.QuestRequest
questRemote.OnServerEvent:Connect(function(player, action, questId)
	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	if action == "Start" and type(questId) == "string" then
		QuestService.Start(player, profile, questId)
	elseif action == "Complete" and type(questId) == "string" then
		QuestService.Complete(player, profile, questId, require(script.Parent.Services.XPService), require(script.Parent.Services.EconomyService), PlayerService)
	end
end)

ReplicatedStorage.Remotes.GetPlayerData.OnServerInvoke = function(player)
	return PlayerService.GetProfile(player)
end

ReplicatedStorage.Remotes.GetQuestData.OnServerInvoke = function(player)
	local profile = PlayerService.GetProfile(player)
	if not profile then return { Active = {}, Completed = {}, Definitions = QuestSystem.GetDefinitions() } end
	return { Active = profile.ActiveQuests, Completed = profile.CompletedQuests, Definitions = QuestSystem.GetDefinitions() }
end

local function ensureStarterMap()
	local islands = Workspace:FindFirstChild("Islands") or Instance.new("Folder")
	islands.Name = "Islands"
	islands.Parent = Workspace
	if islands:FindFirstChild("StarterIsland") then return end

	local island = Instance.new("Model")
	island.Name = "StarterIsland"
	island.Parent = islands

	local floor = Instance.new("Part")
	floor.Name = "Ground"
	floor.Size = Vector3.new(120, 2, 120)
	floor.Position = Vector3.new(0, 0, 0)
	floor.Anchored = true
	floor.Parent = island

	local spawnFolder = Workspace:FindFirstChild("Spawn") or Instance.new("Folder")
	spawnFolder.Name = "Spawn"
	spawnFolder.Parent = Workspace
	if not spawnFolder:FindFirstChild("StarterSpawn") then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "StarterSpawn"
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Position = Vector3.new(0, 2, 5)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Parent = spawnFolder
	end
end

local function spawnQuestGiver()
	local npcs = Workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	npcs.Name = "NPCs"
	npcs.Parent = Workspace
	if npcs:FindFirstChild("CrystalKeeper") then return end

	local model = Instance.new("Model")
	model.Name = "CrystalKeeper"
	model:SetAttribute("Interactable", true)
	model.Parent = npcs

	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Size = Vector3.new(3, 4, 2)
	body.Position = Vector3.new(12, 3, -2)
	body.Anchored = true
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Position = Vector3.new(12, 6, -2)
	head.Anchored = true
	head.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Quest"
	prompt.ObjectText = "Crystal Keeper"
	prompt.MaxActivationDistance = 12
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		local profile = PlayerService.GetProfile(player)
		if not profile then return end
		if not QuestSystem.IsActive(profile, "FIRST_FIGHT") and not QuestSystem.IsCompleted(profile, "FIRST_FIGHT") then
			QuestService.Start(player, profile, "FIRST_FIGHT")
		elseif not QuestSystem.IsActive(profile, "CRYSTAL_POWER") and not QuestSystem.IsCompleted(profile, "CRYSTAL_POWER") then
			QuestService.Start(player, profile, "CRYSTAL_POWER")
		end
		player:SetAttribute("QuestMessage", "Quest updated!")
	end)
end

local function spawnTrainingDummy()
	local npcs = Workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	npcs.Name = "NPCs"
	npcs.Parent = Workspace
	local old = npcs:FindFirstChild("TrainingDummy")
	if old then old:Destroy() end

	local model = Instance.new("Model")
	model.Name = "TrainingDummy"
	model.Parent = npcs
	model:SetAttribute("Enemy", true)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = Vector3.new(0, 4, -12)
	root.Transparency = 1
	root.Anchored = true
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(3, 4, 2)
	torso.Position = Vector3.new(0, 5, -12)
	torso.Anchored = true
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Position = Vector3.new(0, 8, -12)
	head.Anchored = true
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.DisplayName = "Training Dummy"
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
			if npcs.Parent and not npcs:FindFirstChild("TrainingDummy") then spawnTrainingDummy() end
		end)
	end)
end

ensureStarterMap()
spawnQuestGiver()
spawnTrainingDummy()

Players.PlayerAdded:Connect(function(player)
	local profile = PlayerService.Load(player)
	if not QuestSystem.IsActive(profile, "FIRST_FIGHT") and not QuestSystem.IsCompleted(profile, "FIRST_FIGHT") then
		QuestService.Start(player, profile, "FIRST_FIGHT")
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	local profile = PlayerService.Load(player)
	if not QuestSystem.IsActive(profile, "FIRST_FIGHT") and not QuestSystem.IsCompleted(profile, "FIRST_FIGHT") then
		QuestService.Start(player, profile, "FIRST_FIGHT")
	end
end

Players.PlayerRemoving:Connect(function(player)
	PlayerService.Remove(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerService.Save(player)
	end
end)
