-- Simple Spikes

local b = {}
b.Name = "Tar"
b.Icon = nil
b.BuildClass = {CLASS_ANY}
b.Cost = 250
b.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}

-- Disable trap logic
	function b:OnTrapThink() end
	function b:OnTrapTrigger( ) end
	function b:OnTrapEnd() end
	function b:Think() end

function b:StartTouch( ent )
	if not Building.CanTarget( ent ) then return end
	if self:GetDisabled() then return end
	if not self.OnTrap then self.OnTrap = {} end
	if self.OnTrap[ent] then return end
	if CLIENT then
		ent:EmitSound("player/footsteps/mud" .. math.random(1, 4) .. ".wav")
	end
	local n = 0.6 / (self:GetUpgrades() + 1)
	if type(ent) == "Player" then
		self.OnTrap[ent] = { ent:GetRunSpeed(), ent:GetWalkSpeed() }
		ent:SetRunSpeed( ent:GetWalkSpeed() * n )
		ent:SetWalkSpeed( ent:GetWalkSpeed() * n )
	elseif ent.SetSpeedMult then
		ent:SetSpeedMult(n)
		self.OnTrap[ent] = true
	end
end
function b:EndTouch(ent)
	if not self.OnTrap[ent] then return end
	ent:EmitSound("player/footsteps/mud" .. math.random(1, 4) .. ".wav")
	if type(ent) == "Player" then
		ent:SetRunSpeed( self.OnTrap[ent][1] )
		ent:SetWalkSpeed( self.OnTrap[ent][2] )
	elseif ent.SetSpeedMult then
		ent:SetSpeedMult(1)
	end
	self.OnTrap[ent] = nil
end
local mat = Material("yawd/models/trap_tar")
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase(mat)
	-- Renders the trap area
	self:RenderTrapArea()
end
return b