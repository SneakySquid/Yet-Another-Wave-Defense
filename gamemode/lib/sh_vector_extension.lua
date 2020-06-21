local VECTOR = FindMetaTable("Vector")

function VectorRand2D()
	local ang = 2 * math.pi * math.random()

	return Vector(
		math.cos(ang),
		math.sin(ang),
		0
	)
end

function VECTOR:Heading()
	return math.deg(math.atan2(self.y, self.x))
end

function VECTOR:Limit(max)
	local lSq = self:Length2DSqr()

	if (lSq > max * max) then
		self:Div(math.sqrt(lSq))
		self:Mul(max)
	end
end
