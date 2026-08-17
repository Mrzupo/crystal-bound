local NPCService = {}

function NPCService.GetNPCs()
	local folder = workspace:FindFirstChild("NPCs")
	return folder and folder:GetChildren() or {}
end

function NPCService.FindByName(name)
	local folder = workspace:FindFirstChild("NPCs")
	return folder and folder:FindFirstChild(name) or nil
end

function NPCService.IsInteractable(instance)
	return instance and instance:IsA("Model") and instance:GetAttribute("Interactable") == true
end

return NPCService
