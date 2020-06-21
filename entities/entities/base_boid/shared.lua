include("sh_behaviours.lua")

do
	ENT.Base = "base_gmodentity"
	ENT.Type = "anim"

	ENT.Category = "YAWD Entities"
	ENT.Spawnable = true
	ENT.AdminOnly = true

	ENT.PrintName = "Base Boid"
end

do
	AccessorFunc(ENT, "m_Group", "Group")
	AccessorFunc(ENT, "m_Leader", "Leader")

	AccessorFunc(ENT, "m_MaxSpeed", "MaxSpeed", FORCE_NUMBER)
	AccessorFunc(ENT, "m_MaxSteeringForce", "MaxSteeringForce", FORCE_NUMBER)

	AccessorFunc(ENT, "m_AvoidanceRadius", "AvoidanceRadius", FORCE_NUMBER)
	AccessorFunc(ENT, "m_PerceptionRadius", "PerceptionRadius", FORCE_NUMBER)
end

function ENT:Initialize()
	self:SetMaxSpeed(3)
	self:SetMaxSteeringForce(2)

	self:SetPerceptionRadius(2.5)
	self:SetAvoidanceRadius(1)

	if (SERVER) then
		self:SetModel("models/manhack.mdl")

		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_STEP)
		self:PhysicsInit(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()

		if (IsValid(phys)) then
			phys:Wake()
		end
	end

	self.ViewDirections = self:CalculateViewDirections(300)
end

function ENT:ApplyForce(force)
	local acc = self:GetAcceleration()
	acc:Add(force)
end

function ENT:CalculateViewDirections(view_directions)
	local points = {}

	local golden = (1 + math.sqrt(5)) / 2
	local angle = 2 * math.pi * golden

	for i = 1, view_directions do
		local t = i / view_directions
		local phi = math.acos(1 - 2 * t)
		local theta = angle * i

		local v = Vector(
			math.sin(phi) * math.cos(theta),
			math.sin(phi) * math.sin(theta),
			math.cos(phi)
		)

		table.insert(points, v)
	end

	return points
end

function ENT:IsLeader()
	return self == self:GetLeader()
end
