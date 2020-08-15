
--[[
	A spawner for NPCs
]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model( "models/props_c17/oildrum001_explosive.mdl" )
ENT.RenderGroup = RENDERGROUP_BOTH
function ENT:Initialize()
	if ( SERVER ) then
		self:SetUseType( SIMPLE_USE )
		self:SetModel( self.Model )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:Wake()
		end
		self:SetHealth(10)
		self.b = true
		self.b_picked = false
	end
end

function ENT:Explode()
	if not self.b then return end
	self.b = false
	if self.building and IsValid(self.building) then
		local dmg = self.building:DamageInfo()
		for k,v in ipairs( ents.FindInSphere(self:GetPos(), 400) ) do
			if not v or not IsValid(v)  then continue end
			if Building.CanTarget(v) then
				local delta = v:GetPos() - self:GetPos()
				local dis = (400 - delta:Length()) / 400
				local force = dis * 800
				local norm = delta:GetNormalized()
				local t_damage = (self.damage or 1) * dis
				local fling = (v:Health() - t_damage) > 0
				dmg:SetDamage( t_damage )
				dmg:SetDamageType( DMG_BLAST )
				v:TakeDamageInfo( dmg )
				if fling then
					Building.ApplyTrapForce(v, Vector(0,0,450) + norm * force)
				end
			elseif v ~= self and v:GetClass() == self:GetClass() and v.b_picked == true then
				v:Explode()
			end
		end
		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetMagnitude(4)
		util.Effect( "Explosion", effectdata )
	end
	self:Remove()
end

function ENT:OnTakeDamage( dmginfo )
	local att = dmginfo:GetAttacker()
	local newHP = self:Health() - dmginfo:GetDamage()
	if newHP > 0 then
		self:SetHealth(newHP)
	else
		self:Explode()
	end
end

if SERVER then
	function ENT:Think()
		if self:GetBeingHeld() and not self:IsPlayerHolding() then 
			self:SetBeingHeld(false)
		end
		self:NextThink(CurTime() + 2)
		return true
	end
end

function ENT:Use(act)
	if not act or not IsValid(act) or not act:IsPlayer() then return end
	if self:IsPlayerHolding() then 
		self:SetBeingHeld(false)
		act:DropObject()
	else
		act:PickupObject( self )
		self.b_picked = true
		self:SetBeingHeld(true)
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "BeingHeld" )
end