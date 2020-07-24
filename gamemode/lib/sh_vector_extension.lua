local VECTOR = FindMetaTable("Vector")

function VECTOR:Limit(max)
	local lSq = self:Length2DSqr()

	if (lSq > max * max) then
		self:Div(math.sqrt(lSq))
		self:Mul(max)
	end
end
