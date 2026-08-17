local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SaveSystem = require(ReplicatedStorage.Modules.SaveSystem)
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local AchievementSystem = require(ReplicatedStorage.Modules.AchievementSystem)

local PlayerService = { Profiles = {}, CharacterConnections = {} }

local function setupLeaderstats(player, profile)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local level = leaderstats:FindFirstChild("Level") or Instance.new("IntValue")
	level.Name = "Level"; level.Value = profile.Level; level.Parent = leaderstats
	local money = leaderstats:FindFirstChild("Money") or Instance.new("IntValue")
	money.Name = "Money"; money.Value = profile.Money; money.Parent = leaderstats
end

local function bindHumanoid(player, humanoid)
	if not humanoid then return end
	local function updateHealth()
		player:SetAttribute("Health", math.max(0, humanoid.Health))
		player:SetAttribute("MaxHealth", math.max(1, humanoid.MaxHealth))
	end
	humanoid.HealthChanged:Connect(updateHealth)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
	humanoid.Died:Connect(function()
		player:SetAttribute("Health", 0)
		player:SetAttribute("DeathMessage", "You were defeated. Respawning...")
	end)
	updateHealth()
end

function PlayerService.GetProfile(player) return PlayerService.Profiles[player] end

function PlayerService.Load(player)
	if PlayerService.Profiles[player] then return PlayerService.Profiles[player] end
	local profile = PlayerData.Reconcile(SaveSystem.Load(player))
	PlayerService.Profiles[player] = profile
	setupLeaderstats(player, profile)
	if PlayerService.CharacterConnections[player] then PlayerService.CharacterConnections[player]:Disconnect() end
	PlayerService.CharacterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if not PlayerService.Profiles[player] then return end
			local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
			PlayerService.Sync(player)
			bindHumanoid(player, humanoid)
			player:SetAttribute("DeathMessage", "")
		end)
	end)
	PlayerService.Sync(player)
	if player.Character then bindHumanoid(player, player.Character:FindFirstChildOfClass("Humanoid")) end
	return profile
end

function PlayerService.Sync(player)
	local profile = PlayerService.Profiles[player]; if not profile then return end
	local newlyUnlocked = AchievementSystem.Check(profile)
	for _, definition in ipairs(newlyUnlocked) do
		profile.Money = math.min(1000000, (profile.Money or 0) + (definition.RewardMoney or 0))
		player:SetAttribute("AchievementMessage", "Achievement unlocked: " .. definition.Name)
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local level = leaderstats:FindFirstChild("Level"); local money = leaderstats:FindFirstChild("Money")
		if level then level.Value = profile.Level end; if money then money.Value = profile.Money end
	end
	local crystalId = profile.Crystals.Equipped
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

	local owned = profile.Crystals and profile.Crystals.Owned or {}
	for _, id in ipairs({ "EMBER", "TIDE", "GALE" }) do
		player:SetAttribute("Owns_" .. id, table.find(owned, id) ~= nil)
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 + (passive.WalkSpeedBonus or 0) + masteryBonuses.WalkSpeedBonus
		local maxHealth = 100 + (passive.MaxHealthBonus or 0) + masteryBonuses.MaxHealthBonus
		local oldMax = humanoid.MaxHealth
		humanoid.MaxHealth = maxHealth
		if humanoid.Health > 0 and (humanoid.Health == oldMax or humanoid.Health > maxHealth) then humanoid.Health = maxHealth end
		player:SetAttribute("Health", math.max(0, humanoid.Health))
		player:SetAttribute("MaxHealth", maxHealth)
	end
	local head = character and character:FindFirstChild("Head")
	if head then
		local tag = head:FindFirstChild("CrystalBoundTitle"); if tag then tag:Destroy() end
		if title ~= "" then
			tag = Instance.new("BillboardGui"); tag.Name = "CrystalBoundTitle"; tag.Size = UDim2.fromOffset(240, 34); tag.StudsOffset = Vector3.new(0, 2.8, 0); tag.AlwaysOnTop = true; tag.Parent = head
			local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1; label.Text = "< " .. title .. " >"; label.Font = Enum.Font.GothamBold; label.TextSize = 15; label.Parent = tag
		end
	end
end

function PlayerService.Save(player)
	local profile = PlayerService.Profiles[player]; if not profile then return false end
	PlayerService.Sync(player); return SaveSystem.Save(player, profile)
end
function PlayerService.Remove(player)
	PlayerService.Save(player)
	if PlayerService.CharacterConnections[player] then PlayerService.CharacterConnections[player]:Disconnect(); PlayerService.CharacterConnections[player] = nil end
	PlayerService.Profiles[player] = nil
end
return PlayerService
