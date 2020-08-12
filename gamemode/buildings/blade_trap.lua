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
	if CLIENT then
		local function on_create(self, c_ent)
			c_ent:SetPos(self:GetPos())
			c_ent:SetNoDraw(true)
			c_ent:EnableMatrix("RenderMultiply", self.m_matrix)
		end
		function b:Init()	
			self.i_hatch = 0
			self.m_matrix = Matrix()
			self.m_matrix:Scale(Vector(0.7,0.7,0.7))
			self:CreateClientMdl( mdl, on_create )
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
	self:StopSound("ambient/machines/spin_loop.wav")
end
local mat,mat2 = Material("yawd/models/trap_squre"),Material("yawd/models/trap_blade")
local switch = true
function b:Draw()
	-- Calculates the hatch
	if self:DurationProcent() > 0 then
		self.i_hatch = math.min((1 - self:DurationProcent()) * 10, 1)
	else
		self.i_hatch = math.max(0, self.i_hatch - FrameTime() * 1)
	end
	-- Turns the light on or off.
	local b = self:DurationProcent() > 0
	if switch ~= b then
		switch = b
		if b then
			mat2:SetInt("$detailblendfactor", 1)
			mat2:SetTexture("$detail", "yawd/models/trap_blade_selfillum")
		else
			mat2:SetFloat("$detailblendfactor", 0.1)
			mat2:SetTexture("$detail", "yawd/models/trap_blade")
		end
	end
	-- Renders the bottom of the trap.
	self:RenderBase(mat2)

	local r_a = self:LocalToWorldAngles(Angle(0,180,0))
	local h_vec =  Vector(0,hatch_size,1.8)
	local h2_vec = -Vector(hatch_size,hatch_size,1.8)
	local c_ent = self:GetClientMdl( mdl )
	if self.i_hatch <= 0 then
		render.SetMaterial(mat)
		render.DrawBox(self:GetPos(), self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
		render.DrawBox(self:GetPos(), r_a, h2_vec, h_vec, Color(0,0,0))
	elseif self.i_hatch >= 1 then
		render.SetMaterial(mat)
		render.DrawBox(self:GetPos(), self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
		render.DrawBox(self:GetPos(), r_a, h2_vec, h_vec, Color(0,0,0))
		if c_ent and IsValid( c_ent ) then
			c_ent:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 50 - 40)))
			c_ent:SetBodygroup( 1, 1 )
			c_ent:SetModelScale(1, 0)
			local mat = Matrix()
			mat:Scale(Vector(1,1,1))
			c_ent:EnableMatrix("RenderMultiply", mat)

			c_ent:DrawModel()
			local a = c_ent:GetAngles().y
			c_ent:SetRenderAngles(Angle(0,(a + FrameTime() * 700) % 360,0))
		end
	else -- Within Animation
		if c_ent and IsValid( c_ent ) then
			local n = 0.4 + self.i_hatch * 0.6
			local mat = Matrix()
				mat:Scale(Vector(n,n,n))
			c_ent:EnableMatrix("RenderMultiply", mat)
			if self.i_hatch >0.8 then
				c_ent:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 50 - 40)))
				c_ent:DrawModel()
				c_ent:SetBodygroup( 1, 0 )
			end
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
			if c_ent and IsValid( c_ent ) and self.i_hatch <= 0.9 then
				local mdl_h = 40
				c_ent:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self.i_hatch * 40 - mdl_h)))
				c_ent:DrawModel()
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
