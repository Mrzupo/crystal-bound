local DataStoreService = game:GetService("DataStoreService")
local PlayerData = require(script.Parent.PlayerData)

local SaveSystem = {}
local store = DataStoreService:GetDataStore("CrystalBound_PlayerData_v1")

function SaveSystem.Load(player)
	local ok, data = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if ok and type(data) == "table" then return data end
	return PlayerData.new()
end

function SaveSystem.Save(player, data)
	return pcall(function()
		store:UpdateAsync(tostring(player.UserId), function()
			return data
		end)
	end)
end

return SaveSystem
