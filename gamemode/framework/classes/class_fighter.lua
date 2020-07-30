DEFINE_BASECLASS("player_yawd")

local PLAYER = {}
PLAYER.DisplayName = "Fighter"

PLAYER.Model = Model("models/player/guerilla.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_cstrike.mdl"),
	skin = 0,
	body = "10000000",
}

PLAYER.WalkSpeed = 320
PLAYER.RunSpeed = 320 * 1.3

PLAYER.JumpPower = 250

PLAYER.MaxHealth = 220
PLAYER.StartHealth = 220

PLAYER.Description = "The #yawd_fighter is a close range all-rounder that excels at ambushing and flanking enemies."
PLAYER.BaseStats = {}

function PLAYER:Loadout(...)
	BaseClass.Loadout(self, ...)

	if GAMEMODE:GetPlayerUpgradeTier(self.Player, YAWD_UPGRADE_SHOTGUN) ~= 0 then
		self.Player:SetAmmo(164, "Buckshot")
		self.Player.m_StartingAmmo["Buckshot"] = 164

		self.Player:Give("yawd_shotgun")
	end

	self.Player:SwitchToDefaultWeapon()
end


GM:RegisterClass("yawd_fighter", PLAYER)
