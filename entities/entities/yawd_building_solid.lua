
--[[
    A building
]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "yawd_building"
ENT.Model = Model( "models/hunter/blocks/cube4x4x05.mdl" )
function ENT:Initialize()
   self:SetModel( self.Model )
   self:PhysicsInit( SOLID_VPHYSICS )
   self:SetMoveType( MOVETYPE_VPHYSICS )
   self:SetSolid( SOLID_BBOX )
   self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
end