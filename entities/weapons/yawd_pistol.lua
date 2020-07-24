SWEP.Base = "weapon_base"
SWEP.PrintName = "Pistol"
SWEP.Author = "YAWD Team"
SWEP.Category = "YAWD"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.m_WeaponDeploySpeed = 1

SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.DrawCrosshair = true
SWEP.DrawAmmo = true
SWEP.Weight = 5

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false

SWEP.UseHands = true
SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.HoldType = "pistol"

SWEP.PrimaryDelay = 0.4
SWEP.PrimarySpread = Vector(0.03, 0.01, 0)
SWEP.PrimaryDamage = {
	min = 7,
	max = 14,
}
SWEP.PrimaryForce = 1
SWEP.PrimaryMaxDistance = 56756
SWEP.PrimarySound = "weapons/pistol/pistol_fire3.wav"
SWEP.PrimaryViewPunch = {
	p = {
		min = -4,
		max = -7,
	},
	y = {
		min = -1,
		max = 1,
	},
}

SWEP.SecondaryDelay = 1

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()

end

function SWEP:Holster()

end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then
		return
	end

	local owner = self:GetOwner()
	local bullet_info = {
		Attacker = owner,
		Damage = math.random(self.PrimaryDamage.min, self.PrimaryDamage.max),
		Force = self.PrimaryForce,
		Distance = self.PrimaryMaxDistance,
		Num = 1,
		Dir = owner:GetAimVector(),
		Spread = self.PrimarySpread,
		Src = owner:GetShootPos(),
	}

	self:FireBullets(bullet_info)
	self:EmitSound(self.PrimarySound, 75, 100, 1, CHAN_WEAPON)
	self:ViewPunch()

	self:SetNextPrimaryFire(CurTime() + self.PrimaryDelay)
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then
		return
	end

	self:SetNextSecondaryFire(CurTime() + self.SecondaryDelay)
end

function SWEP:Reload()

end

function SWEP:ViewPunch()
	local owner = self:GetOwner()
	local viewpunch = self.PrimaryViewPunch

	owner:ViewPunch(Angle(
		math.random(viewpunch.p.min, viewpunch.p.max),
		math.random(viewpunch.y.min, viewpunch.y.max),
		0
	))
end
