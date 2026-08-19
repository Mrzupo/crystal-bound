local QuestSystem = {}

local Definitions = {
	FIRST_FIGHT = { Id = "FIRST_FIGHT", Name = "First Trial", Description = "Defeat the Training Dummy.", Goal = 1, XP = 100, Money = 50, MinLevel = 1 },
	CRYSTAL_POWER = { Id = "CRYSTAL_POWER", Name = "Crystal Power", Description = "Use your equipped crystal ability once.", Goal = 1, XP = 150, Money = 75, MinLevel = 1, Requires = "FIRST_FIGHT" },
	HUNT_EMBERLINGS = { Id = "HUNT_EMBERLINGS", Name = "Ashes in the Wind", Description = "Defeat 3 Emberlings.", Goal = 3, XP = 300, Money = 150, EnemyType = "Emberling", MinLevel = 3, Requires = "CRYSTAL_POWER" },
	TIDE_EXPEDITION = { Id = "TIDE_EXPEDITION", Name = "Tide Expedition", Description = "Defeat 3 Tidecrawlers.", Goal = 3, XP = 500, Money = 300, EnemyType = "Tidecrawler", MinLevel = 6, Requires = "HUNT_EMBERLINGS" },
	WIND_TRIAL = { Id = "WIND_TRIAL", Name = "Trial of the Gale", Description = "Defeat 3 Galewisps.", Goal = 3, XP = 800, Money = 500, EnemyType = "Galewisp", MinLevel = 10, Requires = "TIDE_EXPEDITION" },
	GUARDIAN_TRIAL = { Id = "GUARDIAN_TRIAL", Name = "Guardian of the Crystals", Description = "Defeat the Crystal Guardian.", Goal = 1, XP = 2200, Money = 1500, EnemyType = "CrystalGuardian", MinLevel = 15, Requires = "WIND_TRIAL" },
	GOLEM_HUNT = { Id = "GOLEM_HUNT", Name = "Stonebound", Description = "Defeat 3 Ancient Golems.", Goal = 3, XP = 900, Money = 600, EnemyType = "AncientGolem", MinLevel = 18, Requires = "GUARDIAN_TRIAL" },
	BAT_HUNT = { Id = "BAT_HUNT", Name = "Shards in the Dark", Description = "Defeat 3 Crystal Bats.", Goal = 3, XP = 1000, Money = 700, EnemyType = "CrystalBat", MinLevel = 19, Requires = "GOLEM_HUNT" },
}

local function safeAmount(amount)
	local value = tonumber(amount)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	if value < 0 or value % 1 ~= 0 then
		return nil
	end
	return value
end

function QuestSystem.GetDefinition(id)
	return Definitions[id]
end

function QuestSystem.GetDefinitions()
	return Definitions
end

function QuestSystem.GetChainOrder()
	local ordered = {}
	local current = nil
	local roots = {}
	for id, definition in pairs(Definitions) do
		if not definition.Requires then table.insert(roots, id) end
	end
	table.sort(roots, function(a, b)
		return (Definitions[a].MinLevel or 1) < (Definitions[b].MinLevel or 1)
	end)
	current = roots[1]
	local seen = {}
	while current and not seen[current] do
		seen[current] = true
		table.insert(ordered, current)
		local nextId
		for id, definition in pairs(Definitions) do
			if definition.Requires == current then
				nextId = id
				break
			end
		end
		current = nextId
	end
	return ordered
end

function QuestSystem.IsActive(profile, questId)
	return table.find(profile.ActiveQuests or {}, questId) ~= nil
end

function QuestSystem.IsCompleted(profile, questId)
	return table.find(profile.CompletedQuests or {}, questId) ~= nil
end

function QuestSystem.CanStart(profile, questId)
	local definition = Definitions[questId]
	if not definition then return false, "Unknown quest." end
	if QuestSystem.IsActive(profile, questId) or QuestSystem.IsCompleted(profile, questId) then
		return false, "Quest already started or completed."
	end
	if #(profile.ActiveQuests or {}) > 0 then
		return false, "Finish your active quest first."
	end
	if (profile.Level or 1) < (definition.MinLevel or 1) then
		return false, string.format("Reach level %d.", definition.MinLevel or 1)
	end
	if definition.Requires and not QuestSystem.IsCompleted(profile, definition.Requires) then
		return false, "Complete the previous quest first."
	end
	return true
end

function QuestSystem.GetAvailable(profile)
	local available = {}
	for questId, definition in pairs(Definitions) do
		local canStart = QuestSystem.CanStart(profile, questId)
		if canStart then table.insert(available, questId) end
	end
	table.sort(available, function(a, b)
		local left = Definitions[a]
		local right = Definitions[b]
		if left.MinLevel ~= right.MinLevel then
			return (left.MinLevel or 1) < (right.MinLevel or 1)
		end
		return a < b
	end)
	return available
end

function QuestSystem.Start(profile, questId)
	local allowed = QuestSystem.CanStart(profile, questId)
	if not allowed then return false end
	profile.ActiveQuests = profile.ActiveQuests or {}
	profile.CompletedQuests = profile.CompletedQuests or {}
	profile.QuestProgress = profile.QuestProgress or {}
	table.insert(profile.ActiveQuests, questId)
	profile.QuestProgress[questId] = 0
	return true
end

function QuestSystem.GetProgress(profile, questId)
	return (profile.QuestProgress and profile.QuestProgress[questId]) or 0
end

function QuestSystem.Advance(profile, questId, amount)
	local definition = Definitions[questId]
	if not definition or not QuestSystem.IsActive(profile, questId) then
		return false, 0, definition and definition.Goal or 0
	end
	profile.QuestProgress = profile.QuestProgress or {}
	local safeIncrement = safeAmount(amount)
	if safeIncrement == nil then
		return false, QuestSystem.GetProgress(profile, questId), definition.Goal
	end
	profile.QuestProgress[questId] = math.min(definition.Goal, QuestSystem.GetProgress(profile, questId) + safeIncrement)
	return profile.QuestProgress[questId] >= definition.Goal, profile.QuestProgress[questId], definition.Goal
end

function QuestSystem.Complete(profile, questId)
	local index = table.find(profile.ActiveQuests or {}, questId)
	if not index then return false end
	table.remove(profile.ActiveQuests, index)
	profile.CompletedQuests = profile.CompletedQuests or {}
	profile.QuestProgress = profile.QuestProgress or {}
	table.insert(profile.CompletedQuests, questId)
	profile.QuestProgress[questId] = 0
	return true
end

return QuestSystem
