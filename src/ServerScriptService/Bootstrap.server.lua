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
local loadingPlayers = setmetatable({}, { __mode = "k" })

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
	if action == "Start" and player:GetAttribute("ProfileLoaded") ~= true then return end

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
		if player:GetAttribute("ProfileLoaded") ~= true then return end
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
	if player:GetAttribute("ProfileLoaded") ~= true then return end
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
	if player:GetAttribute("ProfileLoaded") ~= true then return end
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
	if player:GetAttribute("ProfileLoaded") ~= true then return nil end
	local profile = PlayerService.GetProfile(player)
	if not profile then return nil end
	return deepCopy({ Level = profile.Level, Experience = profile.Experience, Money = profile.Money, Crystals = profile.Crystals, CrystalMastery = profile.CrystalMastery, Inventory = profile.Inventory, Achievements = profile.Achievements, Titles = profile.Titles })
end

remotes.GetQuestData.OnServerInvoke = function(player)
	local now = os.clock()
	if now < (nextQuestDataRequest[player] or 0) then return nil end
	nextQuestDataRequest[player] = now + QUEST_DATA_REQUEST_INTERVAL
	if player:GetAttribute("ProfileLoaded") ~= true then return nil end
	local profile = PlayerService.GetProfile(player)
	if not profile then return nil end
	return deepCopy({ Active = profile.ActiveQuests, Completed = profile.CompletedQuests, Progress = profile.QuestProgress, Definitions = QuestSystem.GetDefinitions() })
end

local function ensureWorldFolders() for _, name in ipairs({ "NPCs", "Islands", "Spawn" }) do local folder = Workspace:FindFirstChild(name); if not folder then folder = Instance.new("Folder"); folder.Name = name; folder.Parent = Workspace end end; return Workspace.NPCs, Workspace.Islands, Workspace.Spawn end
local function createIsland(islands, name, center, size)
	local island = islands:FindFirstChild(name)
	if island and not island:IsA("Model") then island:Destroy(); island = nil end
	island = island or Instance.new("Model")
	island.Name = name
	island.Parent = islands
	island:SetAttribute("IslandId", name)

	local ground = island:FindFirstChild("Ground")
	if ground and not ground:IsA("Part") then ground:Destroy(); ground = nil end
	ground = ground or Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = size
	ground.Position = center
	ground.Anchored = true
	ground.CanCollide = true
	ground.CanTouch = true
	ground.CanQuery = true
	ground.Material = name == "WindIsland" and Enum.Material.Slate or name == "AncientRuins" and Enum.Material.Rock or name == "TideIsland" and Enum.Material.Sand or Enum.Material.Grass
	ground.Parent = island

	local title = ground:FindFirstChild("IslandTitle")
	if title and not title:IsA("BillboardGui") then title:Destroy(); title = nil end
	title = title or Instance.new("BillboardGui")
	title.Name = "IslandTitle"
	title.Size = UDim2.fromOffset(240, 60)
	title.StudsOffset = Vector3.new(0, 12, 0)
	title.AlwaysOnTop = true
	title.Parent = ground
	local text = title:FindFirstChild("Text")
	if text and not text:IsA("TextLabel") then text:Destroy(); text = nil end
	text = text or Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = name:gsub("Island", " Island")
	text.Font = Enum.Font.GothamBold
	text.TextSize = 26
	text.Parent = title
	return island
end
local function createSpawn(spawnFolder)
	local spawn = spawnFolder:FindFirstChild("StarterSpawn")
	if spawn and not spawn:IsA("SpawnLocation") then spawn:Destroy(); spawn = nil end
	spawn = spawn or Instance.new("SpawnLocation")
	spawn.Name="StarterSpawn"
	spawn.Size=Vector3.new(8,1,8)
	spawn.Position=Vector3.new(0,3,8)
	spawn.Anchored=true
	spawn.Neutral=true
	spawn.CanCollide=true
	spawn.CanTouch=true
	spawn.Parent=spawnFolder
end
local function createPortal(island, name, fromPosition, destination, requiredLevel)
	local existing = island:FindFirstChild(name)
	if existing and not existing:IsA("BasePart") then existing:Destroy(); existing=nil end
	local portal = existing or Instance.new("Part")
	portal.Name=name
	portal.Size=Vector3.new(6,8,2)
	portal.Position=fromPosition
	portal.Anchored=true
	portal.CanCollide=false
	portal.CanTouch=true
	portal.CanQuery=true
	portal.Material=Enum.Material.Neon
	portal.Parent=island
	local gui=portal:FindFirstChild("PortalLabel")
	if gui and not gui:IsA("BillboardGui") then gui:Destroy(); gui=nil end
	gui=gui or Instance.new("BillboardGui")
	gui.Name="PortalLabel"
	gui.Size=UDim2.fromOffset(260,60)
	gui.StudsOffset=Vector3.new(0,6,0)
	gui.AlwaysOnTop=true
	gui.Parent=portal
	local label=gui:FindFirstChild("Text")
	if label and not label:IsA("TextLabel") then label:Destroy(); label=nil end
	label=label or Instance.new("TextLabel")
	label.Name="Text"
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Text="Level "..tostring(requiredLevel or 1).." required"
	label.Font=Enum.Font.GothamBold
	label.TextSize=18
	label.Parent=gui
end
local function spawnSimpleNPC(npcs,name,position,objectText,actionText,callback)
	local model=npcs:FindFirstChild(name)
	if model and not model:IsA("Model") then model:Destroy(); model=nil end
	local body = model and model:FindFirstChild("Torso")
	local head = model and model:FindFirstChild("Head")
	local prompt = body and body:FindFirstChildOfClass("ProximityPrompt")
	local valid = model and body and body:IsA("Part") and head and head:IsA("Part") and prompt and prompt:IsA("ProximityPrompt") and model.PrimaryPart == body
	if not valid then
		if model then model:Destroy() end
		model=Instance.new("Model")
		model.Name=name
		model.Parent=npcs
		body=Instance.new("Part")
		body.Name="Torso"
		body.Parent=model
		head=Instance.new("Part")
		head.Name="Head"
		head.Shape=Enum.PartType.Ball
		head.Parent=model
		model.PrimaryPart=body
		prompt=Instance.new("ProximityPrompt")
		prompt.Parent=body
		prompt.Triggered:Connect(callback)
	end
	model:SetAttribute("Interactable",true)
	body.Size=Vector3.new(3,4,2)
	body.Position=position
	body.Anchored=true
	head.Size=Vector3.new(2,2,2)
	head.Position=position+Vector3.new(0,3,0)
	head.Anchored=true
	model.PrimaryPart=body
	prompt.ActionText=actionText
	prompt.ObjectText=objectText
	prompt.MaxActivationDistance=12
	prompt.Enabled=true
end
local function spawnQuestGiver(npcs) spawnSimpleNPC(npcs,"CrystalKeeper",Vector3.new(12,3,-2),"Crystal Keeper","Talk",function() end) end
local function spawnTrader(npcs) spawnSimpleNPC(npcs,"MaterialTrader",Vector3.new(20,3,10),"Material Trader","Talk",function() end) end
local function spawnEnemy(npcs,typeId,position,uniqueName)
	if PlayerService.ShuttingDown or npcs:FindFirstChild(uniqueName) then return end
	NPCService.CreateEnemy(typeId,position,npcs,function(_,config)
		task.delay(config.Respawn,function()
			if not PlayerService.ShuttingDown and npcs.Parent then spawnEnemy(npcs,typeId,position,uniqueName) end
		end,uniqueName)
	end,uniqueName)
end

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
	if loadingPlayers[player] then return false end
	loadingPlayers[player] = true
	local success, profile, reason = xpcall(function()
		return PlayerService.Load(player)
	end, debug.traceback)
	loadingPlayers[player] = nil
	if not success then
		warn(("Crystal Bound: profile load crashed for %s: %s"):format(player.Name, tostring(profile)))
		if player.Parent then player:Kick("Unable to load your Crystal Bound profile safely.") end
		return false
	end
	if not profile then
		if player.Parent then player:Kick(reason or "Unable to load your Crystal Bound profile safely.") end
		return false
	end
	return true
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, player)
end
