SWEP.Base = "weapon_base"
SWEP.PrintName = "YAWD Weapon Base"
SWEP.Author = "YAWD Team"
SWEP.Category = "YAWD"
SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.m_WeaponDeploySpeed = 1

SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.DrawCrosshair = true
SWEP.DrawAmmo = true
SWEP.Weight = 5

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = true

SWEP.UseHands = true
SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.HoldType = "ar2"

SWEP.Primary = {
	Ammo = "AR2",
	ClipSize = 8,
	DefaultClip = 64,
	Automatic = false,
}

SWEP.PrimaryDelay = 1
SWEP.PrimarySpread = Vector(0, 0, 0)
SWEP.PrimaryBulletsPerFire = 1
SWEP.PrimaryBulletsTakenPerShot = 1
SWEP.PrimaryForce = 1
SWEP.PrimaryMaxDistance = 56756
SWEP.PrimarySound = ""
SWEP.PrimaryDamage = {
	min = 10,
	max = 10,
}
SWEP.PrimaryViewPunch = {
	p = {
		min = 0,
		max = 0,
	},
	y = {
		min = 0,
		max = 0,
	},
}

SWEP.ReloadDelay = 1
SWEP.ReloadSound = ""

SWEP.CanAttackReason = {
	CLIP_EMPTY,
	UNUSABLE,
}

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
	local can_attack, reason = self:CanPrimaryAttack()
	if not can_attack then
		if reason == self.CanAttackReason.CLIP_EMTPY then
			self:Reload()
		end

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
		Spread = self:GetSpread(),
		Src = owner:GetShootPos(),
	}

	self:TakePrimaryAmmo(self.PrimaryBulletsTakenPerShot)
	self:FireBullets(bullet_info)
	self:EmitSound(self.PrimarySound, 75, 100, 1, CHAN_WEAPON)
	self:ViewPunch()

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	owner:MuzzleFlash()
	owner:SetAnimation(PLAYER_ATTACK1)

	self:SetNextPrimaryFire(CurTime() + self.PrimaryDelay)
end

function SWEP:SecondaryAttack()

end

function SWEP:CanPrimaryAttack()
	if self:PrimaryClip() <= 0 then
		return false, self.CanAttackReason.CLIP_EMPTY
	end

	return true
end

function SWEP:CanSecondaryAttack()
	return false, self.CanAttackReason.UNUSABLE
end

function SWEP:Reload()
	if not self:CanReload() then
		return
	end

	self:DefaultReload(ACT_VM_RELOAD)

	local owner = self:GetOwner()
	owner:SetAnimation(PLAYER_RELOAD)

	self:EmitSound(self.ReloadSound, 75, 100, 1, CHAN_WEAPON)

	local time = CurTime()
	self:SetNextReload(time + self.ReloadDelay)
	self:SetNextPrimaryFire(time + self.ReloadDelay)
end

function SWEP:CanReload()
	return CurTime() >= self:GetNextReload()
		and self:PrimaryAmmo() > 0
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

function SWEP:GetSpread()
	return self.PrimarySpread
end

-- Nicer names
function SWEP:PrimaryAmmo()
	return self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType())
end

function SWEP:SecondaryAmmo()
	return self:GetOwner():GetAmmoCount(self:GetSecondaryAmmoType())
end

local _weapon = debug.getregistry().Weapon
SWEP.PrimaryClip = _weapon.Clip1
SWEP.SecondaryClip = _weapon.Clip2
