local QuestService = {}
function QuestService.GetActive(profile) return profile.ActiveQuests end
function QuestService.GetCompleted(profile) return profile.CompletedQuests end
function QuestService.Start(profile, questId) if table.find(profile.ActiveQuests, questId) then return false end; table.insert(profile.ActiveQuests, questId); return true end
function QuestService.Complete(profile, questId) local index = table.find(profile.ActiveQuests, questId); if not index then return false end; table.remove(profile.ActiveQuests, index); table.insert(profile.CompletedQuests, questId); return true end
return QuestService
