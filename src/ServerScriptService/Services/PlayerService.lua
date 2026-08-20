local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeProfileStore = require(ReplicatedStorage.Modules.SafeProfileStore)
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local AchievementSystem = require(ReplicatedStorage.Modules.AchievementSystem)
local DailyBountyService = require(script.Parent.DailyBountyService)
local EconomyService = require(script.Parent.EconomyService)
local MovementConfig = require(ReplicatedStorage.Config.MovementConfig)

local PlayerService = {
	Profiles = setmetatable({}, { __mode = "k" }),
	CharacterConnections = setmetatable({}, { __mode = "k" }),
	HumanoidConnections = setmetatable({}, { __mode = "k" }),
	Operations = setmetatable({}, { __mode = "k" }),
	ProfileRevisions = setmetatable({}, { __mode = "k" }),
	Closing = setmetatable({}, { __mode = "k" }),
	LoadingByUserId = {},
	ShuttingDown = false,
}
local OPERATION_TIMEOUT = 10
local SAVE_SETTLE_ATTEMPTS = 3
local DEFAULT_CRYSTAL = "EMBER"
local BASE_WALK_SPEED = math.max(1, tonumber(MovementConfig.BaseWalkSpeed) or 16)
local MIN_WALK_SPEED = math.max(1, tonumber(MovementConfig.MinWalkSpeed) or 6)
local MAX_WALK_SPEED_BONUS = math.clamp(tonumber(MovementConfig.MaxWalkSpeedBonus) or 20, 0, 100)
local MIN_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MinSlowMultiplier) or 0.2, 0.01, 1)
local MAX_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MaxSlowMultiplier) or 1, MIN_SLOW_MULTIPLIER, 10)

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

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

local function releaseOperation(player)
	PlayerService.Operations[player] = nil
end

local function cleanupRemovedPlayer(player)
	if PlayerService.CharacterConnections[player] then
		PlayerService.CharacterConnections[player]:Disconnect()
		PlayerService.CharacterConnections[player] = nil
	end
	cleanupHumanoidConnections(player)
	PlayerService.Operations[player] = nil
	PlayerService.ProfileRevisions[player] = nil
	PlayerService.Closing[player] = nil
	PlayerService.Profiles[player] = nil
end

function PlayerService.GetProfile(player)
	if PlayerService.Closing[player] then return nil end
	return PlayerService.Profiles[player]
end

function PlayerService.Heal(player, amount)
	if not player or not player:IsA("Player") or not player.Parent or PlayerService.Closing[player] then return 0 end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return 0 end
	local safeAmount = tonumber(amount)
	if type(safeAmount) ~= "number" or safeAmount ~= safeAmount or safeAmount == math.huge or safeAmount == -math.huge or safeAmount <= 0 then return 0 end
	safeAmount = math.clamp(safeAmount, 0, 1000)
	local before = math.max(0, humanoid.Health)
	local maximum = math.max(1, humanoid.MaxHealth)
	humanoid.Health = math.min(maximum, before + safeAmount)
	local applied = math.max(0, humanoid.Health - before)
	player:SetAttribute("Health", math.max(0, humanoid.Health))
	player:SetAttribute("MaxHealth", maximum)
	return applied
end

function PlayerService.BeginShutdown()
	PlayerService.ShuttingDown = true
end

function PlayerService.GetPendingLoadCount()
	local count = 0
	for _ in pairs(PlayerService.LoadingByUserId) do count += 1 end
	return count
end

function PlayerService.Load(player)
	PlayerService.Closing[player] = nil
	if PlayerService.ShuttingDown then return nil, "Server is shutting down" end
	if PlayerService.Profiles[player] then return PlayerService.Profiles[player] end
	local userId = player.UserId
	local loadToken = {}
	PlayerService.LoadingByUserId[userId] = loadToken
	local function isCurrentLoad()
		return PlayerService.LoadingByUserId[userId] == loadToken
	end
	if PlayerService.ShuttingDown then
		if isCurrentLoad() then PlayerService.LoadingByUserId[userId] = nil end
		return nil, "Server is shutting down"
	end

	local profile, reason = SafeProfileStore.Load(player)
	if not profile then
		if isCurrentLoad() then PlayerService.LoadingByUserId[userId] = nil end
		player:SetAttribute("ProfileLoadFailed", reason or "Unable to load profile")
		warn(("Crystal Bound: refusing to create a fresh profile for %s because loading failed: %s"):format(player.Name, tostring(reason)))
		return nil, reason
	end

	if not isCurrentLoad() then
		warn(("Crystal Bound: superseded profile load ignored for UserId %d."):format(userId))
		return nil, "Superseded profile load"
	end
	if PlayerService.ShuttingDown or not player.Parent then
		PlayerService.LoadingByUserId[userId] = nil
		local released = SafeProfileStore.Release(player)
		warn(("Crystal Bound: player %s left/shutdown while profile loading; session lock release=%s."):format(player.Name, tostring(released)))
		return nil, PlayerService.ShuttingDown and "Server is shutting down" or "Player left before profile load completed"
	end

	profile = PlayerData.Reconcile(profile)
	if not isCurrentLoad() then
		warn(("Crystal Bound: superseded profile initialization ignored for UserId %d."):format(userId))
		return nil, "Superseded profile initialization"
	end
	if PlayerService.ShuttingDown then
		PlayerService.LoadingByUserId[userId] = nil
		local released = SafeProfileStore.Release(player)
		warn(("Crystal Bound: shutdown interrupted profile initialization for %s; session lock release=%s."):format(player.Name, tostring(released)))
		return nil, "Server is shutting down"
	end
	PlayerService.Profiles[player] = profile
	PlayerService.ProfileRevisions[player] = 0

	if not isCurrentLoad() then
		PlayerService.Profiles[player] = nil
		PlayerService.ProfileRevisions[player] = nil
		warn(("Crystal Bound: profile initialization was superseded for UserId %d."):format(userId))
		return nil, "Superseded profile initialization"
	end
	if PlayerService.ShuttingDown or not player.Parent then
		PlayerService.Profiles[player] = nil
		PlayerService.ProfileRevisions[player] = nil
		PlayerService.LoadingByUserId[userId] = nil
		local released = SafeProfileStore.Release(player)
		warn(("Crystal Bound: player %s left/shutdown during profile initialization; session lock release=%s."):format(player.Name, tostring(released)))
		return nil, PlayerService.ShuttingDown and "Server is shutting down" or "Player left during profile initialization"
	end

	PlayerService.LoadingByUserId[userId] = nil
	setupLeaderstats(player, profile)
	cleanupHumanoidConnections(player)
	if PlayerService.CharacterConnections[player] then PlayerService.CharacterConnections[player]:Disconnect() end
	PlayerService.CharacterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if not PlayerService.Profiles[player] or PlayerService.Closing[player] or player.Character ~= character or not character.Parent then return end
			local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
			if PlayerService.Closing[player] or player.Character ~= character or not character.Parent then return end
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
	local profile = PlayerService.Profiles[player]
	if not profile or PlayerService.Closing[player] then return end
	PlayerService.ProfileRevisions[player] = (PlayerService.ProfileRevisions[player] or 0) + 1
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
	local walkSpeedBonus = math.clamp((finiteNumber(passive.WalkSpeedBonus, 0) or 0) + (finiteNumber(masteryBonuses.WalkSpeedBonus, 0) or 0), 0, MAX_WALK_SPEED_BONUS)
	local maxHealthBonus = math.clamp((finiteNumber(passive.MaxHealthBonus, 0) or 0) + (finiteNumber(masteryBonuses.MaxHealthBonus, 0) or 0), 0, 1000)
	player:SetAttribute("Level", profile.Level)
	player:SetAttribute("Experience", profile.Experience)
	player:SetAttribute("Money", profile.Money)
	player:SetAttribute("EquippedCrystal", crystalId)
	player:SetAttribute("DamageMultiplier", (passive.DamageMultiplier or 1) * masteryBonuses.DamageMultiplier)
	player:SetAttribute("AbilityDamageMultiplier", masteryBonuses.AbilityDamageMultiplier)
	player:SetAttribute("WalkSpeedBonus", walkSpeedBonus)
	player:SetAttribute("MaxHealthBonus", maxHealthBonus)
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
		local baseWalkSpeed = BASE_WALK_SPEED + walkSpeedBonus
		local slowMultiplier = tonumber(humanoid:GetAttribute("CrystalBoundSlowMultiplier"))
		if type(slowMultiplier) == "number" and slowMultiplier == slowMultiplier and slowMultiplier ~= math.huge and slowMultiplier ~= -math.huge then
			slowMultiplier = math.clamp(slowMultiplier, MIN_SLOW_MULTIPLIER, MAX_SLOW_MULTIPLIER)
			humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, baseWalkSpeed * slowMultiplier)
		else
			humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, baseWalkSpeed)
		end
		local maxHealth = 100 + maxHealthBonus
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

local function saveConsistently(player, profile)
	if not profile then return false end
	local saved = false
	for attempt = 1, SAVE_SETTLE_ATTEMPTS do
		if PlayerService.Profiles[player] ~= profile then return false end
		PlayerService.Sync(player)
		local snapshotRevision = PlayerService.ProfileRevisions[player] or 0
		saved = SafeProfileStore.Save(player, profile) == true
		if not saved then return false end
		if (PlayerService.ProfileRevisions[player] or 0) == snapshotRevision then return true end
	end
	warn(("Crystal Bound: profile changed during all %d save-settle passes for %s; last consistent snapshot retained."):format(SAVE_SETTLE_ATTEMPTS, player.Name))
	return saved
end

function PlayerService.RefreshSession(player)
	if not PlayerService.Profiles[player] or PlayerService.Closing[player] then return false end
	if not acquireOperation(player) then return false end
	local success, result = xpcall(function()
		return SafeProfileStore.Refresh(player)
	end, debug.traceback)
	releaseOperation(player)
	if not success then
		warn(("Crystal Bound: PlayerService.RefreshSession failed for %s: %s"):format(player.Name, tostring(result)))
		return false
	end
	return result == true
end

function PlayerService.Save(player)
	if not PlayerService.Profiles[player] or PlayerService.Closing[player] then return false end
	if not acquireOperation(player) then return false end
	local success, result = xpcall(function()
		local profile = PlayerService.Profiles[player]
		return saveConsistently(player, profile)
	end, debug.traceback)
	releaseOperation(player)
	if not success then
		warn(("Crystal Bound: PlayerService.Save failed for %s: %s"):format(player.Name, tostring(result)))
		return false
	end
	player:SetAttribute("LastSaveOk", result == true)
	return result == true
end

function PlayerService.Remove(player)
	if not PlayerService.Profiles[player] then return true end
	if PlayerService.Closing[player] then return false end
	PlayerService.Closing[player] = true
	if not acquireOperation(player) then
		PlayerService.Closing[player] = nil
		return false
	end
	local success, result = xpcall(function()
		local profile = PlayerService.Profiles[player]
		if not profile then return { Saved = true } end
		local saved = saveConsistently(player, profile)
		player:SetAttribute("LastSaveOk", saved)
		if not saved then return { Saved = false } end
		local released = SafeProfileStore.Release(player)
		if not released then return { Saved = false, ReleaseFailed = true } end
		cleanupRemovedPlayer(player)
		return { Saved = true }
	end, debug.traceback)
	releaseOperation(player)

	if not success then
		warn(("Crystal Bound: PlayerService.Remove failed for %s: %s"):format(player.Name, tostring(result)))
		cleanupRemovedPlayer(player)
		return false
	end
	if not result or not result.Saved then
		if result and result.ReleaseFailed then
			warn(("Crystal Bound: retaining session lock for %s because final session-lock release failed."):format(player.Name))
		else
			warn(("Crystal Bound: retaining session lock for %s because final save failed."):format(player.Name))
		end
		cleanupRemovedPlayer(player)
		return false
	end
	return true
end

return PlayerService
