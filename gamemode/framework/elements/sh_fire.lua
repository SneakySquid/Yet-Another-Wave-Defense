local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(bit.bor(DMG_BURN, DMG_DISSOLVE))

	self:SetWeakAgainst(ELEMENT_WATER, ELEMENT_ROCK, ELEMENT_FIRE)
	self:SetStrongAgainst(ELEMENT_SCOURGE, ELEMENT_ICE, ELEMENT_GRASS)
	self:SetImmuneAgainst(ELEMENT_SCOURGE)
end

function ELEMENT:OnInteractWith(target, other, dmg_info)
	if target:HasDebuff(DEBUFF_SOAKED) then
		target:RemoveDebuff(DEBUFF_SOAKED)

		util.BlastDamage(
			dmg_info:GetInflictor(),
			dmg_info:GetAttacker(),
			dmg_info:GetDamagePosition(),
			100,
			75
		)

		-- EffectData stuff here
	else
		target:AddDebuff(DEBUFF_BURNING)
	end

	target:RemoveDebuff(DEBUFF_INFECTED)
end

ELEMENT_FIRE = Element.Register(ELEMENT)
