AddCSLuaFile()

SWEP.Base = "yawd_weapon_base"
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

SWEP.ViewModelFOV = 74
SWEP.ViewModelFlip = true

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_pist_fiveseven.mdl"
SWEP.WorldModel = "models/weapons/w_pist_fiveseven.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary = {
	Ammo = "Pistol",
	ClipSize = 12,
	DefaultClip = 48,
	Automatic = false,
}

SWEP.PrimaryDelay = 0.15
SWEP.PrimarySpread = Vector(0.01, 0.01, 0)
SWEP.PrimaryBulletsPerFire = 1
SWEP.PrimaryBulletsTakenPerShot = 1
SWEP.PrimaryForce = 1
SWEP.PrimaryMaxDistance = 56756
SWEP.PrimarySound = "weapons/fiveseven/fiveseven-1.wav"
SWEP.PrimaryDamage = {
	min = 7,
	max = 14,
}
SWEP.PrimaryViewPunch = {
	p = {
		min = -0.2,
		max = -0.9,
	},
	y = {
		min = -0.01,
		max = 0.01,
	},
}

SWEP.ReloadSound = "weapons/fiveseven/fiveseven_clipout.wav"
