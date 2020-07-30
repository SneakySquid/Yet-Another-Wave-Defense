DEFINE_BASECLASS("player_yawd")

local PLAYER = {}
PLAYER.DisplayName = "Gunner"

PLAYER.Model = Model("models/player/swat.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_combine.mdl"),
	skin = 0,
	body = "00000000",
}

PLAYER.WalkSpeed = 240
PLAYER.RunSpeed = 240 * 1.3

PLAYER.JumpPower = 175

PLAYER.MaxHealth = 150
PLAYER.StartHealth = 150

PLAYER.Description = "The #yawd_gunner is capable of using most ranged weapons with high proficiency."
PLAYER.BaseStats = {}

function PLAYER:Loadout(...)
	BaseClass.Loadout(self, ...)

	if GAMEMODE:GetPlayerUpgradeTier(self.Player, YAWD_UPGRADE_RIFLE) ~= 0 then
		self.Player:SetAmmo(300, "AR2")
		self.Player.m_StartingAmmo["AR2"] = 300

		self.Player:Give("yawd_rifle")
	end

	if GAMEMODE:GetPlayerUpgradeTier(self.Player, YAWD_UPGRADE_LMG) ~= 0 then
		self.Player:SetAmmo(500, "AR2")
		self.Player.m_StartingAmmo["AR2"] = 500

		self.Player:Give("yawd_lmg")
	end

	if GAMEMODE:GetPlayerUpgradeTier(self.Player, YAWD_UPGRADE_SHOTGUN) ~= 0 then
		self.Player:SetAmmo(164, "Buckshot")
		self.Player.m_StartingAmmo["Buckshot"] = 164

		self.Player:Give("yawd_shotgun")
	end

	self.Player:SwitchToDefaultWeapon()
end

GM:RegisterClass("yawd_gunner", PLAYER)
