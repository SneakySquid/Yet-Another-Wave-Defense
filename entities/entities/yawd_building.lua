
--[[
    A building
]]
AddCSLuaFile()


ENT.Type = "anim"
ENT.DisableDuplicator = true

if SERVER then
    function ENT:SetCreator( ply )
        self:SetNWEntity("yawd_owner", ply)
    end
    function ENT:GetBuildingData()
        return self.building_data
    end
else
    function ENT:IsCreatorMe()
        return self:GetCreator() == LocalPlayer()
    end
    function ENT:GetBuildingData()
        if self.building_data then return self.building_data end
        local bn = self:GetNWString("building_name", "")
        if bn == "" then return {} end
        self.building_data = Building.GetData( bn )
        return self.building_data
    end
end
function ENT:GetCreator( ply )
    return self:GetNWEntity("yawd_owner")
end

ENT.Model = Model( "models/hunter/plates/plate4x4.mdl" )
function ENT:Initialize()
   self:SetModel( self.Model )
   self:PhysicsInit( SOLID_VPHYSICS )
   self:SetMoveType( MOVETYPE_VPHYSICS )
   self:SetSolid( SOLID_BBOX )
   self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
end