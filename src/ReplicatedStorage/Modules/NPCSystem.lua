local NPCSystem = {}

function NPCSystem.GetId(npc)
	return npc and npc:GetAttribute("NPCId")
end

return NPCSystem
