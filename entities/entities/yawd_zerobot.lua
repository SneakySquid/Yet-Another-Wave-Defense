--[[
	Zero the booster bot
]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.DisableDuplicator = true

ENT.Model = Model( "models/combine_scanner.mdl" )
ENT.RenderGroup = RENDERGROUP_BOTH
if SERVER then
	util.AddNetworkString("yawd.zerobot")
else
	ENT.AutomaticFrameAdvance = true
end

local boost_end = Sound("npc/turret_floor/retract.wav")
local boost_start = Sound( "npc/scanner/combat_scan1.wav" )

function ENT:Initialize()
	self:SetModel( self.Model )
	if SERVER then
		self:PhysicsInit( SOLID_OBB )
		self:SetMoveType( MOVETYPE_NOCLIP )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		if not IsValid(self.Owner) then
			self.Owner = player.GetAll()[1]
		end
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:EnableGravity(false)
			phys:Wake()
		end
		self.m_acc = 0
	end
end

function ENT:GetTarget()
	return self.m_ETarget
end

function ENT:OnRemove()
	local effectdata = EffectData()
	effectdata:SetOrigin( self:GetPos() )
	effectdata:SetMagnitude(1)
	util.Effect( "cball_bounce", effectdata )
end

function ENT:OnStatusChanged()
	if CLIENT then
		if IsValid(self:GetTarget()) then
			self:EmitSound(boost_start)
		else
			self:EmitSound(boost_end)
		end
		self:SetRenderBounds(self:OBBMins(), self:OBBMaxs())
	end
end

if CLIENT then
	net.Receive("yawd.zerobot", function()
		local self = net.ReadEntity()
		if not IsValid(self) then return end
		local oldTarget = self.m_ETarget
		if not net.ReadBool() then
			self.m_ETarget = nil
		else
			self.m_ETarget = net.ReadEntity()
		end
		if oldTarget == self.m_ETarget then return end
		self:OnStatusChanged()
	end)
	local ratio = 1
	function ENT:Think()
		-- Animation
		if not IsValid( self:GetTarget() ) then
			self:SetSequence("idle")
			self.m_nCykle = ((self.m_nCykle or 0) + FrameTime() * 0.5) % 1
			self:SetCycle( self.m_nCykle )
		else
			self:SetSequence("flare")
			self.m_nCykle = math.min(1, (self.m_nCykle or 0) + FrameTime() * 0.5)
			self:SetCycle( self.m_nCykle)
		end
		self:NextThink(CurTime())
		-- Handle angle
		local t_angle
		if self.m_ETarget and IsValid(self.m_ETarget) then
			local t_pos = self.m_ETarget:GetPos() + self.m_ETarget:OBBCenter()
			t_angle = (t_pos - self:GetPos()):Angle()
		else
			local v = self:GetAbsVelocity()
			t_angle = v:Angle()
			if t_angle.y == 0 then return true end
		end
		local y_n = (self:GetRenderAngles() or self:GetAngles()).y
		local y_diff = math.AngleDifference(y_n, t_angle.y)
		if math.abs(y_diff) < 1 then return true end
		local n_y = y_n - math.Clamp(y_diff, -ratio, ratio)
		self:SetRenderAngles(Angle(0,n_y,0))
		self.m_FakeYaw = n_y
		return true
	end
else
	function ENT:ClearTarget( )
		self.m_ETarget = nil
		net.Start("yawd.zerobot")
			net.WriteEntity(self)
			net.WriteBool(false)
		net.Broadcast()
		self:OnStatusChanged()
		print(self,"clear")
	end
	function ENT:SetBoostTarget( ply )
		self.m_ETarget = ply
		net.Start("yawd.zerobot")
			net.WriteEntity(self)
			net.WriteBool( true )
			net.WriteEntity( ply )
		net.Broadcast()
		self:OnStatusChanged()
	end
	function ENT:MoveTo( pos, min_dis )
		pos.z = pos.z + math.sin(CurTime()) * 5
		local dif = (pos - self:GetPos())
		local le = math.max(0, dif:Length() - min_dis)
		if le > 10 then
			self.m_acc = math.min(self.m_acc + 0.25, le / 50, 1.5)
			dif:GetNormal()
			self:SetAbsVelocity( dif * self.m_acc  )
		elseif self:GetPos().z ~= pos.z then
			self:SetAbsVelocity( Vector(0,0,pos.z - self:GetPos().z) )
		else
			self:SetAbsVelocity( Vector(0,0,0) )
		end
	end
	local function PlayerHasWeapon( ply )
		local wep = ply:GetActiveWeapon()
		if not wep then return end
		if wep:GetMaxClip1() < 1 then return end
		return wep
	end
	function ENT:ScanPlayers() -- Locates the lowest player with health
		local ply
		for k,v in ipairs(player.GetAll()) do
			if v:GetPos():DistToSqr(v:GetPos()) > 123336 then continue end
			local wep = PlayerHasWeapon(v)
			if not wep then continue end
			local tr = util.TraceLine( {
				start = self:GetPos(),
				endpos = v:GetPos() + v:OBBCenter(),
				mask = MASK_SOLID_BRUSHONLY,
				filter = self
			} )
			if tr.Hit and tr.Entity ~= v then continue end -- Behind a wall
			if not ply or ply == self.Owner then
				ply = v
			end
		end
		return ply
	end
	function ENT:Think() -- Turn towards the target
		if IsValid(self.Owner) and self.Owner:Alive() then
			local z_target = self.Owner:GetPos() + Vector(0, 0, self.Owner:OBBMaxs().z + 20)
			self:MoveTo( z_target, 100 )
			self:NextThink( CurTime() )
		else
			self:Remove()
		end
		-- Boost players
		if (self.m_Ps or 0) < CurTime() then
			if not IsValid( self:GetTarget() ) or self.m_Ps < CurTime() - 5 then
				local boost = self:ScanPlayers()
				if boost then
					self:SetBoostTarget( boost )
				elseif self:GetTarget() then
					self:ClearTarget()
				end
				self.m_Ps = CurTime() + 2
			elseif IsValid( self:GetTarget() ) then
				if not PlayerHasWeapon(self:GetTarget()) then
					self:ClearTarget()
				end
			end
		end
		self:NextThink( CurTime() )
		return true
	end
end

local mat_light = Material("sprites/light_glow02_add")
local mat_beam = Material("sprites/tp_beam001")
function ENT:Draw()
	self:DrawModel()
	local y = EyeAngles().y + 270
	cam.Start3D2D(self:GetPos() + Vector(0,0,30), Angle(0, y, 90), 0.5)
		draw.DrawText("Zero", "HUD.TargetID", 0, 0, color_white, TEXT_ALIGN_CENTER)
	cam.End3D2D()
	local target = self:GetTarget()
	if IsValid(target) then
		local r = math.rad(self.m_FakeYaw or self:GetAngles().y)
		local pos1 = self:GetPos() + Vector(math.cos(r),math.sin(r),0) * 15
		local wep = target:GetActiveWeapon()
		if not IsValid(wep) then return end
		local att_id = wep:LookupAttachment("muzzle")
		local pos2
		if att_id < 1 then -- Invalid
			pos2 = target:GetPos() + target:OBBCenter() * 1.3
		else
			local att = wep:GetAttachment(att_id)
			pos2 = att.Pos 
		end
		render.SetMaterial(mat_light)
		render.DrawSprite(pos1, 32,32, Color(255,55,55))
		render.DrawSprite(pos2, 64,64, Color(255,55,55))
		render.SetMaterial(mat_beam)

		self:SetRenderBounds(self:OBBMins(), self:OBBMaxs(), Vector(dis, dis, dis) * 128)
	end
end

local function HasBot( ply )
	for k,v in ipairs( ents.FindByClass("yawd_zerobot") ) do
		if v:GetTarget() == ply then return true end
	end
	return false
end

hook.Add("EntityTakeDamage", "YAWD.ZeroBot", function( target, dmginfo )
	local attacker = dmginfo:GetAttacker()
	if not attacker or not IsValid(attacker) or not attacker:IsPlayer() then return end
	local infict = dmginfo:GetInflictor()
	if not infict or not IsValid(infict) then return end
	if string.sub(infict:GetClass(), 0 , 13) == "yawd_building" then return end
	if HasBot( attacker ) then
		dmginfo:SetDamage( dmginfo:GetDamage() * 1.2)
	end
end)