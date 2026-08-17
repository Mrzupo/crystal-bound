local Players = game:GetService("Players")
local SaveSystem = require(game.ReplicatedStorage.Modules.SaveSystem)
local PlayerData = require(game.ReplicatedStorage.Modules.PlayerData)

local PlayerService = { Profiles = {} }

function PlayerService.GetProfile(player) return PlayerService.Profiles[player] end
function PlayerService.Load(player) PlayerService.Profiles[player] = SaveSystem.Load(player); return PlayerService.Profiles[player] end
function PlayerService.Save(player) local data = PlayerService.Profiles[player]; if data then SaveSystem.Save(player, data) end end
function PlayerService.Remove(player) PlayerService.Save(player); PlayerService.Profiles[player] = nil end

return PlayerService
