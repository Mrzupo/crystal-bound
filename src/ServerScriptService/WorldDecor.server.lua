local Workspace = game:GetService("Workspace")

local islands = Workspace:WaitForChild("Islands")

local function addPart(parent, name, size, position, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = material
	part.Parent = parent
	return part
end

local function addAncientPillar(island, position, height)
	local base = addPart(island, "AncientPillar", Vector3.new(4, height, 4), position + Vector3.new(0, height / 2, 0), Enum.Material.Rock)
	base.Orientation = Vector3.new(0, math.random(0, 90), 0)
	local cap = addPart(island, "PillarCap", Vector3.new(5.5, 1, 5.5), position + Vector3.new(0, height + 0.5, 0), Enum.Material.Slate)
	cap.Orientation = base.Orientation
end

local function addCrystalCluster(island, position)
	for index = 1, 3 do
		local crystal = addPart(
			island,
			"AncientCrystal",
			Vector3.new(1.5 + index * 0.3, 4 + index, 1.5 + index * 0.3),
			position + Vector3.new((index - 2) * 2, 2.5 + index * 0.5, 0),
			Enum.Material.Neon
		)
		crystal.Shape = Enum.PartType.Wedge
		crystal.Orientation = Vector3.new(0, index * 35, 0)
	end
end

local ancient = islands:FindFirstChild("AncientRuins")
if ancient and not ancient:FindFirstChild("DecorReady") then
	for _, data in ipairs({
		{ Vector3.new(460, 1, -35), 10 },
		{ Vector3.new(540, 1, -30), 8 },
		{ Vector3.new(465, 1, 35), 7 },
		{ Vector3.new(545, 1, 40), 11 },
	}) do
		addAncientPillar(ancient, data[1], data[2])
	end
	addCrystalCluster(ancient, Vector3.new(500, 1, -5))
	addCrystalCluster(ancient, Vector3.new(555, 1, 18))
	local marker = Instance.new("BoolValue")
	marker.Name = "DecorReady"
	marker.Value = true
	marker.Parent = ancient
end

local wind = islands:FindFirstChild("WindIsland")
if wind and not wind:FindFirstChild("WindDecorReady") then
	for _, position in ipairs({
		Vector3.new(300, 1, 35),
		Vector3.new(365, 1, 35),
		Vector3.new(315, 1, -35),
	}) do
		local rock = addPart(wind, "WindRock", Vector3.new(7, 4, 7), position, Enum.Material.Slate)
		rock.Orientation = Vector3.new(0, math.random(0, 180), math.random(-10, 10))
	end
	local marker = Instance.new("BoolValue")
	marker.Name = "WindDecorReady"
	marker.Value = true
	marker.Parent = wind
end

print("Crystal Bound world decoration ready")
