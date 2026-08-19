local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local feedback = remotes:FindFirstChild("CombatFeedback")
if feedback then
	if not feedback:IsA("RemoteEvent") then
		error(("Crystal Bound: CombatFeedback has class %s, expected RemoteEvent"):format(feedback.ClassName))
	end
else
	feedback = Instance.new("RemoteEvent")
	feedback.Name = "CombatFeedback"
	feedback.Parent = remotes
end
