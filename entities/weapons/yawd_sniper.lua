AddCSLuaFile()

SWEP.Base = "yawd_sniper_base"
SWEP.PrintName = "Sniper"
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
SWEP.ViewModel = "models/weapons/v_snip_awp.mdl"
SWEP.WorldModel = "models/weapons/w_snip_awp.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary = {
	Ammo = "SniperRound",
	ClipSize = 1,
	DefaultClip = 16,
	Automatic = true,
}

SWEP.ScopeOverlayMaterialPath = "overlays/scope_lens"
SWEP.ScopeDelay = 0.1

if CLIENT and #SWEP.ScopeOverlayMaterialPath > 0 then
	SWEP.ScopeOverlayMaterial = Material(SWEP.ScopeOverlayMaterialPath)
end

SWEP.PrimaryDelay = 1
SWEP.PrimaryUnscopedSpread = Vector(0.1, 0.1, 0)
SWEP.PrimaryScopedSpread = Vector(0.005, 0.005, 0)
SWEP.PrimaryBulletsPerFire = 1
SWEP.PrimaryBulletsTakenPerShot = 1
SWEP.PrimaryForce = 1
SWEP.PrimaryMaxDistance = 56756
SWEP.PrimarySound = "weapons/awp/awp1.wav"
SWEP.PrimaryDamage = {
	min = 90,
	max = 110,
}
SWEP.PrimaryViewPunch = {
	p = {
		min = -2,
		max = -5,
	},
	y = {
		min = -0.4,
		max = 0.4,
	},
}

SWEP.ReloadSound = "weapons/awp/awp_bolt.wav"
