-- The Core

local b = {}
b.Name = "Core"
b.Icon = nil
b.Health = 1000
b.CanBuild = false
b.BuildClass = CLASS_ANY
b.Cost = -1

b.IsSolid = true
b.HasFoundation = true
b.BuildingSize = {-Vector(95, 95, 10), Vector(95, 95, 95)}
b.Models = {

}

function b:Init()
	if SERVER then return end
	self.emiter = ParticleEmitter(self:GetPos())
end

local m = Material("effects/splashwake1")
local m2 = Material("effects/splashwake3")
local m3 = Material("effects/bluespark")
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase()

	local r_col = Color(0,255,0)
	local r_pos = self:LocalToWorld(Vector(0,0,13))
	-- Two rings
	local r_col = Color(255,255,255,math.sin(CurTime() % 360 * 5) * 55 + 200)
	render.SetMaterial(m2)
	render.DrawQuadEasy(r_pos, self:GetUp(), 150, 150, r_col, CurTime() * 10 % 360)
	render.DrawQuadEasy(r_pos, self:GetUp(), 150, 150, r_col, CurTime() * -7 % 360)
	-- Rift
	local p = math.max(0, self:Health() / self:GetMaxHealth())
	render.SetMaterial(Material("effects/ar2_altfire1"))
	render.DrawSprite(self:LocalToWorld(Vector(0,0,100)), 100 * p, 100 * p, Color(255,255,255))

	-- Particles
	local d = LocalPlayer():GetPos():Distance(self:GetPos())
	if d > 1000 then return end
	if not self.emiter then return end
	if self._cpart and self._cpart > CurTime() then return end
	self._cpart = CurTime() + 0.03
	local p_r = math.random(math.pi * 2)
	local p_l = math.random(140)
	local p_x,p_y = math.cos(p_r) * p_l,math.sin(p_r) * p_l
	local s_pos = self:LocalToWorld(Vector(p_x,p_y,12))
	local part = self.emiter:Add( math.random(0,1) == 1 and "yawd/portal_spark" or "effects/blueflare1", s_pos ) -- Create a new particle at pos
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

return b