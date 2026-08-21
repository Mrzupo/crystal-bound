local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)

local islands = Workspace:WaitForChild("Islands")

local function addPart(parent, name, size, position, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = material
	part:SetAttribute("CrystalBoundDecor", true)
	part.Parent = parent
	return part
end

local function at(center, offset)
	return center + offset
end

local function clearDecor(island, markerName, legacyNames)
	local legacy = {}
	for _, name in ipairs(legacyNames or {}) do legacy[name] = true end
	for _, child in ipairs(island:GetChildren()) do
		if child:GetAttribute("CrystalBoundDecor") == true or legacy[child.Name] then
			child:Destroy()
		end
	end
	local marker = island:FindFirstChild(markerName)
	if marker then marker:Destroy() end
end

local function hasCount(island, name, expected)
	local count = 0
	for _, child in ipairs(island:GetChildren()) do
		if child.Name == name and child:GetAttribute("CrystalBoundDecor") == true then count += 1 end
	end
	return count == expected
end

local function addAncientPillar(island, position, height)
	local base = addPart(island, "AncientPillar", Vector3.new(4, height, 4), position + Vector3.new(0, height / 2, 0), Enum.Material.Rock)
	base.Orientation = Vector3.new(0, math.random(0, 90), 0)
	local cap = addPart(island, "PillarCap", Vector3.new(5.5, 1, 5.5), position + Vector3.new(0, height + 0.5, 0), Enum.Material.Slate)
	cap.Orientation = base.Orientation
end

local function addCrystalCluster(island, position, material)
	for index = 1, 3 do
		local crystal = addPart(island, "AncientCrystal", Vector3.new(1.5 + index * 0.3, 4 + index, 1.5 + index * 0.3), position + Vector3.new((index - 2) * 2, 2.5 + index * 0.5, 0), material or Enum.Material.Neon)
		crystal.Shape = Enum.PartType.Wedge
		crystal.Orientation = Vector3.new(0, index * 35, 0)
	end
end

local function addTree(island, position, canopyMaterial)
	local trunk = addPart(island, "TreeTrunk", Vector3.new(2, 8, 2), position + Vector3.new(0, 4, 0), Enum.Material.Wood)
	trunk.Shape = Enum.PartType.Cylinder
	local canopy = addPart(island, "TreeCanopy", Vector3.new(8, 5, 8), position + Vector3.new(0, 9, 0), canopyMaterial or Enum.Material.Grass)
	canopy.Shape = Enum.PartType.Ball
end

local function addRock(island, position, size, material)
	local rock = addPart(island, "Rock", size or Vector3.new(6, 4, 5), position, material or Enum.Material.Rock)
	rock.Shape = Enum.PartType.Ball
	rock.Orientation = Vector3.new(math.random(-8, 8), math.random(0, 180), math.random(-8, 8))
end

local function mark(island, name)
	local marker = Instance.new("BoolValue")
	marker.Name = name
	marker.Value = true
	marker:SetAttribute("CrystalBoundDecor", true)
	marker.Parent = island
end

local starter = islands:WaitForChild("StarterIsland", 30)
local starterCenter = WorldConfig.Islands.STARTER.Center
if starter then
	local ready = starter:FindFirstChild("StarterDecorReady")
		and hasCount(starter, "TreeTrunk", 4)
		and hasCount(starter, "TreeCanopy", 4)
		and hasCount(starter, "Rock", 3)
		and starter:FindFirstChild("TrainingCamp")
		and starter.TrainingCamp:GetAttribute("CrystalBoundDecor") == true
	if not ready then
		clearDecor(starter, "StarterDecorReady", { "TreeTrunk", "TreeCanopy", "Rock", "TrainingCamp" })
		for _, offset in ipairs({ Vector3.new(-45, 1, 38), Vector3.new(-18, 1, 42), Vector3.new(42, 1, 35), Vector3.new(46, 1, -35) }) do
			addTree(starter, at(starterCenter, offset), Enum.Material.Grass)
		end
		for _, offset in ipairs({ Vector3.new(-35, 1, -34), Vector3.new(38, 1, -28), Vector3.new(-45, 1, 5) }) do
			addRock(starter, at(starterCenter, offset))
		end
		local camp = addPart(starter, "TrainingCamp", Vector3.new(14, 1, 14), at(starterCenter, Vector3.new(0, 1.5, 8)), Enum.Material.WoodPlanks)
		camp.Transparency = 0.25
		mark(starter, "StarterDecorReady")
	end
end

local tide = islands:WaitForChild("TideIsland", 30)
local tideCenter = WorldConfig.Islands.TIDE.Center
if tide then
	local ready = tide:FindFirstChild("TideDecorReady") and hasCount(tide, "Rock", 4) and hasCount(tide, "AncientCrystal", 9)
	if not ready then
		clearDecor(tide, "TideDecorReady", { "Rock", "AncientCrystal" })
		for _, offset in ipairs({ Vector3.new(-35, 1, -35), Vector3.new(30, 1, -32), Vector3.new(-25, 1, 35), Vector3.new(35, 1, 32) }) do
			addRock(tide, at(tideCenter, offset), Vector3.new(7, 3, 6), Enum.Material.Sandstone)
		end
		for _, offset in ipairs({ Vector3.new(-28, 1, 10), Vector3.new(10, 1, 30), Vector3.new(35, 1, -5) }) do
			addCrystalCluster(tide, at(tideCenter, offset), Enum.Material.Glass)
		end
		mark(tide, "TideDecorReady")
	end
end

local ancient = islands:WaitForChild("AncientRuins", 30)
local ancientCenter = WorldConfig.Islands.ANCIENT.Center
if ancient then
	local ready = ancient:FindFirstChild("DecorReady") and hasCount(ancient, "AncientPillar", 4) and hasCount(ancient, "PillarCap", 4) and hasCount(ancient, "AncientCrystal", 6)
	if not ready then
		clearDecor(ancient, "DecorReady", { "AncientPillar", "PillarCap", "AncientCrystal" })
		for _, data in ipairs({ { Vector3.new(-40, 1, -35), 10 }, { Vector3.new(40, 1, -30), 8 }, { Vector3.new(-35, 1, 35), 7 }, { Vector3.new(45, 1, 40), 11 } }) do
			addAncientPillar(ancient, at(ancientCenter, data[1]), data[2])
		end
		addCrystalCluster(ancient, at(ancientCenter, Vector3.new(0, 1, -5)))
		addCrystalCluster(ancient, at(ancientCenter, Vector3.new(55, 1, 18)))
		mark(ancient, "DecorReady")
	end
end

local wind = islands:WaitForChild("WindIsland", 30)
local windCenter = WorldConfig.Islands.WIND.Center
if wind then
	local ready = wind:FindFirstChild("WindDecorReady") and hasCount(wind, "WindRock", 3) and hasCount(wind, "AncientCrystal", 3)
	if not ready then
		clearDecor(wind, "WindDecorReady", { "WindRock", "AncientCrystal" })
		for _, offset in ipairs({ Vector3.new(-30, 1, 35), Vector3.new(35, 1, 35), Vector3.new(-15, 1, -35) }) do
			local rock = addPart(wind, "WindRock", Vector3.new(7, 4, 7), at(windCenter, offset), Enum.Material.Slate)
			rock.Shape = Enum.PartType.Ball
			rock.Orientation = Vector3.new(0, math.random(0, 180), math.random(-10, 10))
		end
		addCrystalCluster(wind, at(windCenter, Vector3.new(0, 1, 18)), Enum.Material.Neon)
		mark(wind, "WindDecorReady")
	end
end

print("Crystal Bound world decoration ready")
