local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local crystalConfig = require(ReplicatedStorage.Config.CrystalConfig)

local function refresh()
	local gui = player:FindFirstChild("PlayerGui")
	local main = gui and gui:FindFirstChild("MainUI")
	local panel = main and main:FindFirstChild("Info")
	local label = panel and panel:FindFirstChild("Cooldown")
	if not label then return end

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
end

RunService:BindToRenderStep("CrystalBoundCooldownAuthority", Enum.RenderPriority.Last.Value, refresh)
player:GetAttributeChangedSignal("AbilityCooldownEnd"):Connect(refresh)
player:GetAttributeChangedSignal("EquippedCrystal"):Connect(refresh)
