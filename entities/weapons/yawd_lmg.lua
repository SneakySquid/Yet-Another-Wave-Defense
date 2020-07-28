SWEP.Base = "yawd_weapon_base"
SWEP.PrintName = "Light Machine Gun"
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
SWEP.ViewModel = "models/weapons/v_mach_m249para.mdl"
SWEP.WorldModel = "models/weapons/w_mach_m249para.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary = {
	Ammo = "AR2",
	ClipSize = 100,
	DefaultClip = 300,
	Automatic = true,
}

SWEP.PrimaryDelay = 0.1
SWEP.PrimarySpread = Vector(0.03, 0.045, 0)
SWEP.PrimaryBulletsPerFire = 1
SWEP.PrimaryBulletsTakenPerShot = 1
SWEP.PrimaryForce = 1
SWEP.PrimaryMaxDistance = 56756
SWEP.PrimarySound = "weapons/m249/m249-1.wav"
SWEP.PrimaryDamage = {
	min = 24,
	max = 32,
}
SWEP.PrimaryViewPunch = {
	p = {
		min = -1.2,
		max = -2.1,
	},
	y = {
		min = -0.1,
		max = 0.1,
	},
}

SWEP.ReloadDelay = 1
SWEP.ReloadSound = "weapons/m249/m249_boxout.wav"
