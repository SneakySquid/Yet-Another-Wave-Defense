local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(DMG_CLUB)

	self:SetWeakAgainst(ELEMENT_ROCK)
	self:SetStrongAgainst(ELEMENT_FIRE, ELEMENT_ICE)
	self:SetImmuneAgainst(ELEMENT_SHOCK)
end

function ELEMENT:OnInteractWith(target, other, dmg_info)
	if target:HasDebuff(DEBUFF_FROZEN) then
		dmg_info:ScaleDamage(2)
	end
end

ELEMENT_ROCK = Element.Register(ELEMENT)
