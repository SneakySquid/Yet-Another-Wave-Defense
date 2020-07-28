local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(DMG_SLASH)

	self:SetWeakAgainst(ELEMENT_AIR, ELEMENT_SCOURGE, ELEMENT_FIRE, ELEMENT_GRASS)
	self:SetStrongAgainst(ELEMENT_ROCK, ELEMENT_WATER)
	self:SetImmuneAgainst(0)
end

function ELEMENT:OnInteractWith(target, other, dmg_info)
end

ELEMENT_GRASS = Element.Register(ELEMENT)
