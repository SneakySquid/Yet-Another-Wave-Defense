
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "yawd_building"
ENT.DisableDuplicator = true

ENT.Model = Model( "models/hunter/plates/plate4x4.mdl" )
ENT.RenderGroup = RENDERGROUP_BOTH

--[[	This function is to make icons for traps.
function OI(plate, cam)
	local t = {
		["zfar"]    = 2551.0561503445,
		["fov"]     = 10.002485311578,
		["znear"]   = 1,
		["origin"] =  Vector(1562.759155, 1311.310547, 951.284973),
		["angles"] 	= Angle(25.000, 220.000, 0.000)
	}
	cam:SetPos(plate:GetPos() + t.origin + t.angles:Forward() * 2000)
	cam:SetAngles(t.angles)
end]]

-- Trap functions and variables
ENT.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}
ENT.TrapTriggerTime = -1
ENT.TrapResetTime = -1
ENT.TrapDurationTime = -1
-- Gets called when the trap triggers
function ENT:OnTrapTrigger()
end
-- Gets called on think within the trap duration
function ENT:OnTrapThink()
end
-- Gets called when the trap duration ends
function ENT:OnTrapEnd()
end
-- Gets called when the trap resets
function ENT:OnTrapReset()
end
-- Gets called when the trap upgrades
function ENT:OnTrapUpgrade()
end
-- Creats a damageinfo for the trap.
function ENT:DamageInfo()
	local dm = DamageInfo()
	dm:SetAttacker( self:GetBuildingOwner() )
	dm:SetInflictor( self )
	return dm
end
function ENT:Initialize()
	self:SetModel( self.Model )
end
function ENT:GetBuildingData()
	if self.builddata then return self.builddata end
	local bn = self:GetBuildingName()
	if bn == "" then return {} end
	self.builddata = Building.GetData( bn )
	return self.builddata
end

local mat = Material("yawd/trap_area.png","nocull")
local default = Color(0,255,0,20)
local default_disabled = Color(255,0,0,20)
function ENT:RenderTrapArea( color )
	local vmin,vmax = self:GetTrapArea()
	color = color or (self.CanAfford and default or default_disabled)
	color.a = 20
	render.SetMaterial(mat)
	render.DrawBox(self:GetPos(), self:GetAngles(), vmin,vmax, color)
	render.SetColorMaterial()
	color.a = 15
	render.DrawBox(self:GetPos(), self:GetAngles(), vmin,vmax, color)
end
function ENT:GetDisabled() return false end
function ENT:SetBuildingName( str )
	self.BuildingName = str
end
function ENT:GetBuildingName()
	return self.BuildingName
end
function ENT:Think()
	local ply = LocalPlayer()
	if not ply then 
		SafeRemoveEntity(self)
		return 
	end
	-- Check to see if localplayer still hold weapon.
	local wep = ply:GetActiveWeapon()
	if not wep or not IsValid(wep) or wep:GetClass() ~= "wep_build" then
		SafeRemoveEntity(self)
		return
	end
end
function ENT:Draw()
	self.CanAfford = Building.CanPlayerBuild( LocalPlayer(), self:GetBuildingName() )
	if self.DrawSelection then
		-- This is a bug in gmod. Shadows won't be made if the model isn't "rendered".
		render.SetBlend(0)
			self:DrawModel()
		render.SetBlend(1)
		render.SuppressEngineLighting( true )
		if not self.CanAfford then
			render.ResetModelLighting( 1,0,0 )
		else
			render.ResetModelLighting( 0,1,0 )			
		end
		self:DrawSelection(self.CanAfford)
		render.SuppressEngineLighting( false )
	else
		self:DrawModel()
	end
end
function ENT:SetupDataTables()
end