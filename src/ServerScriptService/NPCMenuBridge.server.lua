local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function bindPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt:GetAttribute("CrystalBoundMenuBound") then return end
	prompt:SetAttribute("CrystalBoundMenuBound", true)
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then return end
	prompt.Triggered:Connect(function(player)
		if model.Name == "CrystalKeeper" then
			player:SetAttribute("OpenQuestMenu", os.clock())
		elseif model.Name == "MaterialTrader" then
			player:SetAttribute("OpenShopMenu", os.clock())
		end
	end)
end

local folder = Workspace:WaitForChild("NPCs")
for _, descendant in ipairs(folder:GetDescendants()) do bindPrompt(descendant) end
folder.DescendantAdded:Connect(bindPrompt)

Players.PlayerRemoving:Connect(function(player)
	player:SetAttribute("OpenQuestMenu", nil)
	player:SetAttribute("OpenShopMenu", nil)
end)
