-- Simple Spikes

local b = {}
b.Name = "Blade Trap"
b.Icon = Material("yawd/hud/blade_trap.png")
b.BuildClass = {CLASS_CONSTRUCTOR, CLASS_FIGHTER, CLASS_RUNNER}
b.Cost = 800
b.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}
local target_range = 134 -- math.sqrt((95) ^ 2 + (95) ^ 2)

local damage = 16 -- This is every slice (5 pr second)

b.TrapTriggerTime = 0.6	-- Time it takes to trigger
b.TrapResetTime = 15	-- Time it takes to reset
b.TrapDurationTime = 5	-- Time it takes to stop

local mdl = Model("models/props_c17/TrapPropeller_Blade.mdl")
-- Trap logic
	function b:Init()
		if CLIENT then
			self.i_hatch = 0
			if not self.t_model then
				self.t_model = ClientsideModel(mdl)
				self.t_model:SetPos(self:GetPos())
				self.t_model:SetNoDraw(true)
				self.m_matrix = Matrix()
				self.m_matrix:Scale(Vector(0.7,0.7,0.7))
				self.t_model:EnableMatrix("RenderMultiply", self.m_matrix)
			end
		end
	end
	function b:OnTrapTrigger( )
		if CLIENT then
			self:EmitSound("ambient/machines/spin_loop.wav")
		end
		self.i_target = CurTime() + .3
	end
	if SERVER then
		function b:OnTrapThink()
			if (self.i_target or 0) < CurTime() then
				for _,ent in ipairs(self:GetEnemiesOn()) do
					if not Building.CanTarget( ent ) then continue end
					ent:EmitSound("ambient/machines/slicer" .. math.random(1,3) .. ".wav")
					local dm = self:DamageInfo()
					dm:SetDamage( damage )
					dm:SetDamageType( DMG_SLASH )
					ent:TakeDamageInfo( dm )
				end
				self.i_target = CurTime() + .2
			end
		end
	end

	function b:OnTrapEnd()
		if CLIENT then
			self:EmitSound("ambient/machines/spindown.wav")
			self:StopSound("ambient/machines/spin_loop.wav")
		end
	end

local mat = Material("yawd/models/trap_base")

local hatch_size = 37
if SERVER then return b end

function b:OnRemove()
	SafeRemoveEntity(self.t_model)
	self:StopSound("ambient/machines/spin_loop.wav")
end
local mat,mat2 = Material("yawd/models/trap_squre"),Material("yawd/models/trap_blade")
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase(mat2)
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
			self.t_model:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 50 - 40)))
			self.t_model:SetBodygroup( 1, 1 )
			self.t_model:SetModelScale(1, 0)
			local mat = Matrix()
			mat:Scale(Vector(1,1,1))
			self.t_model:EnableMatrix("RenderMultiply", mat)

			self.t_model:DrawModel()
			local a = self.t_model:GetAngles().y
			self.t_model:SetRenderAngles(Angle(0,(a + FrameTime() * 700) % 360,0))
		end
	else -- Within Animation
		if self.t_model then
			local n = 0.4 + self.i_hatch * 0.6
			local mat = Matrix()
				mat:Scale(Vector(n,n,n))
			self.t_model:EnableMatrix("RenderMultiply", mat)
		end
		if self.t_model and self.i_hatch >0.8 then -- There can be some cliping problems over 0.7
			self.t_model:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 50 - 40)))
			self.t_model:DrawModel()
			self.t_model:SetBodygroup( 1, 0 )
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
	self:RenderBase(mat2)
	self:RenderTrapArea()

	local h_vec =  Vector(0,hatch_size,1.9)
	local h2_vec = -Vector(hatch_size,hatch_size,1.8)
		render.SetMaterial(mat)
		render.DrawBox(self:GetPos(), self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
		render.DrawBox(self:GetPos() + self:GetAngles():Forward() * hatch_size, self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
end
return b
