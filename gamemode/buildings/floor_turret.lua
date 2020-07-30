-- Simple Spikes

local b = {}
b.Name = "Floor Turret"
b.Icon = Material("yawd/hud/floor_turret.png")
b.BuildClass = {CLASS_CONSTRUCTOR, CLASS_GUNNER, CLASS_HEALER}
b.Cost = 850
b.TrapArea = {-Vector(95 * 3, 95 * 3, 1.7), Vector(95 * 3, 95 * 3, 95)}
local target_range = 403 -- math.sqrt((95 * 3) ^ 2 + (95 * 3) ^ 2)

local damage = 15 -- This gets x 50

b.TrapTriggerTime = 1	-- Time it takes to trigger
b.TrapResetTime = 15	-- Time it takes to reset
b.TrapDurationTime = 5	-- Time it takes to stop

local mdl = Model("models/combine_turrets/ground_turret.mdl")
-- Trap logic
	function b:Init()
		if CLIENT then
			self.i_hatch = 0
			if not self.t_model then
				self.t_model = ClientsideModel(mdl)
				self.t_model:SetPos(self:GetPos())
				self.t_model:SetNoDraw(true)
				self.t_model:SetModelScale(2)
			end
		end
	end
	function b:OnTrapTrigger( )
		if CLIENT then
			self:EmitSound("npc/scanner/scanner_siren1.wav")
		end
	end
	-- Unlike other traps, this one scans for enemies.
	local function SeeTarget(from, target, me)
		local tr = util.TraceLine( {
			start = from,
			endpos = target:GetPos() + target:OBBCenter(),
			filter = me,
			mask = MASK_SHOT
		} )
		if not tr.Hit then return false end
		if not IsValid(tr.Entity) or tr.Entity ~= target then return false end
		return true
	end
	local function OnDamage(self, tr, dmginfo)
		if not IsValid(tr.Entity) then dmginfo:SetDamage( 0 ) return end
		if not Building.CanTarget( tr.Entity ) then dmginfo:SetDamage( 0 ) return end
		dmginfo:SetAttacker( self:GetBuildingOwner() )
		dmginfo:SetInflictor( self )
	end
	function b:OnTrapThink()
		-- Find target
		if (self.i_target or 0) < CurTime() then
			local targets = {}
			for _,ent in ipairs(ents.FindInSphere(self:GetPos(), target_range)) do
				if not Building.CanTarget( ent ) then continue end
				if not SeeTarget(self:LocalToWorld(Vector(0,0,22)), ent) then continue end
				table.insert(targets, ent)
			end
			local n = #targets
			if n == 0 then
				self.e_target = nil
				return
			elseif n == 1 then
				self.e_target = targets[1]
			else
				local cur,dis
				for k,ent in ipairs(targets) do
					if not dis then
						dis = ent:GetPos():DistToSqr(self:GetPos())
						cur = ent
					else
						local dis2 = ent:GetPos():DistToSqr(self:GetPos())
						if dis < dis2 then continue end
						dis = dis2
						cur = ent
					end
				end
				self.e_target = cur
			end
			self.i_target = CurTime() + 0.75
		end
		-- Shoot target
		if IsValid(self.e_target) and self:DurationProcent() <= 0.9 and (self.i_bullet or 0) <= CurTime() then
			self.i_bullet = CurTime() + 0.10
			local b_pos = self:LocalToWorld(Vector(0,0,22 * 2))
			local b_ang = (self.e_target:GetPos() + self.e_target:OBBCenter() - b_pos):Angle()
			local b_norm = b_ang:Forward()
			local bullet = {}
				bullet.Num    = 1
				bullet.Src    = b_pos
				bullet.Dir    = b_norm
				bullet.Spread = Vector( 0, 0, 0 )
				bullet.Tracer = 2
				bullet.Force  = 5
				bullet.Damage = damage
				bullet.TracerName = "AR2Tracer"
				bullet.Callback = SERVER and OnDamage
			self:FireBullets( bullet)
			--MuzzleFlash
			if CLIENT then
				self:EmitSound("npc/turret_floor/shoot" .. math.random(1,3) .. ".wav")
				-- https://developer.valvesoftware.com/wiki/Muzzle_Flash_Lighting
				local dlight = DynamicLight( self:EntIndex() )
				local f_norm = Angle(0,b_ang.y,0):Forward()
				if ( dlight ) then
					dlight.pos = b_pos + f_norm * 20
					dlight.r = 231
					dlight.g = 219
					dlight.b = 14
					dlight.brightness = 1
					local size = math.random(245, 256)
					dlight.Size = size
					dlight.Decay = 512
					dlight.DieTime = CurTime() + 0.05
				end
				if self.t_model then
					self.t_model:MuzzleFlash()
				end
				local effectdata = EffectData()
				local m_pos = b_pos + f_norm * 25
				effectdata:SetEntity(self)
				effectdata:SetFlags( 0 )
				effectdata:SetOrigin( m_pos )
				effectdata:SetStart( m_pos )
				effectdata:SetAngles( b_ang )
				effectdata:SetNormal( b_norm )
				effectdata:SetAttachment( 1 )
				effectdata:SetMagnitude(2)
				util.Effect( "MuzzleEffect", effectdata )
			end
		end
	end
	function b:OnTrapEnd()
		if CLIENT then
			self:EmitSound("npc/scanner/cbot_discharge1.wav")
		end
	end

local mat = Material("yawd/models/trap_base")

local hatch_size = 37
if SERVER then return b end

function b:OnRemove()
	SafeRemoveEntity(self.t_model)
end

local mat,mat2 = Material("yawd/models/trap_squre"),Material("yawd/models/trap_side")
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase()
	-- Render turret

	if self:DurationProcent() > 0 then
		self.i_hatch = math.min((1 - self:DurationProcent()) * 10, 1)
	else
		self.i_hatch = math.max(0, self.i_hatch - FrameTime() * 1)
	end
	local r_a = self:LocalToWorldAngles(Angle(0,180,0))
	local h_vec =  Vector(0,hatch_size,1.8)
	local h2_vec = -Vector(hatch_size,hatch_size,1.8)
	if self.i_hatch <= 0 then
		render.SetMaterial(mat)
		render.DrawBox(self:GetPos(), self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
		render.DrawBox(self:GetPos(), r_a, h2_vec, h_vec, Color(0,0,0))
	elseif self.i_hatch >= 1 then
		render.SetMaterial(mat)
		render.DrawBox(self:GetPos(), self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
		render.DrawBox(self:GetPos(), r_a, h2_vec, h_vec, Color(0,0,0))
		if self.t_model then
			self.t_model:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 40 - 40)))
			self.t_model:DrawModel()
			if IsValid(self.e_target) then
				local a = (self.e_target:GetPos() - self.t_model:GetPos()):Angle()
				self.t_model:SetRenderAngles(Angle(0,a.y,180))
			else
				local a = self.t_model:GetAngles().y
				self.t_model:SetRenderAngles(Angle(0,a + FrameTime() * 65,180))
			end
		end
	else -- Within Animation
		if self.t_model and self.i_hatch >0.8 then -- There can be some cliping problems over 0.7
			self.t_model:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 40 - 40)))
			self.t_model:DrawModel()
		end
		Building.StencilMask()
		-- Render the mask
			render.DrawBox(self:GetPos(), self:GetAngles(), Vector(-hatch_size,-hatch_size,-1.8), Vector(hatch_size,hatch_size,1.8), Color(0,0,0))
		Building.StencilRender()
		-- Render stuff
			--Sides
			render.SetMaterial(mat2)
			local n = self:GetAngles():Right()
			render.DrawQuadEasy(self:LocalToWorld(Vector(0,hatch_size,0)), n, hatch_size * 5, 3.6, Color(0,0,0), 0)
			render.DrawQuadEasy(self:LocalToWorld(Vector(0,-hatch_size,0)), -n, hatch_size * 5, 3.6, Color(0,0,0), 0)
			local n = hatch_size * math.sin(self.i_hatch * math.pi)
			-- Hatch
			render.SetMaterial(mat)
			render.DrawBox(self:GetPos(), self:GetAngles(), Vector(-hatch_size - n,-hatch_size,-1.8), Vector(-n,hatch_size,1.8), Color(0,0,0))
			render.DrawBox(self:GetPos(), r_a, Vector(-hatch_size - n,-hatch_size,-1.8), Vector(-n,hatch_size,1.8), Color(0,0,0))
			if self.t_model and self.i_hatch <= 0.9 then
				local mdl_h = 40
				self.t_model:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 40 - mdl_h)))
				self.t_model:DrawModel()
			end
		Building.StencilEnd()
	end
	-- Renders the trap area
	self:RenderTrapArea()
end
function b:DrawSelection( )
	self:RenderBase()
	self:RenderTrapArea()

	local h_vec =  Vector(0,hatch_size,1.9)
	local h2_vec = -Vector(hatch_size,hatch_size,1.8)
		render.SetMaterial(mat)
		render.DrawBox(self:GetPos(), self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
		render.DrawBox(self:GetPos() + self:GetAngles():Forward() * hatch_size, self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
end
return b
