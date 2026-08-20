local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DodgeService = require(script.Parent.Services.DodgeService)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)

local NPCs = Workspace:WaitForChild("NPCs")
local arena = Workspace:FindFirstChild("GuardianArena") or Instance.new("Folder")
arena.Name = "GuardianArena"
arena.Parent = Workspace
local bossConfig = BossConfig.CrystalGuardian
local config = bossConfig.ArenaHazard
local center = bossConfig.ArenaCenter
local pillarPositions = {
	center + Vector3.new(18, 4, 18),
	center + Vector3.new(-18, 4, 18),
	center + Vector3.new(18, 4, -18),
	center + Vector3.new(-18, 4, -18),
}

local hazardParts = {}
local phaseActive = false

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function ensureFloor()
	local floor = arena:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		floor.Size = Vector3.new(54, 1, 54)
		floor.Position = center
		floor.Anchored = true
		floor.Material = Enum.Material.Slate
		floor.Color = Color3.fromRGB(45, 35, 65)
		return floor
	end
	if floor then floor:Destroy() end
	floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(54, 1, 54)
	floor.Position = center
	floor.Anchored = true
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(45, 35, 65)
	floor.Parent = arena
	return floor
end

local function ensureRing()
	local ring = arena:FindFirstChild("Ring")
	if ring and ring:IsA("BasePart") then
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(1, 50, 50)
		ring.CFrame = CFrame.new(center + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(150, 90, 230)
		ring.Transparency = 0.45
		return ring
	end
	if ring then ring:Destroy() end
	ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(1, 50, 50)
	ring.CFrame = CFrame.new(center + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(150, 90, 230)
	ring.Transparency = 0.45
	ring.Parent = arena
	return ring
end

local function ensurePylon(index, position)
	local name = "Pylon" .. index
	local pillar = arena:FindFirstChild(name)
	if pillar and pillar:IsA("BasePart") then
		pillar.Size = Vector3.new(3, 8, 3)
		pillar.Position = position
		pillar.Anchored = true
		pillar.Material = Enum.Material.Neon
		pillar.Color = Color3.fromRGB(135, 95, 220)
		return pillar
	end
	if pillar then pillar:Destroy() end
	pillar = Instance.new("Part")
	pillar.Name = name
	pillar.Size = Vector3.new(3, 8, 3)
	pillar.Position = position
	pillar.Anchored = true
	pillar.Material = Enum.Material.Neon
	pillar.Color = Color3.fromRGB(135, 95, 220)
	pillar.Parent = arena
	return pillar
end

local function createArena()
	ensureFloor()
	ensureRing()
	for index, position in ipairs(pillarPositions) do
		ensurePylon(index, position)
	end
end

local function setPhaseHazard(enabled)
	if phaseActive == enabled then return end
	phaseActive = enabled
	if enabled then
		for index = 1, 4 do
			local hazard = Instance.new("Part")
			hazard.Name = "PhaseHazard" .. index
			hazard.Shape = Enum.PartType.Cylinder
			hazard.Size = Vector3.new(0.6, 8, 8)
			hazard.CFrame = CFrame.new(pillarPositions[index] + Vector3.new(0, -2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
			hazard.Anchored = true
			hazard.CanCollide = false
			hazard.CanTouch = false
			hazard.Material = Enum.Material.Neon
			hazard.Color = Color3.fromRGB(255, 90, 120)
			hazard.Transparency = 0.25
			hazard.Parent = arena
			hazardParts[index] = hazard
			TweenService:Create(hazard, TweenInfo.new(0.4), { Transparency = 0.05 }):Play()
		end
	else
		for index, hazard in pairs(hazardParts) do
			if hazard.Parent then
				TweenService:Create(hazard, TweenInfo.new(0.35), { Transparency = 1 }):Play()
				task.delay(0.4, function()
					if hazard.Parent then hazard:Destroy() end
				end)
			end
			hazardParts[index] = nil
		end
	end
end

local function applyHazardDamage()
	if not phaseActive then return end
	local halfExtent = math.clamp(finiteNumber(config.HalfExtent, 23), 0, 1000)
	local damage = math.clamp(finiteNumber(config.Damage, 0), 0, 1000)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local offset = root.Position - center
			if math.abs(offset.X) <= halfExtent and math.abs(offset.Z) <= halfExtent then
				DodgeService.ApplyDamage(player, humanoid, damage, nil, "Environmental", 0)
			end
		end
	end
end

createArena()

task.spawn(function()
	local interval = math.clamp(finiteNumber(config.Interval, 0.75), 0.1, 10)
	while arena.Parent do
		local guardian = NPCs:FindFirstChild("CrystalGuardian")
		local humanoid = guardian and guardian:FindFirstChildOfClass("Humanoid")
		local phase = guardian and guardian:GetAttribute("BossPhase") or 1
		setPhaseHazard(guardian ~= nil and humanoid ~= nil and humanoid.Health > 0 and phase >= 2)
		applyHazardDamage()
		task.wait(interval)
	end
end)
