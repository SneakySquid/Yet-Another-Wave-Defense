
--[[
	The core
]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "yawd_building"
ENT.Model = Model( "models/hunter/blocks/cube4x4x05.mdl" )
function ENT:Initialize()
	self:SetModel( self.Model )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_BBOX )
	-- self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	gmod.GetGamemode().Building_Core = self
	if SERVER and Controller then
		Controller.TrySpawnSpawners()
	elseif CLIENT then
		Building.ApplyFunctions( self )
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end