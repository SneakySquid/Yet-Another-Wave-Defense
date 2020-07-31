-- Simple Spikes

local b = {}
b.Name = "Crusher"
b.Icon = Material("yawd/hud/crusher.png")
b.Health = -1
b.CanBuild = true
b.BuildClass = {CLASS_JUGGERNAUT, CLASS_HEALER, CLASS_RUNNER, CLASS_FIGHTER }
b.Cost = 750

local damage = 75 -- This allows to balance traps

b.BuildingSize = {-Vector(95, 95, 12), Vector(95, 95, 12)}
b.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}

b.TrapTriggerTime = 0.5	-- Time it takes to trigger
b.TrapResetTime = 7		-- Time it takes to reset
b.TrapDurationTime = 4	-- Time it takes to stop

function b:OnTrapThink() end
function b:OnTrapTrigger( tListOfEnemies )
	if SERVER then
		local dm = self:DamageInfo()
		dm:SetDamage( damage )
		dm:SetDamageType( DMG_CRUSH )
		self.t_List = {}
		for k,v in ipairs( tListOfEnemies ) do
			v:TakeDamageInfo( dm )
			table.insert(self.t_List, v)
			if v.SetMaxSpeed then
				v:SetMaxSpeed( 0 )
			end
		end
	else
		self:EmitSound("physics/concrete/boulder_impact_hard" .. math.random(1,3) .. ".wav")
		self.triggered = true
	end
end
if CLIENT then
	function b:OnTrapEnd()
		self:EmitSound("physics/metal/metal_box_strain" .. math.random(1,4) .. ".wav", 100, 100, 0.4)
		self.triggered = nil
	end
else
	function b:OnTrapEnd()
		for k,v in ipairs( self.t_List or 0 ) do
			if not IsValid(v) then continue end
			if v.SetMaxSpeed then
				v:SetMaxSpeed( v.NPC_DATA and v.NPC_DATA.MoveSpeed or 16 )
			end
		end
	end
end

local mat,mat2 = Material("yawd/models/trap_crusher"),Material("yawd/models/trap_crusher_part")
b.retract = 0
function b:DrawSelection( )
	self:RenderBase(mat)
	self:RenderTrapArea()
end
local height = Vector(0,0,1.75)
function b:Draw()
	-- Renders the bottom of the trap
	if self.triggered then
		self.retract = math.min(self.retract + FrameTime() * 5, 1)
	elseif self.retract > 0 then
		self.retract = math.max(self.retract - FrameTime() * 1, 0)
	end
	if self.retract <= 0 then 
		self:RenderBase(mat)
		self:RenderTrapArea()
		return 
	end
	self:RenderBase()
	self:RenderTrapArea()
	render.SetMaterial(mat2)
	render.DrawBox(self:LocalToWorld(height), self:LocalToWorldAngles(Angle(0,90,-90 * self.retract)), self:OBBMins() - height, Vector(self:OBBMaxs().x,0,self:OBBMaxs()), color_white)
	render.DrawBox(self:LocalToWorld(height), self:LocalToWorldAngles(Angle(0,90,90 * self.retract)), Vector(self:OBBMins().x,0,self:OBBMins()) - height, self:OBBMaxs(), color_white)
end
return b
