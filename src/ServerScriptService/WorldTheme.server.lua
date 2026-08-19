local Workspace = game:GetService("Workspace")
local islands = Workspace:WaitForChild("Islands")

local themes = {
	StarterIsland = { Material = Enum.Material.Grass },
	TideIsland = { Material = Enum.Material.Sand },
	WindIsland = { Material = Enum.Material.Slate },
	AncientRuins = { Material = Enum.Material.Rock },
}

local allReady = true

for islandName, theme in pairs(themes) do
	local island = islands:WaitForChild(islandName, 30)
	if not island then
		allReady = false
		warn(("Crystal Bound: world theme island missing after 30s: %s"):format(islandName))
		continue
	end

	local ground = island:FindFirstChild("Ground")
	if not ground or not ground:IsA("BasePart") then
		allReady = false
		warn(("Crystal Bound: world theme ground missing for island: %s"):format(islandName))
		continue
	end

	ground.Material = theme.Material
end

if allReady then
	print("Crystal Bound world themes ready")
else
	warn("Crystal Bound world themes incomplete")
end
