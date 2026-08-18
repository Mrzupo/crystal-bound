local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local crystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
local active = false

local function refresh()
	local gui = player:FindFirstChild("PlayerGui")
	local main = gui and gui:FindFirstChild("MainUI")
	local panel = main and main:FindFirstChild("Info")
	local label = panel and panel:FindFirstChild("Cooldown")
	if not label then return false end

	local crystal = player:GetAttribute("EquippedCrystal") or "EMBER"
	local endTime = tonumber(player:GetAttribute("AbilityCooldownEnd")) or 0
	local remaining = math.max(0, endTime - os.clock())
	local config = crystalConfig.Abilities[crystal]
	local name = config and config.Name or "Ability"

	if remaining > 0 then
		label.Text = string.format("Q Ability: %.1fs", remaining)
	else
		label.Text = string.format("Q Ability: READY • %s", name)
	end
	return remaining > 0
end

local function refreshOnStateChange()
	active = refresh()
end

player:GetAttributeChangedSignal("AbilityCooldownEnd"):Connect(refreshOnStateChange)
player:GetAttributeChangedSignal("EquippedCrystal"):Connect(refreshOnStateChange)
player.CharacterAdded:Connect(function()
	task.defer(refreshOnStateChange)
end)

refreshOnStateChange()

task.spawn(function()
	while player.Parent do
		if active then
			active = refresh()
			task.wait(0.1)
		else
			task.wait(0.25)
		end
	end
end)
