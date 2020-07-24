AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

list.Set("NPC", "yawd_npc_base", {
	Name = "Base",
	Category = "YAWD",
	Class = "yawd_npc_base",
})

AccessorFunc(ENT, "m_Mass", "Mass") -- Measured in kg
AccessorFunc(ENT, "m_Target", "Target") -- This should be an entity
AccessorFunc(ENT, "m_MaxSpeed", "MaxSpeed") -- max velocity in m/s
AccessorFunc(ENT, "m_Momentum", "Momentum") -- This is set internally, get returns kg m/s.
AccessorFunc(ENT, "m_Attacking", "Attacking") -- Boolean if Target isn't null
AccessorFunc(ENT, "m_Ragdolled", "Ragdolled") -- Boolean if ent is ragdolled
AccessorFunc(ENT, "m_Controller", "Controller") -- Controller object, set with ENT:InitController
AccessorFunc(ENT, "m_AimDistance", "AimDistance") -- maximum detection range for entities
AccessorFunc(ENT, "m_Acceleration", "Acceleration") -- Acceleration measure in m/s
AccessorFunc(ENT, "m_SteeringForce", "SteeringForce") -- Max steering force in m/s

function ENT:Initialize()
	-- set these ones yourself in inherited entities
	self:SetMass(80) -- set mass to 80kg
	self:SetMaxSpeed(10) -- measured in m/s, 5 m/s = 250 units
	--self:SetController(nil) -- use ENT:InitController to set this
	self:SetAimDistance(50) -- How far away the ent can detect players, measured in meters
	self:SetSteeringForce(500) -- How fast an entity can turn, measured in m/s

	-- leave these ones alone
	self:SetMomentum(0) -- measured in kg m/s, set internally
	self:SetTarget(NULL) -- target should always be an entity even if it is NULL
	self:SetAttacking(false) -- set internally, use to check if the ent has a target
	self:SetRagdolled(false) -- set internally, unragdolls when momentum = 0
	self:SetAcceleration(Vector()) -- acceleration vector for movement

	if CLIENT then
		hook.Add("PreDrawHalos", self, self.DrawHalo) -- shitcode alert
	end

	if SERVER then
		self:SetModel("models/combine_soldier.mdl")

		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_STEP)
		self:PhysicsInit(SOLID_VPHYSICS)

		self:PhysWake()
	end

	self:InitController(Building.GetCore():GetPos(), 0, 0)
end

if CLIENT then
	ENT.HaloColour = Color(234, 60, 83) -- team.GetColor(TEAM_ATTACKER) -- not defined yet smh, manual include master race

	function ENT:DrawHalo()
		halo.Add({self}, self.HaloColour)
	end
end

function ENT:InitController(target, jump_down, jump_up)
	local controller = Controller.New(target, jump_down, jump_up)

	if controller then
		local path = Controller.RequestEntityPath(self, target, jump_down, jump_up)
		if path then
			DebugMessage(string.format("Generated initial path for %s.", self))
			controller:SetPath(path)
		end

		self:SetController(controller)
	end
end

function ENT:CalculateVelocity()
	local velocity = self:GetVelocity()
	local speed = velocity:Length()

	-- speed is hammer units, speed*2 is cm/s, divide by 100 for m/s
	local mps = speed * 2 / 100

	self:SetMomentum(mps * self.m_Mass)

	if self.m_Ragdolled then
		if self.m_Momentum == 0 then
			self:SetRagdolled(false)
		end

		return true
	else
		if false and self.m_Momentum > y then
			self:SetRagdolled(true)
			return true
		end
	end

	local controller = self:GetController()
	if not controller then return false end

	local goal = controller:GetGoal()

	if not goal then
		local new_path = Controller.RequestEntityPath(self, target, jump_down, jump_up)

		if new_path then
			DebugMessage(string.format("Generated new path for %s.", self))
			controller:SetPath(new_path)

			goal = controller:GetGoal()

			if not goal then
				DebugMessage("Failed to set new goal.")
				return false
			end
		else
			DebugMessage(string.format("Failed to generate new path for %s.", self))

			if SERVER then
				self:Remove()
			end

			return false
		end
	end

	local current_pos = self:GetPos()
	local dist = goal:DistToSqr(current_pos)

	local acceleration = self.m_Acceleration
	local max_speed = self.m_MaxSpeed * 100 * 0.5
	local steering_force = self.m_SteeringForce * 100 * 0.5

	if dist <= max_speed * max_speed then
		local finished = controller:NextGoal()

		if finished then
			DebugMessage(string.format("%s reached the end of the path, removing.", self))

			if SERVER then self:Remove() end

			return false
		end

		DebugMessage(string.format("%s is moving to %s.", self, controller:GetGoal()))
	end

	local desired = goal - current_pos
	desired:Normalize()
	desired:Mul(max_speed)

	local steer = desired - velocity
	steer:Limit(steering_force)

	acceleration:Add(steer)
--	acceleration.z = 0

	velocity:Add(acceleration)
	velocity:Limit(max_speed)

	return velocity
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:HandleAnimation(velocity)
	local speed = velocity:Length()

	if speed <= 0 then
		self:ResetSequence(ACT_IDLE)
	elseif speed <= self.m_MaxSpeed * 100 * 0.25 then
		self:ResetSequence(ACT_WALK)
	else
		self:ResetSequence(ACT_RUN)
	end

	self:SetAngles(velocity:Angle())
end

function ENT:Think()
	self:SetSequence(ACT_IDLE)

	local velocity = self:CalculateVelocity()
	if not velocity then return end

	self:SetVelocity(velocity)
	self:HandleAnimation(velocity)

	self:NextThink(CurTime())

	return true
end
