local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerService = require(script.Parent.Services.PlayerService)
local CombatService = require(script.Parent.Services.CombatService)
local QuestService = require(script.Parent.Services.QuestService)
local CrystalService = require(script.Parent.Services.CrystalService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local NPCService = require(script.Parent.Services.NPCService)

local crystalRequirements = { EMBER = 1, TIDE = 3, GALE = 5 }

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

for _, name in ipairs({
	"CombatRequest", "QuestRequest", "NPCRequest", "InventoryRequest",
	"XPChanged", "LevelUp", "MoneyChanged", "InventoryChanged", "CrystalChanged",
}) do
	ensureRemote("RemoteEvent", name)
end
ensureRemote("RemoteFunction", "GetPlayerData")
ensureRemote("RemoteFunction", "GetQuestData")

local remotes = ReplicatedStorage.Remotes

remotes.CombatRequest.OnServerEvent:Connect(function(player, action, target)
	CombatService.HandleRequest(player, action, target)
end)

remotes.QuestRequest.OnServerEvent:Connect(function(player, action, questId)
	local profile = PlayerService.GetProfile(player)
	if not profile or type(questId) ~= "string" then return end
	if action == "Start" then
		QuestService.Start(player, profile, questId)
	end
end)

remotes.InventoryRequest.OnServerEvent:Connect(function(player)
	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	remotes.InventoryChanged:FireClient(player, profile.Inventory)
end)

remotes.CrystalChanged.OnServerEvent:Connect(function(player, crystalId)
	if type(crystalId) ~= "string" or not CrystalSystem.Exists(crystalId) then return end
	local profile = PlayerService.GetProfile(player)
	if not profile then return end

	local requiredLevel = crystalRequirements[crystalId] or math.huge
	if profile.Level < requiredLevel then
		player:SetAttribute("CrystalMessage", string.format("%s unlocks at level %d", crystalId, requiredLevel))
		return
	end

	if not CrystalService.OwnsCrystal(profile, crystalId) then
		CrystalService.UnlockCrystal(profile, crystalId)
	end
	if CrystalService.EquipCrystal(profile, crystalId) then
		PlayerService.Sync(player)
		player:SetAttribute("CrystalMessage", crystalId .. " equipped")
		remotes.XPChanged:FireClient(player, profile.Experience, profile.Level)
	end
end)

remotes.GetPlayerData.OnServerInvoke = function(player)
	return PlayerService.GetProfile(player)
end

remotes.GetQuestData.OnServerInvoke = function(player)
	local profile = PlayerService.GetProfile(player)
	if not profile then
		return { Active = {}, Completed = {}, Progress = {}, Definitions = QuestSystem.GetDefinitions() }
	end
	return {
		Active = profile.ActiveQuests,
		Completed = profile.CompletedQuests,
		Progress = profile.QuestProgress,
		Definitions = QuestSystem.GetDefinitions(),
	}
end

local function ensureWorldFolders()
	for _, name in ipairs({ "NPCs", "Islands", "Spawn" }) do
		local folder = Workspace:FindFirstChild(name)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = Workspace
		end
	end
	return Workspace.NPCs, Workspace.Islands, Workspace.Spawn
end

local function createIsland(islands, name, center, size)
	local island = islands:FindFirstChild(name)
	if island then return island end

	island = Instance.new("Model")
	island.Name = name
	island.Parent = islands
	island:SetAttribute("IslandId", name)

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = size
	ground.Position = center
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Parent = island

	local title = Instance.new("BillboardGui")
	title.Name = "IslandTitle"
	title.Size = UDim2.fromOffset(240, 60)
	title.StudsOffset = Vector3.new(0, 12, 0)
	title.AlwaysOnTop = true
	title.Parent = ground

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = name:gsub("Island", " Island")
	text.Font = Enum.Font.GothamBold
	text.TextSize = 26
	text.Parent = title

	return island
end

local function createSpawn(spawnFolder)
	if spawnFolder:FindFirstChild("StarterSpawn") then return end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StarterSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 3, 8)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = spawnFolder
end

local function createPortal(island, name, fromPosition, destination, requiredLevel)
	if island:FindFirstChild(name) then return end
	local portal = Instance.new("Part")
	portal.Name = name
	portal.Size = Vector3.new(6, 8, 2)
	portal.Position = fromPosition
	portal.Anchored = true
	portal.Material = Enum.Material.Neon
	portal.Parent = island
	portal:SetAttribute("RequiredLevel", requiredLevel or 1)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 60)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = portal
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = requiredLevel and ("Level " .. requiredLevel .. " required") or "Portal"
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Parent = gui

	local cooldown = {}
	portal.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not player or not root or cooldown[player] then return end
		local profile = PlayerService.GetProfile(player)
		if not profile or profile.Level < (requiredLevel or 1) then
			player:SetAttribute("PortalMessage", string.format("Reach level %d to use this portal", requiredLevel or 1))
			return
		end
		cooldown[player] = true
		root.CFrame = CFrame.new(destination)
		task.delay(1, function() cooldown[player] = nil end)
	end)
end

local function spawnQuestGiver(npcs)
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
		local questToStart
		if not QuestSystem.IsActive(profile, "FIRST_FIGHT") and not QuestSystem.IsCompleted(profile, "FIRST_FIGHT") then
			questToStart = "FIRST_FIGHT"
		elseif not QuestSystem.IsActive(profile, "CRYSTAL_POWER") and not QuestSystem.IsCompleted(profile, "CRYSTAL_POWER") then
			questToStart = "CRYSTAL_POWER"
		elseif profile.Level >= 3 and not QuestSystem.IsActive(profile, "HUNT_EMBERLINGS") and not QuestSystem.IsCompleted(profile, "HUNT_EMBERLINGS") then
			questToStart = "HUNT_EMBERLINGS"
		elseif profile.Level >= 6 and not QuestSystem.IsActive(profile, "TIDE_EXPEDITION") and not QuestSystem.IsCompleted(profile, "TIDE_EXPEDITION") then
			questToStart = "TIDE_EXPEDITION"
		elseif profile.Level >= 10 and not QuestSystem.IsActive(profile, "WIND_TRIAL") and not QuestSystem.IsCompleted(profile, "WIND_TRIAL") then
			questToStart = "WIND_TRIAL"
		end
		if questToStart then
			QuestService.Start(player, profile, questToStart)
			player:SetAttribute("QuestMessage", "Started: " .. QuestSystem.GetDefinition(questToStart).Name)
		else
			player:SetAttribute("QuestMessage", "No new quest available.")
		end
	end)
end

local function spawnEnemy(npcs, typeId, position, uniqueName)
	if npcs:FindFirstChild(uniqueName) then return end
	NPCService.CreateEnemy(typeId, position, npcs, function(model, config)
		local respawnTime = config.Respawn
		task.delay(respawnTime, function()
			if npcs.Parent then
				spawnEnemy(npcs, typeId, position, uniqueName)
			end
		end)
	end, uniqueName)
end

local npcs, islands, spawnFolder = ensureWorldFolders()
local starterIsland = createIsland(islands, "StarterIsland", Vector3.new(0, 0, 0), Vector3.new(120, 2, 120))
local tideIsland = createIsland(islands, "TideIsland", Vector3.new(170, 0, 0), Vector3.new(100, 2, 100))
createSpawn(spawnFolder)
createPortal(starterIsland, "TidePortal", Vector3.new(52, 5, 0), Vector3.new(120, 4, 0), 4)
createPortal(tideIsland, "StarterPortal", Vector3.new(118, 5, 0), Vector3.new(48, 4, 0), 1)

spawnQuestGiver(npcs)
spawnEnemy(npcs, "TrainingDummy", Vector3.new(0, 1, -12), "TrainingDummy")
spawnEnemy(npcs, "Emberling", Vector3.new(30, 1, -18), "EmberlingA")
spawnEnemy(npcs, "Emberling", Vector3.new(-30, 1, -18), "EmberlingB")
spawnEnemy(npcs, "Tidecrawler", Vector3.new(160, 1, -12), "TidecrawlerA")
spawnEnemy(npcs, "Tidecrawler", Vector3.new(190, 1, 15), "TidecrawlerB")
spawnEnemy(npcs, "Galewisp", Vector3.new(180, 1, 28), "GalewispA")

Players.PlayerAdded:Connect(function(player)
	local profile = PlayerService.Load(player)
	if profile and not QuestSystem.IsActive(profile, "FIRST_FIGHT") and not QuestSystem.IsCompleted(profile, "FIRST_FIGHT") then
		QuestService.Start(player, profile, "FIRST_FIGHT")
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	local profile = PlayerService.Load(player)
	if profile and not QuestSystem.IsActive(profile, "FIRST_FIGHT") and not QuestSystem.IsCompleted(profile, "FIRST_FIGHT") then
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
