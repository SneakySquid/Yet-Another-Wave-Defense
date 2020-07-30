-- Simple Spikes

local b = {}
b.Name = "Spikes"
b.Icon = Material("yawd/hud/spikes.png")
b.Health = -1
b.CanBuild = true
b.BuildClass = {CLASS_CONSTRUCTOR, CLASS_JUGGERNAUT}
b.Cost = 350

local damage = 50 -- This allows to balance traps

b.BuildingSize = {-Vector(95, 95, 12), Vector(95, 95, 12)}
b.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}

b.TrapTriggerTime = 0.5	-- Time it takes to trigger
b.TrapResetTime = 7		-- Time it takes to reset
b.TrapDurationTime = 1	-- Time it takes to stop

function b:OnTrapThink() end
function b:OnTrapTrigger( tListOfEnemies )
	if SERVER then
		local dm = self:DamageInfo()
		dm:SetDamage( damage )
		dm:SetDamageType( DMG_SLASH )
		for k,v in ipairs( tListOfEnemies ) do
			v:TakeDamageInfo( dm )
			v:EmitSound("npc/manhack/grind_flesh" .. math.random(1,3) .. ".wav", 100)
		end
	else
		self:EmitSound("npc/strider/strider_skewer1.wav", 100, 100, 0.4)
		self.triggered = true
	end
end
if CLIENT then
	function b:OnTrapEnd()
		self:EmitSound("npc/strider/strider_skewer1.wav", 100, 100, 0.4)
		self.triggered = nil
	end
end

local mat = Material("yawd/spike.png")
local mat2 = Material("yawd/models/trap_spike")
b.retract = 0
local spike_length = 50
function b:DrawSelection( )
	self:RenderBase(mat2)
	self:RenderTrapArea()
	render.SetMaterial(mat)
	local ep = EyePos()
	local r_t = {}
	for x = -3, 3 do
		for y = -3, 3 do
			local pos = self:LocalToWorld(Vector(x * 19, y * 19, self:OBBMaxs().z))
			table.insert(r_t, {pos,ep:DistToSqr(pos)})
		end
	end
	table.sort(r_t, function(a,b) return a[2]>b[2] end)
	local n = self:GetAngles():Up()
	for k,v in ipairs(r_t) do
		render.DrawBeam(v[1],v[1] + n * spike_length, 5, 1, 0, self.CanAfford and Color(0,255,0) or Color(255,0,0))
	end
end
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase(mat2)
	self:RenderTrapArea()
	if self.triggered then
		self.retract = math.min(self.retract + FrameTime() * 500, spike_length)
	elseif self.retract > 0 then
		self.retract = math.max(self.retract - FrameTime() * 300, 0)
	end
	if self.retract <= 0 then return end
	render.SetMaterial(mat)
	local ep = EyePos()
	local r_t = {}
	for x = -3, 3 do
		for y = -3, 3 do
			local pos = self:LocalToWorld(Vector(x * 19, y * 19, self:OBBMaxs().z))
			table.insert(r_t, {pos,ep:DistToSqr(pos)})
		end
	end
	table.sort(r_t, function(a,b) return a[2]>b[2] end)
	local r_e = self.retract / spike_length
	local n = self:GetAngles():Up()
	for k,v in ipairs(r_t) do
		render.DrawBeam(v[1],v[1] + n * self.retract, 5, r_e, 0, Color(255,255,255))
	end
end
return b
