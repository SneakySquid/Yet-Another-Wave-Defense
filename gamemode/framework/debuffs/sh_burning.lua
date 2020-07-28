local DEBUFF = Debuff.New()

function DEBUFF:Initialize()
	self.InitializeTime = CurTime()
	self.IgniteTime = 5
end

function DEBUFF:Think()
	if CurTime() > self.InitializeTime + self.IgniteTime then return end

	local target = self:GetTarget()
	target:RemoveDebuff(DEBUFF_BURNING)
end

function DEBUFF:DrawEffect()
end

function DEBUFF:OnApplied(target)
	target:Ignite(self.IgniteTime)
end

function DEBUFF:OnRemoved(target)
end

DEBUFF_BURNING = Debuff.Register(DEBUFF)
