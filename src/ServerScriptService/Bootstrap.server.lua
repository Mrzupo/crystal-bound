local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerService = require(script.Parent.Services.PlayerService)
local CombatService = require(script.Parent.Services.CombatService)
local QuestService = require(script.Parent.Services.QuestService)
local CrystalService = require(script.Parent.Services.CrystalService)
local InventoryService = require(script.Parent.Services.InventoryService)
local EconomyService = require(script.Parent.Services.EconomyService)
local BossService = require(script.Parent.Services.BossService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local CrystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
local CrystalUpgradeConfig = require(ReplicatedStorage.Config.CrystalUpgradeConfig)
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)
local NPCService = require(script.Parent.Services.NPCService)

local AUTOSAVE_INTERVAL = 60
local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end
local function deepCopy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do
		result[key] = deepCopy(child)
	end
	return result
end
local NPC_INTERACTION_RANGE = math.clamp(finiteNumber(InteractionConfig.NPCInteractionRange, 14), 4, 50)
local QUEST_REQUEST_INTERVAL = 0.15
local INVENTORY_REQUEST_INTERVAL = 0.1
local CRYSTAL_REQUEST_INTERVAL = 0.12
local CRYSTAL_UPGRADE_INTERVAL = 0.25
local PLAYER_DATA_REQUEST_INTERVAL = 0.2
local QUEST_DATA_REQUEST_INTERVAL = 0.35
local nextQuestRequest = setmetatable({}, { __mode = "k" })
local nextInventoryRequest = setmetatable({}, { __mode = "k" })
local nextCrystalRequest = setmetatable({}, { __mode = "k" })
local nextCrystalUpgradeRequest = setmetatable({}, { __mode = "k" })
local nextPlayerDataRequest = setmetatable({}, { __mode = "k" })
local nextQuestDataRequest = setmetatable({}, { __mode = "k" })

local function ensureRemote(className, name)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local existing = remotes:FindFirstChild(name)
	if existing then
		if existing.ClassName ~= className then
			error(("Crystal Bound: Remote %s has class %s, expected %s"):format(name, existing.ClassName, className))
		end
		return existing
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes
	return remote
end

for _, name in ipairs({ "CombatRequest", "QuestRequest", "InventoryRequest", "XPChanged", "LevelUp", "MoneyChanged", "InventoryChanged", "CrystalChanged", "CrystalMasteryChanged", "CrystalUpgradeRequest" }) do
	ensureRemote("RemoteEvent", name)
end
ensureRemote("RemoteFunction", "GetPlayerData")
ensureRemote("RemoteFunction", "GetQuestData")
local remotes = ReplicatedStorage.Remotes

local function isNearNPC(player, npcName, range)
	local character = player.Character; local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = Workspace:FindFirstChild("NPCs"); local npc = folder and folder:FindFirstChild(npcName)
	local npcRoot = npc and (npc.PrimaryPart or npc:FindFirstChild("Torso"))
	local safeRange = finiteNumber(range, NPC_INTERACTION_RANGE)
	return root and npcRoot and (root.Position - npcRoot.Position).Magnitude <= math.clamp(safeRange, 4, 50)
end

remotes.CombatRequest.OnServerEvent:Connect(function(player, action, target) CombatService.HandleRequest(player, action, target) end)
remotes.QuestRequest.OnServerEvent:Connect(function(player, action, questId)
	local now = os.clock()
	if now < (nextQuestRequest[player] or 0) then return end
	nextQuestRequest[player] = now + QUEST_REQUEST_INTERVAL

	local profile = PlayerService.GetProfile(player)
	if profile and action == "Start" and type(questId) == "string" then
		if not isNearNPC(player, "CrystalKeeper") then
			player:SetAttribute("QuestMessage", "Talk to the Crystal Keeper to start a quest.")
			return
		end
		local started, reason = QuestSystem.CanStart(profile, questId)
		if started then QuestService.Start(player, profile, questId) else player:SetAttribute("QuestMessage", reason or "Quest cannot be started.") end
	end
end)

remotes.InventoryRequest.OnServerEvent:Connect(function(player, action, itemId, amount)
	local now = os.clock()
	if now < (nextInventoryRequest[player] or 0) then return end
	nextInventoryRequest[player] = now + INVENTORY_REQUEST_INTERVAL

	local profile = PlayerService.GetProfile(player); if not profile then return end
	if action == "Sell" and type(itemId) == "string" then
		if not isNearNPC(player, "MaterialTrader") then player:SetAttribute("ShopMessage", "You need to be near the Material Trader."); return end
		local ok, earned = EconomyService.SellItem(profile, itemId, amount or 1, InventoryService)
		if ok then PlayerService.Sync(player); remotes.MoneyChanged:FireClient(player, profile.Money); remotes.InventoryChanged:FireClient(player, InventoryService.GetInventory(profile)); player:SetAttribute("ShopMessage", string.format("Sold %s for %d Money", itemId, earned)) else player:SetAttribute("ShopMessage", "You do not have that item.") end
	else remotes.InventoryChanged:FireClient(player, InventoryService.GetInventory(profile)) end
end)

remotes.CrystalChanged.OnServerEvent:Connect(function(player, crystalId)
	local now = os.clock()
	if now < (nextCrystalRequest[player] or 0) then return end
	nextCrystalRequest[player] = now + CRYSTAL_REQUEST_INTERVAL
	if type(crystalId) ~= "string" or not CrystalSystem.Exists(crystalId) then return end
	local profile = PlayerService.GetProfile(player); if not profile then return end
	local requiredLevel = (CrystalConfig.UnlockLevels and CrystalConfig.UnlockLevels[crystalId]) or math.huge
	if profile.Level < requiredLevel then player:SetAttribute("CrystalMessage", string.format("%s unlocks at level %d", crystalId, requiredLevel)); return end
	if not CrystalService.OwnsCrystal(profile, crystalId) then CrystalService.UnlockCrystal(profile, crystalId) end
	if CrystalService.EquipCrystal(profile, crystalId) then local mastery = CrystalMastery.Get(profile, crystalId); PlayerService.Sync(player); player:SetAttribute("CrystalMessage", crystalId .. " equipped"); remotes.CrystalMasteryChanged:FireClient(player, crystalId, mastery.Level, mastery.XP) end
end)

remotes.CrystalUpgradeRequest.OnServerEvent:Connect(function(player, crystalId)
	local now = os.clock()
	if now < (nextCrystalUpgradeRequest[player] or 0) then return end
	nextCrystalUpgradeRequest[player] = now + CRYSTAL_UPGRADE_INTERVAL
	if type(crystalId) ~= "string" or not CrystalSystem.Exists(crystalId) then return end
	if not isNearNPC(player, "CrystalKeeper") then player:SetAttribute("CrystalMessage", "Go to the Crystal Keeper to upgrade your crystal."); return end
	local profile = PlayerService.GetProfile(player); if not profile or not CrystalService.OwnsCrystal(profile, crystalId) then return end
	local mastery = CrystalMastery.Get(profile, crystalId); if mastery.Level >= CrystalUpgradeConfig.MaxLevel then player:SetAttribute("CrystalMessage", crystalId .. " mastery is already maxed."); return end
	local cost = CrystalMastery.GetUpgradeCost(profile, crystalId)
	if type(cost) ~= "table" then
		player:SetAttribute("CrystalMessage", "Crystal upgrade configuration is unavailable.")
		return
	end
	for itemId, amount in pairs(cost) do if not InventoryService.HasItem(profile, itemId, amount) then player:SetAttribute("CrystalMessage", string.format("Need %d %s to upgrade.", amount, itemId)); return end end
	local removed = {}
	for itemId, amount in pairs(cost) do
		if not InventoryService.RemoveItem(profile, itemId, amount) then
			for rollbackId, rollbackAmount in pairs(removed) do InventoryService.AddItem(profile, rollbackId, rollbackAmount) end
			player:SetAttribute("CrystalMessage", "Crystal upgrade could not consume all materials safely.")
			return
		end
		removed[itemId] = amount
	end
	local upgraded, newLevel = CrystalMastery.Upgrade(profile, crystalId)
	if not upgraded then
		for itemId, amount in pairs(removed) do InventoryService.AddItem(profile, itemId, amount) end
		return
	end
	PlayerService.Sync(player); remotes.InventoryChanged:FireClient(player, InventoryService.GetInventory(profile)); remotes.CrystalMasteryChanged:FireClient(player, crystalId, newLevel, 0); player:SetAttribute("CrystalMessage", string.format("%s mastery upgraded to Lv. %d", crystalId, newLevel))
end)

remotes.GetPlayerData.OnServerInvoke = function(player)
	local now = os.clock()
	if now < (nextPlayerDataRequest[player] or 0) then return nil end
	nextPlayerDataRequest[player] = now + PLAYER_DATA_REQUEST_INTERVAL
	local profile = PlayerService.GetProfile(player)
	if not profile then return nil end
	return deepCopy({ Level = profile.Level, Experience = profile.Experience, Money = profile.Money, Crystals = profile.Crystals, CrystalMastery = profile.CrystalMastery, Inventory = profile.Inventory, Achievements = profile.Achievements, Titles = profile.Titles })
end

remotes.GetQuestData.OnServerInvoke = function(player)
	local now = os.clock()
	if now < (nextQuestDataRequest[player] or 0) then return nil end
	nextQuestDataRequest[player] = now + QUEST_DATA_REQUEST_INTERVAL
	local profile = PlayerService.GetProfile(player)
	if not profile then return { Active = {}, Completed = {}, Progress = {}, Definitions = deepCopy(QuestSystem.GetDefinitions()) } end
	return deepCopy({ Active = profile.ActiveQuests, Completed = profile.CompletedQuests, Progress = profile.QuestProgress, Definitions = QuestSystem.GetDefinitions() })
end

local function ensureWorldFolders() for _, name in ipairs({ "NPCs", "Islands", "Spawn" }) do local folder = Workspace:FindFirstChild(name); if not folder then folder = Instance.new("Folder"); folder.Name = name; folder.Parent = Workspace end end; return Workspace.NPCs, Workspace.Islands, Workspace.Spawn end
local function createIsland(islands, name, center, size)
	local island = islands:FindFirstChild(name); if island then return island end
	island = Instance.new("Model"); island.Name = name; island.Parent = islands; island:SetAttribute("IslandId", name)
	local ground = Instance.new("Part"); ground.Name = "Ground"; ground.Size = size; ground.Position = center; ground.Anchored = true; ground.Material = name == "WindIsland" and Enum.Material.Slate or name == "AncientRuins" and Enum.Material.Rock or Enum.Material.Grass; ground.Parent = island
	local title = Instance.new("BillboardGui"); title.Name = "IslandTitle"; title.Size = UDim2.fromOffset(240, 60); title.StudsOffset = Vector3.new(0, 12, 0); title.AlwaysOnTop = true; title.Parent = ground
	local text = Instance.new("TextLabel"); text.Size = UDim2.fromScale(1, 1); text.BackgroundTransparency = 1; text.Text = name:gsub("Island", " Island"); text.Font = Enum.Font.GothamBold; text.TextSize = 26; text.Parent = title; return island
end
local function createSpawn(spawnFolder) if spawnFolder:FindFirstChild("StarterSpawn") then return end; local spawn = Instance.new("SpawnLocation"); spawn.Name="StarterSpawn"; spawn.Size=Vector3.new(8,1,8); spawn.Position=Vector3.new(0,3,8); spawn.Anchored=true; spawn.Neutral=true; spawn.Parent=spawnFolder end
local function createPortal(island, name, fromPosition, destination, requiredLevel)
	if island:FindFirstChild(name) then return end
	local portal=Instance.new("Part"); portal.Name=name; portal.Size=Vector3.new(6,8,2); portal.Position=fromPosition; portal.Anchored=true; portal.Material=Enum.Material.Neon; portal.Parent=island
	local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(260,60); gui.StudsOffset=Vector3.new(0,6,0); gui.AlwaysOnTop=true; gui.Parent=portal
	local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text="Level "..tostring(requiredLevel or 1).." required"; label.Font=Enum.Font.GothamBold; label.TextSize=18; label.Parent=gui
end
local function spawnSimpleNPC(npcs,name,position,objectText,actionText,callback)
	if npcs:FindFirstChild(name) then return end
	local model=Instance.new("Model"); model.Name=name; model:SetAttribute("Interactable",true); model.Parent=npcs
	local body=Instance.new("Part"); body.Name="Torso"; body.Size=Vector3.new(3,4,2); body.Position=position; body.Anchored=true; body.Parent=model
	local head=Instance.new("Part"); head.Name="Head"; head.Shape=Enum.PartType.Ball; head.Size=Vector3.new(2,2,2); head.Position=position+Vector3.new(0,3,0); head.Anchored=true; head.Parent=model
	model.PrimaryPart=body; local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=actionText; prompt.ObjectText=objectText; prompt.MaxActivationDistance=12; prompt.Parent=body; prompt.Triggered:Connect(callback)
end
local function spawnQuestGiver(npcs) spawnSimpleNPC(npcs,"CrystalKeeper",Vector3.new(12,3,-2),"Crystal Keeper","Talk",function() end) end
local function spawnTrader(npcs) spawnSimpleNPC(npcs,"MaterialTrader",Vector3.new(20,3,10),"Material Trader","Talk",function() end) end
local function spawnEnemy(npcs,typeId,position,uniqueName) if npcs:FindFirstChild(uniqueName) then return end; NPCService.CreateEnemy(typeId,position,npcs,function(_,config) task.delay(config.Respawn,function() if npcs.Parent then spawnEnemy(npcs,typeId,position,uniqueName) end end,uniqueName) end,uniqueName) end

local npcs,islands,spawnFolder=ensureWorldFolders()
local worldIslands = WorldConfig.Islands
local starterConfig, tideConfig, windConfig, ancientConfig = worldIslands.STARTER, worldIslands.TIDE, worldIslands.WIND, worldIslands.ANCIENT
local starterIsland=createIsland(islands,"StarterIsland",starterConfig.Center,starterConfig.Size)
local tideIsland=createIsland(islands,"TideIsland",tideConfig.Center,tideConfig.Size)
local windIsland=createIsland(islands,"WindIsland",windConfig.Center,windConfig.Size)
local ancientIsland=createIsland(islands,"AncientRuins",ancientConfig.Center,ancientConfig.Size)
createSpawn(spawnFolder)
createPortal(starterIsland,"TidePortal",Vector3.new(52,5,0),Vector3.new(120,4,0),tideConfig.Level)
createPortal(tideIsland,"StarterPortal",Vector3.new(118,5,0),Vector3.new(48,4,0),starterConfig.Level)
createPortal(tideIsland,"WindPortal",Vector3.new(218,5,0),Vector3.new(280,4,0),windConfig.Level)
createPortal(windIsland,"TideReturnPortal",Vector3.new(278,5,0),Vector3.new(210,4,0),tideConfig.Level)
createPortal(windIsland,"AncientPortal",Vector3.new(390,5,0),Vector3.new(440,4,0),ancientConfig.Level)
createPortal(ancientIsland,"WindReturnPortal",Vector3.new(440,5,50),Vector3.new(380,4,0),windConfig.Level)
spawnQuestGiver(npcs); spawnTrader(npcs); spawnEnemy(npcs,"TrainingDummy",Vector3.new(0,1,-12),"TrainingDummy"); spawnEnemy(npcs,"Emberling",Vector3.new(30,1,-18),"EmberlingA"); spawnEnemy(npcs,"Emberling",Vector3.new(-30,1,-18),"EmberlingB"); spawnEnemy(npcs,"Tidecrawler",Vector3.new(160,1,-12),"TidecrawlerA"); spawnEnemy(npcs,"Tidecrawler",Vector3.new(190,1,15),"TidecrawlerB"); spawnEnemy(npcs,"Galewisp",Vector3.new(300,1,-18),"GalewispA"); spawnEnemy(npcs,"CrystalBat",Vector3.new(320,1,16),"CrystalBatA"); spawnEnemy(npcs,"AncientGolem",Vector3.new(455,1,0),"AncientGolemA")

local function syncAllPlayerData()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerService.GetProfile(player)
		if profile then PlayerService.Sync(player) end
	end
end

local function loadPlayer(player)
	local profile, reason = PlayerService.Load(player)
	if not profile then
		if player.Parent then player:Kick(reason or "Unable to load your Crystal Bound profile safely.") end
		return false
	end
	PlayerService.Sync(player)
	return true
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, player)
end
