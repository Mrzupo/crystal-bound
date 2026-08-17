local BaseCrystal = {}
BaseCrystal.__index = BaseCrystal

function BaseCrystal.new(context)
	return setmetatable({ Context = context, Active = false }, BaseCrystal)
end
function BaseCrystal:Initialize() end
function BaseCrystal:CanActivate() return not self.Active end
function BaseCrystal:Activate() self.Active = true end
function BaseCrystal:Deactivate() self.Active = false end
function BaseCrystal:GetCooldown() return 0 end
function BaseCrystal:Destroy() self.Active = false self.Context = nil end

return BaseCrystal
