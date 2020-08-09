-- Simple Spikes

local b = {}
b.Name = "Explosives"
b.Icon = Material("yawd/hud/explosive.png")
b.BuildClass = {CLASS_BOMBER}
b.Cost = 1100
-- b.TrapArea

local damage = 555 -- This gets x 50

b.TrapTriggerTime = 1	-- Time it takes to trigger
b.TrapResetTime = 20	-- Time it takes to reset
b.TrapDurationTime = 2	-- Time it takes to stop

local mdl = Model("models/props_c17/oildrum001_explosive.mdl")
-- Trap logic
	function b:Init()
		if CLIENT then
			if not self.t_model then
				self.t_model = ClientsideModel(mdl)
				self.t_model:SetPos(self:GetPos())
				self.t_model:SetNoDraw(true)
			end
		else
			self.b_spawned = false
		end
	end
	function b:OnTrapTrigger( )
		if CLIENT then
			self:EmitSound("ambient/machines/thumper_shutdown1.wav")
		end
	end
	function b:OnTrapEnd()
		if CLIENT then
			self:EmitSound("npc/scanner/cbot_discharge1.wav")
		end
	end

if SERVER then
	function b:OnDisabled()
		if self.e_barrel and IsValid(self.e_barrel) then
			SafeRemoveEntity(self.e_barrel)
		end
	end
	function b:Think()
		-- In case this trap is disabled, remove the barrel.
		if self:GetDisabled() then
			self.i_duration = nil
			return
		end
		-- Start timer if we don't have a barrel anymore
		if not (self.e_barrel and IsValid(self.e_barrel)) then
			if self.b_spawned then
				self.n_Timer = CurTime() + self.TrapResetTime
				self.b_spawned = false
			elseif not self.i_duration then
				if (self.n_Timer or 0) > CurTime() then return end
				self.i_duration = CurTime() + self.TrapDurationTime
				-- Tell the client we're spawning a barrel
				net.Start("yawd.traptrigger")
					net.WriteEntity(self)
					net.WriteInt(0, 32)
				net.Broadcast()
			elseif self.i_duration <= CurTime() then
				self.i_duration = nil
				-- Spawn barrel
				local e = ents.Create("yawd_explosive")
					e:SetPos(self:GetPos())
					e:SetAngles(self:GetAngles())
					e.building = self
					e.damage = damage
					e:Spawn()
				self.b_spawned = true
				self.e_barrel = e
			end
		end
	end
	function b:OnRemove()
		if not self.e_barrel or not IsValid(self.e_barrel) then return end
		SafeRemoveEntity(self.e_barrel)
	end
end

local mat = Material("yawd/models/trap_base")
if SERVER then return b end

function b:OnRemove()
	SafeRemoveEntity(self.t_model)
end

local function IsNearLocal(self)
	if not IsValid(LocalPlayer()) then return false end
	local dis = LocalPlayer():GetPos():DistToSqr(self:GetPos())
	return dis < 1305339
end

local mat,mat2 = Material("yawd/models/trap_squre2"),Material("models/props_wasteland/lighthouse_stairs")
local hatch_size = 18.5
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase()
	-- Render the barrel animation
	local h_vec =  Vector(0,hatch_size,1.8)
	local h2_vec = -Vector(hatch_size,hatch_size,1.8)
	local r_a = self:LocalToWorldAngles(Angle(0,180,0))
	if not self.i_hatch then
		self.i_hatch = 0
	end
	if self:DurationProcent() > 0 then
		self.i_hatch = math.min((1 - self:DurationProcent()) * 10, 1)
	elseif self.i_hatch > 0 then
		self.i_hatch = math.max(0, (self.i_hatch or 0) - FrameTime() * 0.5)
	end
	if IsNearLocal(self) then
		render.SetMaterial(mat)
		if self.i_hatch <= 0 then
			render.DrawBox(self:GetPos(), self:GetAngles(), h2_vec, h_vec, Color(0,0,0))
			render.DrawBox(self:GetPos(), r_a, h2_vec, h_vec, Color(0,0,0))
		else
			local r_model = self.t_model and (self:DurationProcent() > 0 or self.i_hatch > 0.9)
			Building.StencilMask()
			-- Render the mask
				render.DrawBox(self:GetPos(), self:GetAngles(), Vector(-hatch_size,-hatch_size,-1.8), Vector(hatch_size,hatch_size,1.8), Color(0,0,0))
			Building.StencilRender()
			-- Render stuff
				--Sides
				render.SetMaterial(mat2)
				render.DrawBox(self:GetPos(), self:GetAngles(), Vector(hatch_size,hatch_size,0), -Vector(hatch_size,hatch_size,100), color_white)
				-- Hatch
				local n = hatch_size * self.i_hatch
				render.SetMaterial(mat)
				render.DrawBox(self:GetPos(), self:GetAngles(), Vector(-hatch_size - n,-hatch_size,-1.8), Vector(-n,hatch_size,1.8), Color(0,0,0))
				render.DrawBox(self:GetPos(), r_a, Vector(-hatch_size - n,-hatch_size,-1.8), Vector(-n,hatch_size,1.8), Color(0,0,0))

				if r_model then
					self.t_model:SetRenderOrigin(self:LocalToWorld(Vector(0,0,self:DurationProcent() * -50)))
					self.t_model:SetRenderAngles(self:GetAngles())
					self.t_model:DrawModel()
				end
			Building.StencilEnd()
			if r_model then
				self.t_model:DrawModel()
			end
		end
	end
end
function b:DrawSelection( )
	self:RenderBase()
end
return b
