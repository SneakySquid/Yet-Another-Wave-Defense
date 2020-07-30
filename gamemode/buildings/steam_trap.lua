-- Simple Spikes

local b = {}
b.Name = "Steam Trap"
b.Icon = Material("yawd/hud/steam_trap.png")
b.Health = -1
b.CanBuild = true
b.BuildClass = {CLASS_CONSTRUCTOR, CLASS_BOMBER}
b.Cost = 450

local damage = 35 -- This allows to balance traps

b.BuildingSize = {-Vector(95, 95, 12), Vector(95, 95, 12)}
b.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}

b.TrapTriggerTime = 1	-- Time it takes to trigger
b.TrapResetTime = 7		-- Time it takes to reset
b.TrapDurationTime = 1-- Time it takes to stop
function b:OnTrapThink() end
if SERVER then
	function b:OnTrapTrigger( tListOfEnemies )
		local dm = self:DamageInfo()
		dm:SetDamage( damage )
		dm:SetDamageType( DMG_SLASH )
		for k,v in ipairs( tListOfEnemies ) do
			--v:TakeDamageInfo( dm )
			if (v.i_lastpush or 0) > CurTime() then continue end
			v.i_lastpush = CurTime() + 1
			Building.ApplyTrapForce(v, Vector(0,0,450) + self:GetAngles():Forward() * 1000)
		end
	end
else
	function b:OnTrapTrigger( tListOfEnemies )
		self:EmitSound("ambient/gas/cannister_loop.wav", 100)
		self.triggered = true
		if not IsValid(self.emitter) then
			self.emitter = ParticleEmitter( self:GetPos() ) -- Particle emitter in this position
		end
	end
	function b:OnTrapEnd()
		self:StopSound("ambient/gas/cannister_loop.wav")
		self:EmitSound("ambient/gas/steam_loop1.wav",45)
		self.triggered = nil
		if IsValid(self.emitter) then
			self.emitter:Finish()
			self.emitter = nil
		end
	end
	function b:OnTrapThink()
		if not IsValid(self.emitter) then return end
		if (self.i_part or 0) > CurTime() then return end
		self.i_part = CurTime() + 0.5
		for i = 1, 20 do
			local n = math.random(1,16)
			if n < 10 then n = "0" .. n end
			local part = self.emitter:Add( "particle/smokesprites_00" .. n, self:GetPos() + Vector(0,0,10) ) -- Create a new particle at pos
			if ( part ) then
				part:SetDieTime( 3 ) -- How long the particle should "live"

				part:SetStartAlpha( 155 ) -- Starting alpha of the particle
				part:SetEndAlpha( 0 ) -- Particle size at the end if its lifetime

				part:SetStartSize( math.random(50,75) ) -- Starting size
				part:SetEndSize( 30 ) -- Size when removed

				part:SetGravity( Vector( 0, 0, 10 ) ) -- Gravity of the particle
				part:SetAirResistance(100)
				local v = VectorRand()
				v.z = 0
				part:SetVelocity( v * 450 ) -- Initial velocity of the particle
			end
		end
	end
	function b:OnTrapReset()
		self:StopSound("ambient/gas/steam_loop1.wav")
		self.emitter = nil
	end
end

local mat = Material("yawd/models/trap_push")
b.i_push = 0
function b:Draw()
	-- Renders the bottom of the trap
	if self.triggered then
		self.i_push = math.min(self.i_push * 0.08 + self.i_push + FrameTime(), 1)
	elseif self.i_push > 0 then
		self.i_push = math.max(self.i_push - FrameTime() * 2, 0)
	end
	if self.i_push <= 0 then
		self:RenderBase(mat)
	else
		self:RenderBase()
		render.SetMaterial(mat)
		local mi,ma = self:OBBMins(),self:OBBMaxs()
		render.DrawBox(self:LocalToWorld(Vector(self.i_push * 12.8,0,self.i_push * 49.4)), self:LocalToWorldAngles(Angle(0,270,self.i_push * -30)), Vector(mi.x,mi.y,-1), Vector(ma.x,ma.y,0), Color(255,255,255))
	end
	self:RenderTrapArea()
end
function b:DrawSelection( )
	self:RenderBase(mat)
	self:RenderTrapArea()
end
return b
