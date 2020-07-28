SWEP.Base = "yawd_weapon_base"
SWEP.PrintName = "Rifle"
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
SWEP.ViewModelFlip = true

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_rif_ak47.mdl"
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary = {
	Ammo = "AR2",
	ClipSize = 30,
	DefaultClip = 90,
	Automatic = true,
}

SWEP.PrimaryDelay = 0.1
SWEP.PrimarySpread = Vector(0.01, 0.02, 0)
SWEP.PrimaryBulletsPerFire = 1
SWEP.PrimaryBulletsTakenPerShot = 1
SWEP.PrimaryForce = 1
SWEP.PrimaryMaxDistance = 56756
SWEP.PrimarySound = "weapons/ak47/ak47-1.wav"
SWEP.PrimaryDamage = {
	min = 17,
	max = 24,
}
SWEP.PrimaryViewPunch = {
	p = {
		min = -0.9,
		max = -1.7,
	},
	y = {
		min = -0.1,
		max = 0.1,
	},
}

SWEP.ReloadDelay = 1
SWEP.ReloadSound = "weapons/ak47/ak47_clipin.wav"
