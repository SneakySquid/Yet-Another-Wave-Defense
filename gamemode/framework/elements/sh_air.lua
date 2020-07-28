local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(bit.bor(DMG_SONIC, DMG_NEVERGIB))

	self:SetWeakAgainst(ELEMENT_ROCK, ELEMENT_SHOCK)
	self:SetStrongAgainst(ELEMENT_GRASS)
	self:SetImmuneAgainst(0)
end

function ELEMENT:OnInteractWith(target, other, dmg_info)
	if other == ELEMENT_ROCK then return end

	local attacker = dmg_info:GetInflictor()
	if not attacker:IsValid() then attacker = dmg_info:GetAttacker() end

	local attack_dir = dmg_info:GetDamagePosition() - attacker:GetPos()
	attack_dir:Normalize()

	target:SetVelocity(attack_dir * 50)
end

ELEMENT_AIR = Element.Register(ELEMENT)
