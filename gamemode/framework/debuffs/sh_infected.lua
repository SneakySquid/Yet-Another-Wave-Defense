local DEBUFF = Debuff.New()

function DEBUFF:Initialize()
end

function DEBUFF:Think()
end

function DEBUFF:DrawEffect()
end

function DEBUFF:OnApplied(target)
end

function DEBUFF:OnRemoved(target)
end

DEBUFF_INFECTED = Debuff.Register(DEBUFF)
