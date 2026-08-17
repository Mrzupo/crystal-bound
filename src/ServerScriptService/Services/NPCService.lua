local NPCService = {}
function NPCService.GetNPCs() local folder = workspace:FindFirstChild("NPCs"); return folder and folder:GetChildren() or {} end
return NPCService
