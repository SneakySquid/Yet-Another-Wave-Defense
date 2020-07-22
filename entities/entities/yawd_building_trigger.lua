
--[[
	A trigger entity for buildings
]]

ENT.Type = "anim"
ENT.DisableDuplicator = true

ENT.AreaMin = -Vector(95, 95, 1.7)
ENT.AreaMax = Vector(95, 95, 95)
function ENT:SetArea(vMin, vMax)
	self.AreaMin = vMin
	self.AreaMax = vMax
end
function ENT:Initialize()
	if SERVER then
		self:PhysicsInitBox( self.AreaMin, self.AreaMax )
		self:SetTrigger( true )
		self:SetSolidFlags( bit.bor( FSOLID_TRIGGER, FSOLID_USE_TRIGGER_BOUNDS ) )
	end
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
end
if SERVER then
	function ENT:StartTouch( ent )
		if self:GetOwner().StartTouch then
			self:GetOwner():StartTouch(ent)
		end
	end
	function ENT:EndTouch(ent)
		if self:GetOwner().EndTouch then
			self:GetOwner():EndTouch(ent)
		end
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end
--[[
function ENT:Draw()
	render.SetColorMaterial()
	render.DrawBox(self:GetPos(), self:GetAngles(), self.AreaMin, self.AreaMax, Color(0,0,255))
end]]