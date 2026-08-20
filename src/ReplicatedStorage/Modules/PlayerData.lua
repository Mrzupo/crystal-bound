local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent.PlayerDataOriginal)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)

local originalReconcile = PlayerData.Reconcile

function PlayerData.Reconcile(input)
	local data = originalReconcile(input)
	if type(data) ~= "table" or type(data.Crystals) ~= "table" or type(data.Crystals.Owned) ~= "table" then
		return data
	end

	data.CrystalMastery = type(data.CrystalMastery) == "table" and data.CrystalMastery or {}
	for _, crystalId in ipairs(data.Crystals.Owned) do
		if CrystalSystem.Exists(crystalId) and type(data.CrystalMastery[crystalId]) ~= "table" then
			data.CrystalMastery[crystalId] = { Level = 1, XP = 0 }
		end
	end
	return data
end

return PlayerData
