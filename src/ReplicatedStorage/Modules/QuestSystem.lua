local QuestSystem = {}

function QuestSystem.IsActive(profile, questId)
	return table.find(profile.ActiveQuests or {}, questId) ~= nil
end

function QuestSystem.IsCompleted(profile, questId)
	return table.find(profile.CompletedQuests or {}, questId) ~= nil
end

return QuestSystem
