local QuestSystem = {}

local Definitions = {
	FIRST_FIGHT = {
		Id = "FIRST_FIGHT",
		Name = "First Trial",
		Description = "Defeat the Training Dummy.",
		Goal = 1,
		XP = 100,
		Money = 50,
	},
	CRYSTAL_POWER = {
		Id = "CRYSTAL_POWER",
		Name = "Crystal Power",
		Description = "Use your equipped crystal ability once.",
		Goal = 1,
		XP = 150,
		Money = 75,
	},
}

function QuestSystem.GetDefinition(id)
	return Definitions[id]
end

function QuestSystem.GetDefinitions()
	return Definitions
end

function QuestSystem.IsActive(profile, questId)
	return table.find(profile.ActiveQuests or {}, questId) ~= nil
end

function QuestSystem.IsCompleted(profile, questId)
	return table.find(profile.CompletedQuests or {}, questId) ~= nil
end

function QuestSystem.Start(profile, questId)
	if not Definitions[questId] or QuestSystem.IsActive(profile, questId) or QuestSystem.IsCompleted(profile, questId) then
		return false
	end
	table.insert(profile.ActiveQuests, questId)
	return true
end

function QuestSystem.Complete(profile, questId)
	local index = table.find(profile.ActiveQuests or {}, questId)
	if not index then return false end
	table.remove(profile.ActiveQuests, index)
	table.insert(profile.CompletedQuests, questId)
	return true
end

return QuestSystem
