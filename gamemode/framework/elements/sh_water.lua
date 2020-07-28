local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(DMG_DIRECT)

	self:SetWeakAgainst(ELEMENT_WATER, ELEMENT_GRASS)
	self:SetStrongAgainst(ELEMENT_FIRE, ELEMENT_ROCK, ELEMENT_SCOURGE)
	self:SetImmuneAgainst(0)
end

local WetTargets = {}

function ELEMENT:OnInteractWith(target, other, dmg_info)
	target:RemoveDebuff(DEBUFF_BURNING)
	target:RemoveDebuff(DEBUFF_INFECTED)

	if other ~= ELEMENT_WATER then
		WetTargets[target] = WetTargets[target] or {}

		local wet_boys = WetTargets[target]
		local new = table.insert(wet_boys, CurTime())

		if new == 3 then
			if CurTime() - wet_boys[target][1] <= 5 then
				target:AddDebuff(DEBUFF_SOAKED)
			end

			WetTargets[target] = {}
		end
	end
end

ELEMENT_WATER = Element.Register(ELEMENT)
