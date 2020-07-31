-- Simple Spikes

local b = {}
b.Name = "Lava"
b.Icon = Material("yawd/hud/lava.png")
b.Health = -1
b.CanBuild = true
b.BuildClass = {CLASS_CONSTRUCTOR, CLASS_RUNNER}
b.Cost = 550

b.BuildingSize = {-Vector(95, 95, 12), Vector(95, 95, 12)}
b.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}

b.TrapTriggerTime = 0.5	-- Time it takes to trigger
b.TrapResetTime = 45	-- Time it takes to reset
b.TrapDurationTime = 0	-- Time it takes to stop

function b:OnTrapThink() end

-- Set the amount of uses.
if SERVER then
	function b:Init()
		self.BurnAmount = 10 + self:GetUpgrades() * 7
	end
	function b:OnTrapReset()
		self.BurnAmount = 10 + self:GetUpgrades() * 7
	end
	function b:OnTrapUpgrade()
		self.BurnAmount = 10 + self:GetUpgrades() * 7
	end
else
	function b:OnTrapReset()
		self:EmitSound("ambient/fire/ignite.wav")
	end
end

function b:StartTouch( ent )
	if self:GetDisabled() then return end
	if self.BurnAmount <= 0 then return end
	if not Building.CanTarget( ent ) then return end
	if ent:HasDebuff(DEBUFF_BURNING) then return end
	self.OnTrap[ent] = true
	self.BurnAmount = self.BurnAmount - 1
	local dm = Element.DamageInfo( ELEMENT_FIRE )
		ent:TakeDamageInfo( dm )
		ent:EmitSound("ambient/fire/gascan_ignite1.wav", 100)
	--	ent:Ignite(4, 16)
	if self.BurnAmount > 0 then return end
	-- Start reset
	net.Start("yawd.traptrigger")
		net.WriteEntity(self)
		net.WriteInt(0, 32)
	net.Broadcast()
	self.i_duration = CurTime() + self.TrapDurationTime
end

function b:Think()
	if self.i_duration and self.i_duration < CurTime() then
		self.i_reset = CurTime() + self.TrapResetTime
		self.i_duration = nil
	end
	if self.i_reset and self.i_reset < CurTime() then
		self.i_reset = nil
		self:OnTrapReset()
	end
end

local mat = Material("yawd/models/trap_lava")
local mat2 = Material("yawd/models/trap_lava_empty")
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase( (self.i_reset or self:GetDisabled()) and mat2 or mat)
	self:RenderTrapArea()
end
b.DrawSelection = b.Draw

return b
