local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local feedback = remotes:FindFirstChild("CombatFeedback")
if not feedback then
	feedback = Instance.new("RemoteEvent")
	feedback.Name = "CombatFeedback"
	feedback.Parent = remotes
end
