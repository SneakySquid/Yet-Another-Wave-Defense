local DEBUFF = Debuff.New()

function DEBUFF:Initialize()
	self.IgniteTime = 7.5
	self.BurnDamage = 50

	self.DamageTimer = util.Timer()
	self.RemoveTimer = util.Timer(self.IgniteTime)
end

function DEBUFF:Think()
	if SERVER then
		local target = self:GetTarget()

		if self.RemoveTimer:Elapsed() then
			PrintTable(self.RemoveTimer)
			target:RemoveDebuff(DEBUFF_BURNING)
			return
		end

		if self.DamageTimer:Elapsed() then
			local dmg_info = DamageInfo()

			dmg_info:SetDamageType(bit.bor(DMG_BURN, DMG_DISSOLVE))
			dmg_info:SetDamage(self.BurnDamage)

			dmg_info:SetAttacker(Entity(0))
			dmg_info:SetInflictor(Entity(0))

			target:TakeDamageInfo(dmg_info)

			if target:Health() <= 0 then
				target:RemoveDebuff(DEBUFF_BURNING)
				return
			end

			self.DamageTimer:Start(1)
		end
	end
end

function DEBUFF:DrawEffect()
end

function DEBUFF:OnApplied(target)
	if SERVER then
		target:Ignite(self.IgniteTime)
	end
end

function DEBUFF:OnRemoved(target)
	if SERVER then
		target:Extinguish()
	end
end

DEBUFF_BURNING = Debuff.Register(DEBUFF)
