local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(DMG_CLUB)

	self:SetWeakAgainst(ELEMENT_FIRE, ELEMENT_WATER, ELEMENT_ICE)
	self:SetStrongAgainst(ELEMENT_ROCK, ELEMENT_GRASS)
	self:SetImmuneAgainst(0)
end

function ELEMENT:OnInteractWith(target, other, dmg_info)
	if target:HasDebuff(DEBUFF_SOAKED) then
		target:AddDebuff(DEBUFF_FROZEN)
	end

	target:RemoveDebuff(DEBUFF_BURNING)
end

ELEMENT_ICE = Element.Register(ELEMENT)
