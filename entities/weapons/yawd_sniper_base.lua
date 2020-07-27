SWEP.Base = "yawd_weapon_base"
SWEP.PrintName = "YAWD Sniper Base"
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
	Ammo = "SniperRound",
	ClipSize = 4,
	DefaultClip = 32,
	Automatic = true,
}

SWEP.ScopeOverlayMaterialPath = ""
SWEP.ScopeDelay = 0.1

if CLIENT and #SWEP.ScopeOverlayMaterialPath > 0 then
	SWEP.ScopeOverlayMaterial = Material(SWEP.ScopeOverlayMaterialPath)
end

SWEP.PrimaryDelay = 1
SWEP.PrimaryUnscopedSpread = Vector(0.1, 0.1, 0)
SWEP.PrimaryScopedSpread = Vector(0, 0, 0)
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

function SWEP:SecondaryAttack()
	self:ToggleScope()
end

function SWEP:CanSecondaryAttack()
	return true
end

function SWEP:ToggleScope()
	if not self:CanScope() then
		return
	end

	self:SetScoped(not self:GetScoped())
	self:SetNextScope(CurTime() + self.ScopeDelay)
end

function SWEP:SetNextScope(time)
	self.next_scope_time = time
end

function SWEP:GetNextScopeTime()
	return self.next_scope_time or 0
end

function SWEP:CanScope()
	return CurTime() >= self:GetNextScopeTime()
end

function SWEP:SetScoped(b)
	self.is_scoped = b
end

function SWEP:GetScoped()
	return self.is_scoped or false
end

function SWEP:GetSpread()
	return self:GetScoped() and self.PrimaryScopedSpread or self.PrimaryUnscopedSpread
end

function SWEP:DrawHUD()
	if self:GetScoped() then
		surface.SetMaterial(self.ScopeOverlayMaterial)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end
end
