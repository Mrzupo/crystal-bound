local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeProfileStore = require(ReplicatedStorage.Modules.SafeProfileStore)
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local AchievementSystem = require(ReplicatedStorage.Modules.AchievementSystem)
local DailyBountyService = require(script.Parent.DailyBountyService)
local EconomyService = require(script.Parent.EconomyService)
local MovementConfig = require(ReplicatedStorage.Config.MovementConfig)

local PlayerService = { Profiles = {}, CharacterConnections = {}, HumanoidConnections = {}, Operations = {} }
local OPERATION_TIMEOUT = 10
local DEFAULT_CRYSTAL = "EMBER"
local BASE_WALK_SPEED = math.max(1, tonumber(MovementConfig.BaseWalkSpeed) or 16)
local MIN_WALK_SPEED = math.max(1, tonumber(MovementConfig.MinWalkSpeed) or 6)
local MIN_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MinSlowMultiplier) or 0.2, 0.01, 1)
local MAX_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MaxSlowMultiplier) or 1, MIN_SLOW_MULTIPLIER, 10)

local function setupLeaderstats(player, profile)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local level = leaderstats:FindFirstChild("Level") or Instance.new("IntValue")
	level.Name = "Level"; level.Value = profile.Level; level.Parent = leaderstats
	local money = leaderstats:FindFirstChild("Money") or Instance.new("IntValue")
	money.Name = "Money"; money.Value = profile.Money; money.Parent = leaderstats
end

local function cleanupHumanoidConnections(player)
	local connections = PlayerService.HumanoidConnections[player]
	if not connections then return end
	for _, connection in ipairs(connections) do
		if connection.Connected then connection:Disconnect() end
	end
	PlayerService.HumanoidConnections[player] = nil
end

local function ensureAnimator(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function bindHumanoid(player, humanoid)
	cleanupHumanoidConnections(player)
	if not humanoid then return end
	local connections = {}
	PlayerService.HumanoidConnections[player] = connections
	local function updateHealth()
		if not player.Parent or not humanoid.Parent then return end
		player:SetAttribute("Health", math.max(0, humanoid.Health))
		player:SetAttribute("MaxHealth", math.max(1, humanoid.MaxHealth))
	end
	table.insert(connections, humanoid.HealthChanged:Connect(updateHealth))
	table.insert(connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth))
	table.insert(connections, humanoid.Died:Connect(function()
		if player.Parent then
			player:SetAttribute("Health", 0)
			player:SetAttribute("DeathMessage", "You were defeated. Respawning...")
		end
	end))
	updateHealth()
end

local function syncTitleTag(character, title)
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local tag = head:FindFirstChild("CrystalBoundTitle")
	if title == "" then
		if tag then tag:Destroy() end
		return
	end
	local expectedText = "< " .. title .. " >"
	local label = tag and tag:FindFirstChild("Label")
	if tag and label and label:IsA("TextLabel") and label.Text == expectedText then return end
	if tag then tag:Destroy() end
	tag = Instance.new("BillboardGui")
	tag.Name = "CrystalBoundTitle"
	tag.Size = UDim2.fromOffset(240, 34)
	tag.StudsOffset = Vector3.new(0, 2.8, 0)
	tag.AlwaysOnTop = true
	tag.Parent = head
	label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = expectedText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.Parent = tag
end

local function acquireOperation(player)
	local started = os.clock()
	while PlayerService.Operations[player] do
		if os.clock() - started >= OPERATION_TIMEOUT then return false end
		task.wait(0.05)
	end
	PlayerService.Operations[player] = true
	return true
end

local function releaseOperation(player) PlayerService.Operations[player] = nil end

function PlayerService.GetProfile(player) return PlayerService.Profiles[player] end

function PlayerService.Load(player)
	if PlayerService.Profiles[player] then return PlayerService.Profiles[player] end
	local profile, reason = SafeProfileStore.Load(player)
	if not profile then
		player:SetAttribute("ProfileLoadFailed", reason or "Unable to load profile")
		warn(("Crystal Bound: refusing to create a fresh profile for %s because loading failed: %s"):format(player.Name, tostring(reason)))
		return nil, reason
	end

	profile = PlayerData.Reconcile(profile)
	PlayerService.Profiles[player] = profile
	setupLeaderstats(player, profile)
	cleanupHumanoidConnections(player)
	if PlayerService.CharacterConnections[player] then PlayerService.CharacterConnections[player]:Disconnect() end
	PlayerService.CharacterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if not PlayerService.Profiles[player] then return end
			local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
			if humanoid then ensureAnimator(character) end
			PlayerService.Sync(player)
			bindHumanoid(player, humanoid)
			player:SetAttribute("DeathMessage", "")
		end)
	end)
	PlayerService.Sync(player)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then ensureAnimator(player.Character) end
		bindHumanoid(player, humanoid)
	end
	return profile
end

function PlayerService.Sync(player)
	local profile = PlayerService.Profiles[player]; if not profile then return end
	local newlyUnlocked = AchievementSystem.Check(profile)
	for _, definition in ipairs(newlyUnlocked) do
		EconomyService.AddMoney(profile, definition.RewardMoney or 0)
		player:SetAttribute("AchievementMessage", "Achievement unlocked: " .. definition.Name)
	end
	local bounty = DailyBountyService.Refresh(profile)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level"); local money = leaderstats:FindFirstChild("Money")
		if level then level.Value = profile.Level end
		if money then money.Value = profile.Money end
	end
	local crystalId = CrystalSystem.GetEquipped(profile) or DEFAULT_CRYSTAL
	if profile.Crystals.Equipped ~= crystalId then profile.Crystals.Equipped = crystalId end
	local passive = CrystalSystem.GetPassive(crystalId)
	local mastery = CrystalMastery.Get(profile, crystalId)
	local masteryBonuses = CrystalMastery.GetBonuses(profile, crystalId)
	local title = (profile.Titles and profile.Titles[#profile.Titles]) or ""
	player:SetAttribute("Level", profile.Level)
	player:SetAttribute("Experience", profile.Experience)
	player:SetAttribute("Money", profile.Money)
	player:SetAttribute("EquippedCrystal", crystalId)
	player:SetAttribute("DamageMultiplier", (passive.DamageMultiplier or 1) * masteryBonuses.DamageMultiplier)
	player:SetAttribute("AbilityDamageMultiplier", masteryBonuses.AbilityDamageMultiplier)
	player:SetAttribute("WalkSpeedBonus", (passive.WalkSpeedBonus or 0) + masteryBonuses.WalkSpeedBonus)
	player:SetAttribute("MaxHealthBonus", (passive.MaxHealthBonus or 0) + masteryBonuses.MaxHealthBonus)
	player:SetAttribute("CrystalMasteryLevel", mastery.Level)
	player:SetAttribute("CrystalMasteryXP", mastery.XP)
	player:SetAttribute("EnemiesDefeated", (profile.Stats and profile.Stats.EnemiesDefeated) or 0)
	player:SetAttribute("BossesDefeated", (profile.Stats and profile.Stats.BossesDefeated) or 0)
	player:SetAttribute("AchievementCount", #(profile.Achievements or {}))
	player:SetAttribute("Title", title)
	player:SetAttribute("DailyBountyEnemy", bounty.EnemyType)
	player:SetAttribute("DailyBountyProgress", bounty.Progress)
	player:SetAttribute("DailyBountyGoal", bounty.Goal)
	player:SetAttribute("DailyBountyReward", bounty.RewardMoney)
	player:SetAttribute("DailyBountyClaimed", bounty.Claimed)

	local owned = profile.Crystals and profile.Crystals.Owned or {}
	for _, id in ipairs({ "EMBER", "TIDE", "GALE" }) do player:SetAttribute("Owns_" .. id, table.find(owned, id) ~= nil) end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		ensureAnimator(character)
		local baseWalkSpeed = BASE_WALK_SPEED + (passive.WalkSpeedBonus or 0) + masteryBonuses.WalkSpeedBonus
		local slowMultiplier = tonumber(humanoid:GetAttribute("CrystalBoundSlowMultiplier"))
		if type(slowMultiplier) == "number" and slowMultiplier == slowMultiplier and slowMultiplier ~= math.huge and slowMultiplier ~= -math.huge then
			slowMultiplier = math.clamp(slowMultiplier, MIN_SLOW_MULTIPLIER, MAX_SLOW_MULTIPLIER)
			humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, baseWalkSpeed * slowMultiplier)
		else
			humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, baseWalkSpeed)
		end
		local maxHealth = 100 + (passive.MaxHealthBonus or 0) + masteryBonuses.MaxHealthBonus
		local oldMax = math.max(1, humanoid.MaxHealth)
		local oldHealth = humanoid.Health
		humanoid.MaxHealth = maxHealth
		if oldHealth > 0 then
			if oldMax ~= maxHealth then humanoid.Health = math.clamp((oldHealth / oldMax) * maxHealth, 1, maxHealth)
			elseif oldHealth > maxHealth then humanoid.Health = maxHealth end
		end
		player:SetAttribute("Health", math.max(0, humanoid.Health))
		player:SetAttribute("MaxHealth", maxHealth)
	end
	syncTitleTag(character, title)
end

function PlayerService.Save(player)
	if not PlayerService.Profiles[player] then return false end
	if not acquireOperation(player) then return false end
	local ok = false
	local profile = PlayerService.Profiles[player]
	if profile then
		PlayerService.Sync(player)
		ok = SafeProfileStore.Save(player, profile) == true
		player:SetAttribute("LastSaveOk", ok)
	end
	releaseOperation(player)
	return ok
end

function PlayerService.Remove(player)
	if not PlayerService.Profiles[player] then return true end
	if not acquireOperation(player) then return false end
	local profile = PlayerService.Profiles[player]
	if not profile then releaseOperation(player); return true end
	PlayerService.Sync(player)
	local saved = SafeProfileStore.Save(player, profile) == true
	player:SetAttribute("LastSaveOk", saved)
	if not saved then
		warn(("Crystal Bound: retaining session lock for %s because final save failed."):format(player.Name))
		if PlayerService.CharacterConnections[player] then PlayerService.CharacterConnections[player]:Disconnect(); PlayerService.CharacterConnections[player] = nil end
		cleanupHumanoidConnections(player)
		PlayerService.Profiles[player] = nil
		releaseOperation(player)
		return false
	end

	SafeProfileStore.Release(player)
	if PlayerService.CharacterConnections[player] then PlayerService.CharacterConnections[player]:Disconnect(); PlayerService.CharacterConnections[player] = nil end
	cleanupHumanoidConnections(player)
	PlayerService.Profiles[player] = nil
	releaseOperation(player)
	return true
end

return PlayerService
