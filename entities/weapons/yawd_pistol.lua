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
SWEP.ViewModel = "models/weapons/v_pist_fiveseven.mdl"
SWEP.WorldModel = "models/weapons/w_pist_fiveseven.mdl"
SWEP.HoldType = "pistol"
SWEP.ViewModelFlip = true

SWEP.Primary = {
	Ammo = "Pistol",
	ClipSize = 12,
	DefaultClip = 48,
	Automatic = true,
}

SWEP.Secondary = {}

SWEP.PrimaryDelay = 0.2
SWEP.PrimarySpread = Vector(0.03, 0.01, 0)
SWEP.PrimaryBulletsPerFire = 1
SWEP.PrimaryDamage = {
	min = 7,
	max = 14,
}
SWEP.PrimaryForce = 1
SWEP.PrimaryMaxDistance = 56756
SWEP.PrimarySound = "weapons/pistol/pistol_fire3.wav"
SWEP.PrimaryViewPunch = {
	p = {
		min = -1,
		max = -3,
	},
	y = {
		min = -1,
		max = 1,
	},
}

SWEP.SecondaryDelay = 1

SWEP.ReloadDelay = 1

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	return true
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
		Num = self.PrimaryBulletsPerFire,
		Dir = owner:GetAimVector(),
		Spread = self.PrimarySpread,
		Src = owner:GetShootPos(),
	}

	self:TakePrimaryAmmo(self.PrimaryBulletsPerFire)
	self:FireBullets(bullet_info)
	self:EmitSound(self.PrimarySound, 75, 100, 1, CHAN_WEAPON)
	self:ViewPunch()

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	owner:MuzzleFlash()
	owner:SetAnimation(PLAYER_ATTACK1)

	self:SetNextPrimaryFire(CurTime() + self.PrimaryDelay)
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then
		return
	end

	self:SetNextSecondaryFire(CurTime() + self.SecondaryDelay)
end

function SWEP:Reload()
	if not self:CanReload() then
		return
	end


	self:DefaultReload(ACT_VM_RELOAD)

	local owner = self:GetOwner()
	owner:SetAnimation(PLAYER_RELOAD)

	local time = CurTime()
	self:SetNextReload(time + self.ReloadDelay)
	self:SetNextPrimaryFire(time + self.PrimaryDelay)
	self:SetNextSecondaryFire(time + self.SecondaryDelay)
end

function SWEP:CanReload()
	return CurTime() >= self:GetNextReload()
end

function SWEP:SetNextReload(time)
	self.next_reload = time
end

function SWEP:GetNextReload()
	return self.next_reload or 0
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
