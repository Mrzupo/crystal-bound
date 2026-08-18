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
	part.Parent = parent
	return part
end

local function at(center, offset)
	return center + offset
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
	marker.Parent = island
end

local starter = islands:WaitForChild("StarterIsland", 30)
local starterCenter = WorldConfig.Islands.STARTER.Center
if starter and not starter:FindFirstChild("StarterDecorReady") then
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

local tide = islands:WaitForChild("TideIsland", 30)
local tideCenter = WorldConfig.Islands.TIDE.Center
if tide and not tide:FindFirstChild("TideDecorReady") then
	for _, offset in ipairs({ Vector3.new(-35, 1, -35), Vector3.new(30, 1, -32), Vector3.new(-25, 1, 35), Vector3.new(35, 1, 32) }) do
		addRock(tide, at(tideCenter, offset), Vector3.new(7, 3, 6), Enum.Material.Sandstone)
	end
	for _, offset in ipairs({ Vector3.new(-28, 1, 10), Vector3.new(10, 1, 30), Vector3.new(35, 1, -5) }) do
		addCrystalCluster(tide, at(tideCenter, offset), Enum.Material.Glass)
	end
	mark(tide, "TideDecorReady")
end

local ancient = islands:WaitForChild("AncientRuins", 30)
local ancientCenter = WorldConfig.Islands.ANCIENT.Center
if ancient and not ancient:FindFirstChild("DecorReady") then
	for _, data in ipairs({ { Vector3.new(-40, 1, -35), 10 }, { Vector3.new(40, 1, -30), 8 }, { Vector3.new(-35, 1, 35), 7 }, { Vector3.new(45, 1, 40), 11 } }) do
		addAncientPillar(ancient, at(ancientCenter, data[1]), data[2])
	end
	addCrystalCluster(ancient, at(ancientCenter, Vector3.new(0, 1, -5)))
	addCrystalCluster(ancient, at(ancientCenter, Vector3.new(55, 1, 18)))
	mark(ancient, "DecorReady")
end

local wind = islands:WaitForChild("WindIsland", 30)
local windCenter = WorldConfig.Islands.WIND.Center
if wind and not wind:FindFirstChild("WindDecorReady") then
	for _, offset in ipairs({ Vector3.new(-30, 1, 35), Vector3.new(35, 1, 35), Vector3.new(-15, 1, -35) }) do
		local rock = addPart(wind, "WindRock", Vector3.new(7, 4, 7), at(windCenter, offset), Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball
		rock.Orientation = Vector3.new(0, math.random(0, 180), math.random(-10, 10))
	end
	addCrystalCluster(wind, at(windCenter, Vector3.new(0, 1, 18)), Enum.Material.Neon)
	mark(wind, "WindDecorReady")
end

print("Crystal Bound world decoration ready")