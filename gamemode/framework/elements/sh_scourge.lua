local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(DMG_POISON)

	self:SetWeakAgainst(ELEMENT_FIRE, ELEMENT_WATER)
	self:SetStrongAgainst(ELEMENT_NONE, ELEMENT_GRASS)
	self:SetImmuneAgainst(0)
end

function ELEMENT:OnInteractWith(target, other, dmg_info)
	if not target:HasDebuff(DEBUFF_BURNING) then
		target:AddDebuff(DEBUFF_INFECTED)
	end
end

ELEMENT_SCOURGE = Element.Register(ELEMENT)
