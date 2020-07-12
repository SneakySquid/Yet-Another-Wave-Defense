
--[[
	A spawner for NPCs
]]
AddCSLuaFile()
local beam_length = 2000

ENT.Type = "anim"
ENT.Model = Model( "models/props_phx/construct/metal_angle360.mdl" )
ENT.RenderGroup = RENDERGROUP_BOTH
local snd = Sound("ambience/mechwhine.wav")
function ENT:Initialize()
	if ( SERVER ) then
		self:SetModel( self.Model )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:EmitSound(snd,75, 30, 1)
	else
		self.PixVis = util.GetPixelVisibleHandle()
		self.emitter = ParticleEmitter( self:GetPos() )
		self:SetRenderBounds( -Vector(48, 48, 1), Vector(48,48,beam_length + 50), Vector( 0, 0, 0 ) )
	end
	self:DrawShadow(false)
end

function ENT:OnRemove()
	self:StopSound(snd)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

if SERVER then 
	function ENT:Think()
	end
	return 
end

function ENT:Draw()
 --   self:DrawModel()
end

local m = Material("effects/splashwake1")
local m2 = Material("effects/splashwake3")
local m3 = Material("effects/bluespark")
local m4 = Material("decals/rollermine_crater")
local m5 = Material("effects/blueflare1")

local rndSnd = {Sound("ambient/energy/zap1.wav"),Sound("ambient/energy/zap2.wav"),Sound("ambient/energy/zap3.wav"),Sound("ambient/energy/zap5.wav"),Sound("ambient/energy/zap6.wav"),Sound("ambient/energy/zap7.wav"),Sound("ambient/energy/zap8.wav"),Sound("ambient/energy/zap9.wav")}
function ENT:Think()
	local d = LocalPlayer():GetPos():Distance(self:GetPos())
	-- Play sound
	if not (self._nsnd and self._nsnd > CurTime()) and d < 100 then
		self._nsnd = CurTime() + 4
		local snd = table.Random(rndSnd)
		self:EmitSound(snd,50, math.random(50, 20))
	end
	-- Render particles
	if GAMEMODE:HasWaveStarted() then return end
	if d > 1000 then return end
	if self._cpart and self._cpart > CurTime() then return end
	
	self._cpart = CurTime() + 0.05
	local p_r = math.random(math.pi * 2)
	local p_l = math.random(47)
	local p_x,p_y = math.cos(p_r) * p_l,math.sin(p_r) * p_l
	local s_pos = self:LocalToWorld(Vector(p_x,p_y,4))
	local part = self.emitter:Add( math.random(0,1) == 1 and "yawd/portal_spark" or "effects/blueflare1", s_pos ) -- Create a new particle at pos
	if ( part ) then
		part:SetDieTime( 1.1 ) -- How long the particle should "live"
		part:SetRoll( math.rad(180))
		part:SetStartAlpha( 0 ) -- Starting alpha of the particle
		part:SetEndAlpha( 255 ) -- Particle size at the end if its lifetime

		part:SetStartSize( 5 ) -- Starting size
		part:SetEndSize( 0 ) -- Size when removed

		part:SetGravity( Vector( 0, 0, 250 ) ) -- Gravity of the particle
		part:SetVelocity( Vector(p_x,p_y,0) * -0.8 ) -- Initial velocity of the particle
	end
end

function ENT:DrawTranslucent()
	local r_pos = self:LocalToWorld(Vector(0,0,0.5))
	local d = LocalPlayer():GetPos():Distance(self:GetPos())
	-- Crack in ground
	render.SetMaterial(m4)
	render.DrawQuadEasy(r_pos, self:GetUp(), 180, 180, Color(255,255,255,255), self:EntIndex() * 40)

	-- Two rings
	local r_col = Color(255,255,255,math.sin(CurTime() % 360 * 5) * 55 + 200)
	render.SetMaterial(m2)
	render.DrawQuadEasy(r_pos, self:GetUp(), 90, 90, r_col, CurTime() * 10 % 360)
	if d < 1500 then
	render.DrawQuadEasy(r_pos, self:GetUp(), 90, 90, r_col, CurTime() * -7 % 360)

	-- Center spin
	render.SetMaterial(m)
	render.DrawQuadEasy(r_pos, self:GetUp(), 24, 24, r_col, CurTime() * -45 % 360)
	end
	
	-- Glow
	render.SetMaterial(m5)
	render.DrawQuadEasy(r_pos, self:GetUp(), 90, 90, r_col, 0)

	-- Draw beam
	render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
		render.SetMaterial(Material("sprites/physring1"))
		render.DrawQuadEasy(self:GetPos() + Vector(0,0,beam_length), Vector(0,0,-1), math.random(300,305),math.random(300,305), r_col, CurTime() % 360 * 50)
	render.OverrideBlend(false)
	render.SetMaterial(Material("sprites/tp_beam001"))
	render.DrawBeam(self:GetPos(), self:GetPos() + Vector(0,0,beam_length) , math.max(5,d / 200), 0, beam_length / 100, Color(255,255,255))
end