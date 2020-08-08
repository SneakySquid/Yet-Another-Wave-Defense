-- Lightning Rod

local b = {}
b.Name = "Lightning Rod"
b.Icon = Material("yawd/hud/lightning_rod.png")
b.Health = -1
b.CanBuild = true
b.BuildClass = {CLASS_HEALER}
b.Cost = 1200

local damage = 125 -- This allows to balance traps

b.BuildingSize = {-Vector(95, 95, 12), Vector(95, 95, 12)}
b.TrapArea = {-Vector(95 * 3, 95 * 3, 1.7), Vector(95 * 3, 95 * 3, 95)}

b.TrapTriggerTime = 1		-- Time it takes to trigger
b.TrapResetTime = 22.5			-- Time it takes to reset
b.TrapDurationTime = 0.5	-- Time it takes to stop

local mdl = "models/props_c17/utilitypole03a.mdl"
function b:Init()
	if CLIENT then
		if not self.t_model then
			self.t_model = ClientsideModel(mdl)
			self.t_model:SetPos(self:GetPos())
			self.t_model:SetNoDraw(true)
			self.t_model:SetModelScale(0.18)
		end
	end
end

local function FindNearestEnemy(pos, radius, t)
	local c,d
	for _,v in ipairs(ents.FindInSphere(pos, radius)) do
		if table.HasValue(t, v) then continue end
		if not Building.CanTarget( v ) then continue end
		local dis = pos:Distance( v:GetPos() )
		if not d or d > dis then
			d = dis
			c = v
		end
	end
	return c
end

function b:OnTrapThink() end
function b:OnTrapTrigger( tListOfEnemies )
	if SERVER then
		-- Find a randomish enemy
		local c
		for k,v in ipairs( tListOfEnemies ) do
			if IsValid(v) then
				c = v
			end
		end
		if not c then return false end -- No hit?
		-- Scan for 5-6 randomish enemies and list them
		local t = { c }
		for i = 1, math.random(5,6) do
			local c = FindNearestEnemy( c:GetPos(), 300, t)
			if not c then break end
			table.insert(t, c)
		end
		-- Damage the NPCs
		local dm = self:DamageInfo()
		dm:SetDamage( damage )
		dm:SetDamageType( DMG_SHOCK )
		for k,v in ipairs( t ) do
			v:TakeDamageInfo( dm )
			local n = math.random(1,9)
			if n == 4 then n = n + 1 end
			v:EmitSound("ambient/energy/zap" ..n .. ".wav", 100)
		end
		self:EmitSound("ambient/energy/weld" .. math.random(1, 2) .. ".wav")
		return t -- Tell the clients what NPC's are "on" the trap.
	else
		local last = self:LocalToWorld(Vector(0,0,50))
		self._tList = {last}
		for k,v in ipairs( tListOfEnemies ) do
			if not IsValid(v) then continue end
			local vp = v:GetPos()
			local mid = (last + vp) / 2
			table.insert(self._tList, mid + Vector(0,0,mid:Distance(vp)) / 2 )
			table.insert(self._tList, vp)
			last = vp
		end
	end
end
if CLIENT then
	function b:OnTrapEnd()
		self._tList = nil
	end
	function b:OnRemove()
		SafeRemoveEntity(self.t_model)
		if IsValid(self.emitter) then
			self.emitter:Finish()
			self.emitter = nil
		end
	end
end

local mat = Material("sprites/tp_beam001")
local mat2 = Material("yawd/models/trap_lightning")
local mat3 = Material("effects/strider_muzzle")

function b:DrawSelection( )
	self:RenderBase(mat2)
	self:RenderTrapArea()
end
function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase(mat2)
	self:RenderTrapArea()
	if self.t_model then -- There can be some cliping problems over 0.7
		self.t_model:SetRenderOrigin( self:GetPos() )
		self.t_model:SetRenderAngles( self:GetAngles() )
		self.t_model:DrawModel()
	end
	-- Render sparks
	if not IsValid(LocalPlayer()) then return end
	local dis = LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 100000
	if not (dis or self.i_reset or self:GetDisabled()) then
		if not IsValid(self.emitter) then
			self.emitter = ParticleEmitter( self:GetPos() ) -- Particle emitter in this position
		elseif (self.r_part or 0) < CurTime() then
			self.r_part = CurTime() + math.random(0.25, 2)
			local x_r = (math.random(0, 1) * 2 - 1) * 11.5
			local y_r = (math.random(0, 1) * 10.5)
			local part = self.emitter:Add( "effects/strider_muzzle", self:LocalToWorld(Vector(0,x_r,67 + y_r)) ) -- Create a new particle at pos
			if ( part ) then
				part:SetDieTime( 0.5 ) -- How long the particle should "live"
				part:SetRoll(math.random(360))

				part:SetStartAlpha( 155 ) -- Starting alpha of the particle
				part:SetEndAlpha( 0 ) -- Particle size at the end if its lifetime

				part:SetStartSize( math.random(10, 15) ) -- Starting size
				part:SetEndSize( 8 ) -- Size when removed

				part:SetGravity( Vector( 0, 0, 0 ) ) -- Gravity of the particle
			end
		end
	end
	-- Render trap trigger effect
	if not self._tList then return end -- No shock
	render.SetMaterial(mat3)
	render.DrawSprite(self:LocalToWorld(Vector(0,0,72)), 64, 64, Color(255,255,255,math.random(25,125)))

	render.SetMaterial(mat)
	render.StartBeam( #self._tList )
		local ep = 0
		for k,vp in ipairs( self._tList ) do
			if last then
				ep = ep + last:Distance(vp) / 100
			end
			render.AddBeam(vp, 16, ep, color_white)
			last = vp
		end
	render.EndBeam()
end
return b