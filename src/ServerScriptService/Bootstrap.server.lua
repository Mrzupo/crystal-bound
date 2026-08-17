local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)

Players.PlayerAdded:Connect(function(player)
	PlayerService.Load(player)
end)
Players.PlayerRemoving:Connect(function(player)
	PlayerService.Remove(player)
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerService.Save(player)
	end
end)
