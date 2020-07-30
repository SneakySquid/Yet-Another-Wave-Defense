
--[[
	The core
]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "yawd_building"
ENT.Model = Model( "models/hunter/plates/plate4x4.mdl" )
function ENT:Initialize()
	if SERVER then
		self:SetModel( self.Model )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:Sleep()
		end
		self:SetUseType(SIMPLE_USE)
	end

	-- self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	gmod.GetGamemode().Building_Core = self
	if SERVER and Controller then
		Controller.TrySpawnSpawners()
	elseif CLIENT then
		Building.ApplyFunctions( self )
	end
	for k,v in ipairs(ents.FindByClass( self:GetClass() )) do
		if v ~= self then
			SafeRemoveEntity(v)
		end
	end
end


function ENT:TakeCoreDamage( amount )
	local new_hp = self:Health() - amount
	local p = new_hp / self:GetMaxHealth()
	if p <= .50 and math.random(1,5) < 2 then
		self:EmitSound("ambient/machines/wall_move" .. math.random(1, 3) .. ".wav", 140)
	end
	self:SetHealth(new_hp)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:Use(activator, caller, use_type, value)
	if activator:IsPlayer() and use_type == USE_ON then
		GAMEMODE:OpenUpgradesMenuOnPlayer(activator)
	end
end

-- The core gives ammo
if SERVER then
	local n_Ammo = 0
	function ENT:Think()
		if n_Ammo > CurTime() then return end
		n_Ammo = CurTime() + 2
		for _, ply in ipairs( player.GetAll() ) do
			if ply:GetPos():Distance(self:GetPos()) < 300 then
				ply:YAWDGiveAmmo()
			end
		end
	end
end
