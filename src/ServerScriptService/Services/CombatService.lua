local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local DamageService = require(script.Parent.DamageService)
local PlayerService = require(script.Parent.PlayerService)
local XPService = require(script.Parent.XPService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local QuestService = require(script.Parent.QuestService)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local CombatService = {}
local cooldowns = {}

local CRYSTAL_COLORS = {
	EMBER = Color3.fromRGB(255, 90, 35),
	TIDE = Color3.fromRGB(45, 150, 255),
	GALE = Color3.fromRGB(170, 120, 255),
}

local VALID_ACTIONS = {
	Basic = true,
	Ability = true,
}

local function getCharacter(instance)
	if instance:IsA("Player") then return instance.Character elseif instance:IsA("Model") then return instance end
end

local function isPlayerTarget(target)
	return target:IsA("Player") or (target:IsA("Model") and Players:GetPlayerFromCharacter(target) ~= nil)
end

local function makeEffect(name, position, size, color, duration)
	local effect = Instance.new("Part")
	effect.Name = name
	effect.Anchored = true
	effect.CanCollide = false
	effect.CanQuery = false
	effect.CanTouch = false
	effect.Material = Enum.Material.Neon
	effect.Color = color
	effect.Transparency = 0.1
	effect.Size = size
	effect.CFrame = CFrame.new(position)
	effect.Parent = workspace
	return effect, duration or 0.3
end

local function emitCombatEffect(crystalId, targetModel, ability)
	local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
	if not root then return end
	local color = CRYSTAL_COLORS[crystalId] or CRYSTAL_COLORS.EMBER
	local effect, duration = makeEffect(ability and "CrystalAbilityEffect" or "CrystalHitEffect", root.Position, ability and Vector3.new(5, 5, 5) or Vector3.new(2, 2, 2), color, 0.25)
	effect.Shape = Enum.PartType.Ball
	TweenService:Create(effect, TweenInfo.new(duration), { Size = ability and Vector3.new(11, 11, 11) or Vector3.new(4, 4, 4), Transparency = 1 }):Play()
	Debris:AddItem(effect, duration + 0.05)
	if not ability then return end
	if crystalId == "EMBER" then
		local ring, ringDuration = makeEffect("EmberBurst", root.Position, Vector3.new(1, 0.6, 1), color, 0.35)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, math.rad(90))
		TweenService:Create(ring, TweenInfo.new(ringDuration), { Size = Vector3.new(1, 12, 12), Transparency = 1 }):Play()
		Debris:AddItem(ring, ringDuration + 0.05)
	elseif crystalId == "TIDE" then
		for index = 1, 3 do
			local orb, orbDuration = makeEffect("TideOrb", root.Position + Vector3.new((index - 2) * 2.5, 1 + index * 0.25, 0), Vector3.new(1.2, 1.2, 1.2), color, 0.5)
			orb.Shape = Enum.PartType.Ball
			TweenService:Create(orb, TweenInfo.new(orbDuration), { Position = root.Position + Vector3.new((index - 2) * 4, 4 + index, 0), Transparency = 1 }):Play()
			Debris:AddItem(orb, orbDuration + 0.05)
		end
	elseif crystalId == "GALE" then
		for index = 1, 2 do
			local slash, slashDuration = makeEffect("GaleSlash", root.Position, Vector3.new(0.5, 7, 0.5), color, 0.3)
			slash.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(index * 65), math.rad(25 * index))
			TweenService:Create(slash, TweenInfo.new(slashDuration), { Size = Vector3.new(0.5, 11, 0.5), Transparency = 1 }):Play()
			Debris:AddItem(slash, slashDuration + 0.05)
		end
	end
end

local function fireProgress(player, levelsGained, mastery)
	local profile = PlayerService.GetProfile(player); if not profile then return end
	PlayerService.Sync(player)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
	if remotes:FindFirstChild("XPChanged") then remotes.XPChanged:FireClient(player, profile.Experience, profile.Level) end
	if remotes:FindFirstChild("MoneyChanged") then remotes.MoneyChanged:FireClient(player, profile.Money) end
	if remotes:FindFirstChild("InventoryChanged") then remotes.InventoryChanged:FireClient(player, profile.Inventory) end
	if levelsGained > 0 and remotes:FindFirstChild("LevelUp") then remotes.LevelUp:FireClient(player, profile.Level) end
	if mastery and remotes:FindFirstChild("CrystalMasteryChanged") then remotes.CrystalMasteryChanged:FireClient(player, mastery.Crystal, mastery.Level, mastery.XP) end
end

local function completeQuest(player, profile, questId, message)
	local definition = QuestSystem.GetDefinition(questId)
	if not definition or not QuestSystem.IsActive(profile, questId) then return false end
	if not QuestSystem.Complete(profile, questId) then return false end
	XPService.AddXP(profile, definition.XP)
	EconomyService.AddMoney(profile, definition.Money)
	PlayerService.Sync(player)
	player:SetAttribute("QuestMessage", message or (definition.Name .. " complete!"))
	QuestService.TryStartNext(player, profile)
	return true
end

local function advanceEnemyQuest(player, profile, enemyType)
	for questId, definition in pairs(QuestSystem.GetDefinitions()) do
		if definition.EnemyType == enemyType and QuestSystem.IsActive(profile, questId) then
			local complete, progress, goal = QuestSystem.Advance(profile, questId, 1)
			player:SetAttribute("QuestProgress", string.format("%s: %d/%d", definition.Name, progress, goal))
			if complete then completeQuest(player, profile, questId, definition.Name .. " complete!") end
		end
	end
end

local function giveLoot(profile, targetModel, crystalId)
	local enemyType = targetModel:GetAttribute("EnemyType")
	local enemyConfig = enemyType and EnemyConfig.Get(enemyType) or nil
	local itemId = enemyConfig and enemyConfig.Drop
	if not itemId then itemId = ({ EMBER = "EmberShard", TIDE = "TidePearl", GALE = "GaleFeather" })[crystalId] end
	if itemId then return InventoryService.AddItem(profile, itemId, 1) end
	return 0
end

local function rewardDefeat(player, profile, targetModel, action, crystalId)
	if targetModel:GetAttribute("BossId") ~= nil then return end
	if targetModel:GetAttribute("Enemy") ~= true or targetModel:GetAttribute("DeathRewarded") == true then return end
	targetModel:SetAttribute("DeathRewarded", true)
	local enemyType = targetModel:GetAttribute("EnemyType")
	local enemyConfig = enemyType and EnemyConfig.Get(enemyType) or nil
	local xpGain = enemyConfig and enemyConfig.XP or (action == "Ability" and 40 or 25)
	local moneyGain = enemyConfig and enemyConfig.Money or (action == "Ability" and 20 or 10)
	local _, _, levelsGained = XPService.AddXP(profile, xpGain)
	EconomyService.AddMoney(profile, moneyGain)
	giveLoot(profile, targetModel, crystalId)
	profile.Stats.EnemiesDefeated = (profile.Stats.EnemiesDefeated or 0) + 1
	if enemyType == "AncientGolem" then profile.Stats.AncientGolemsDefeated = (profile.Stats.AncientGolemsDefeated or 0) + 1 elseif enemyType == "CrystalBat" then profile.Stats.CrystalBatsDefeated = (profile.Stats.CrystalBatsDefeated or 0) + 1 end
	local masteryLevel, masteryXP, masteryLevels = CrystalMastery.AddXP(profile, crystalId, math.max(10, math.floor(xpGain * 0.5)))
	advanceEnemyQuest(player, profile, enemyType)
	if targetModel.Name == "TrainingDummy" then completeQuest(player, profile, "FIRST_FIGHT", "First Trial complete!") end
	if masteryLevels > 0 then player:SetAttribute("CrystalMessage", string.format("%s mastery reached Lv. %d", crystalId, masteryLevel)) end
	fireProgress(player, levelsGained or 0, { Crystal = crystalId, Level = masteryLevel, XP = masteryXP })
end

local function applyGaleSplash(player, centerModel, damage)
	local centerRoot = centerModel:FindFirstChild("HumanoidRootPart") or centerModel.PrimaryPart; if not centerRoot then return end
	local folder = workspace:FindFirstChild("NPCs"); if not folder then return end
	local profile = PlayerService.GetProfile(player)
	for _, enemy in ipairs(folder:GetChildren()) do
		if enemy ~= centerModel and enemy:IsA("Model") and enemy:GetAttribute("Enemy") == true and enemy:GetAttribute("BossId") == nil then
			local humanoid = enemy:FindFirstChildOfClass("Humanoid"); local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if humanoid and humanoid.Health > 0 and root and (root.Position - centerRoot.Position).Magnitude <= 12 then
				humanoid:TakeDamage(math.max(1, damage * 0.45))
				if humanoid.Health <= 0 and profile then rewardDefeat(player, profile, enemy, "Ability", "GALE") end
			end
		end
	end
end

local function applyAbilitySpecial(player, profile, crystalId, targetModel, abilityDamage)
	if crystalId == "TIDE" then
		local character = player.Character; local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 30); player:SetAttribute("CrystalMessage", "Tidal Pulse restored health.") end
	elseif crystalId == "GALE" then
		applyGaleSplash(player, targetModel, abilityDamage)
	end
end

function CombatService.HandleRequest(player, action, target)
	if not player:IsA("Player") or not VALID_ACTIONS[action] then return end
	local profile = PlayerService.GetProfile(player); if not profile or not profile.Crystals then return end
	if typeof(target) ~= "Instance" or target == player or isPlayerTarget(target) then return end
	local crystalId = profile.Crystals.Equipped
	local config = action == "Ability" and CrystalSystem.GetAbility(crystalId) or CrystalSystem.GetBasicAttack(crystalId); if not config then return end
	cooldowns[player] = cooldowns[player] or {}
	local now = os.clock(); if now < (cooldowns[player][action] or 0) then return end
	cooldowns[player][action] = now + config.Cooldown
	if action == "Ability" then player:SetAttribute("AbilityCooldownEnd", now + config.Cooldown) end
	local targetModel = getCharacter(target); if not targetModel then return end
	local passive = CrystalSystem.GetPassive(crystalId); local mastery = CrystalMastery.GetBonuses(profile, crystalId)
	local multiplier = math.max(0.1, tonumber(passive.DamageMultiplier) or 1) * mastery.DamageMultiplier
	if action == "Ability" then multiplier *= mastery.AbilityDamageMultiplier end
	local damage = (config.Damage + math.max(0, (profile.Stats.Damage or 0) - 10)) * multiplier
	local humanoid = targetModel:FindFirstChildOfClass("Humanoid"); if not humanoid or humanoid.Health <= 0 then return end
	targetModel:SetAttribute("LastAttackerUserId", player.UserId)
	local result = DamageService.ProcessDamage({ Attacker = player, Target = targetModel, Amount = damage, Range = config.Range, DamageType = "Crystal" }); if not result.Success then return end
	emitCombatEffect(crystalId, targetModel, action == "Ability")
	if action == "Ability" then applyAbilitySpecial(player, profile, crystalId, targetModel, damage); completeQuest(player, profile, "CRYSTAL_POWER", "Crystal Power complete!") end
	if humanoid.Health <= 0 then rewardDefeat(player, profile, targetModel, action, crystalId) end
end

return CombatService