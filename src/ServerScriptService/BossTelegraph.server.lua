local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local DodgeService = require(script.Parent.Services.DodgeService)
local NPCs = Workspace:WaitForChild("NPCs")

local RUN_INTERVAL = 0.25
local TELEGRAPH_TIME = 0.8
local COOLDOWN = 5.5
local RADIUS = 8
local DAMAGE = 32

local nextCast = 0

local function createTelegraph(position)
	local part = Instance.new("Part")
	part.Name = "GuardianTelegraph"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.25, RADIUS * 2, RADIUS * 2)
	part.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 75, 110)
	part.Transparency = 0.35
	part.Parent = Workspace

	TweenService:Create(part, TweenInfo.new(TELEGRAPH_TIME, Enum.EasingStyle.Linear), {
		Transparency = 0.05,
		Size = Vector3.new(0.25, RADIUS * 2.25, RADIUS * 2.25),
	}):Play()
	Debris:AddItem(part, TELEGRAPH_TIME + 0.2)
end

local function getTarget()
	local guardian = NPCs:FindFirstChild("CrystalGuardian")
	local humanoid = guardian and guardian:FindFirstChildOfClass("Humanoid")
	local root = guardian and (guardian:FindFirstChild("HumanoidRootPart") or guardian.PrimaryPart)
	if not humanoid or humanoid.Health <= 0 or not root or (guardian:GetAttribute("BossPhase") or 1) < 2 then
		return nil
	end

	local nearestPlayer, nearestDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if targetHumanoid and targetHumanoid.Health > 0 and targetRoot then
			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance <= 70 and (not nearestDistance or distance < nearestDistance) then
				nearestPlayer = player
				nearestDistance = distance
			end
		end
	end
	return nearestPlayer
end

local function cast()
	local player = getTarget()
	if not player then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return end

	local position = root.Position
	createTelegraph(position)
	task.delay(TELEGRAPH_TIME, function()
		if not player.Parent then return end
		local currentCharacter = player.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
		local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
		if currentHumanoid and currentRoot and currentHumanoid.Health > 0 and (currentRoot.Position - position).Magnitude <= RADIUS then
			DodgeService.ApplyDamage(player, currentHumanoid, DAMAGE)
			player:SetAttribute("BossMessage", "Guardian Impact!")
		end
	end)
end

task.spawn(function()
	while Workspace.Parent do
		if os.clock() >= nextCast then
			local guardian = NPCs:FindFirstChild("CrystalGuardian")
			local phase = guardian and guardian:GetAttribute("BossPhase") or 1
			if phase >= 2 then
				nextCast = os.clock() + COOLDOWN
				cast()
			else
				nextCast = os.clock() + 1
			end
		end
		task.wait(RUN_INTERVAL)
	end
end)
