function ENT:Align(max_distance)
	local group = self:GetGroup()
	if (#group <= 1) then return vector_origin end

	local count = 0
	local total = Vector()
	local pos = self:GetPos()

	for i, boid in ipairs(group) do
		local distance = pos:Distance(boid:GetPos())

		if (distance > 0 and distance < max_distance) then
			total:Add(boid:GetVelocity())
			count = count + 1
		end
	end

	if (count > 0) then
		total:Div(count)
		total:Normalize()
		total:Mul(self:GetMaxSpeed())

		local steer = total - self:GetVelocity()
		steer:Limit(self:GetMaxSteeringForce())

		return steer
	end

	return vector_origin
end

function ENT:Cohesion(desired_distance)
	local group = self:GetGroup()
	if (#group <= 1) then return vector_origin end

	local count = 0
	local total = Vector()
	local pos = self:GetPos()

	for i, boid in ipairs(group) do
		local distance = pos:Distance(boid:GetPos())

		if (distance > 0 and distance < desired_distance) then
			total:Add(boid:GetPos())
			count = count + 1
		end
	end

	if (count > 0) then
		total:Div(count)
		return self:Seek(total)
	end

	return vector_origin
end

function ENT:Seek(target)
	local desired = target - self:GetPos()
	desired:Normalize()
	desired:Mul(self:GetMaxSpeed())

	local steer = desired - self:GetVelocity()
	steer:Limit(self:GetMaxSteeringForce())

	return steer
end

function ENT:Seperate(desired_seperation)
	local group = self:GetGroup()
	if (#group <= 1) then return vector_origin end

	local count = 0
	local steer = Vector()
	local pos = self:GetPos()

	for i, boid in ipairs(group) do
		local distance = pos:Distance(boid:GetPos())

		if (distance > 0 and distance < desired_seperation) then
			local diff = pos - boid:GetPos()
			diff:Normalize()
			diff:Div(distance)

			steer:Add(diff)
			count = count + 1
		end
	end

	if (count > 0) then
		steer:Div(count)
	end

	if (steer:Length() > 0) then
		steer:Normalize()
		steer:Mul(self:GetMaxSpeed())
		steer:Sub(self:GetVelocity())
		steer:Limit(self:GetMaxSteeringForce())
	end

	return steer
end
