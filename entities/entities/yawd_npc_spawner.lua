
--[[
    A spawner for NPCs
]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model( "models/props_phx/construct/metal_angle360.mdl" )
function ENT:Initialize()
   self:SetModel( self.Model )
   self:PhysicsInit( SOLID_VPHYSICS )
   self:SetMoveType( MOVETYPE_VPHYSICS )
   self:SetSolid( SOLID_BBOX )

   self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
end