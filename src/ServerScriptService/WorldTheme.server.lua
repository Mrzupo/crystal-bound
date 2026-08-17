local Workspace = game:GetService("Workspace")
local islands = Workspace:WaitForChild("Islands")

local themes = {
	StarterIsland = { Material = Enum.Material.Grass },
	TideIsland = { Material = Enum.Material.Sand },
	WindIsland = { Material = Enum.Material.Slate },
	AncientRuins = { Material = Enum.Material.Rock },
}

for islandName, theme in pairs(themes) do
	local island = islands:WaitForChild(islandName, 30)
	local ground = island and island:FindFirstChild("Ground")
	if ground and ground:IsA("BasePart") then
		ground.Material = theme.Material
	end
end

print("Crystal Bound world themes ready")
