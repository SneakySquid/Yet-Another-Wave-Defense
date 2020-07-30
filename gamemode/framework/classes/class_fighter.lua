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

	self.Player:StripWeapon("yawd_fists")

	self.Player:SetAmmo(256, "Pistol")
	self.Player.m_StartingAmmo["Pistol"] = 256

	self.Player:SetAmmo(164, "Buckshot")
	self.Player.m_StartingAmmo["Buckshot"] = 164

	self.Player:Give("weapon_crowbar")
	self.Player:Give("yawd_shotgun")
	self.Player:Give("weapon_pistol")

	self.Player:SwitchToDefaultWeapon()
end


GM:RegisterClass("yawd_fighter", PLAYER)
--[[yawd_lmg
	self.Player:GiveAmmo(256, "Pistol", true)
	self.Player:GiveAmmo(256, "SMG1", true)
	self.Player:GiveAmmo(5, "grenade", true)
	self.Player:GiveAmmo(64, "Buckshot", true)
	self.Player:GiveAmmo(32, "357", true)
	self.Player:GiveAmmo(32, "XBowBolt", true)
	self.Player:GiveAmmo(100, "AR2", true)

	self.Player:Give("weapon_crowbar")
	self.Player:Give("weapon_pistol")
	self.Player:Give("weapon_smg1")
	self.Player:Give("weapon_frag")
	self.Player:Give("weapon_physcannon")
	self.Player:Give("weapon_crossbow")
	self.Player:Give("weapon_shotgun")
	self.Player:Give("weapon_357")
	self.Player:Give("weapon_rpg")
	self.Player:Give("weapon_ar2")
]]
