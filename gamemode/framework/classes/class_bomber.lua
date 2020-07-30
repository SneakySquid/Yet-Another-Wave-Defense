DEFINE_BASECLASS("player_yawd")

local PLAYER = {}
PLAYER.DisplayName = "Bomber"

PLAYER.Model = Model("models/player/group03/male_03.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_refugee.mdl"),
	skin = 1,
	body = "0000000"
}

PLAYER.WalkSpeed = 280
PLAYER.RunSpeed = 280 * 1.3

PLAYER.JumpPower = 175

PLAYER.MaxHealth = 175
PLAYER.StartHealth = 175

PLAYER.Description = "The #yawd_bomber is a class that utilises high AoE burst damage to demolish large groups of enemies."
PLAYER.BaseStats = {}

function PLAYER:Loadout(...)
	BaseClass.Loadout(self, ...)

	if GAMEMODE:GetPlayerUpgradeTier(self.Player, YAWD_UPGRADE_GRENADE) ~= 0 then
		self.Player:SetAmmo(15, "grenade")
		self.Player.m_StartingAmmo["grenade"] = 15

		self.Player:Give("weapon_frag")
	end

	if GAMEMODE:GetPlayerUpgradeTier(self.Player, YAWD_UPGRADE_RPG) ~= 0 then
		self.Player:SetAmmo(15, "RPG_Round")
		self.Player.m_StartingAmmo["RPG_Round"] = 15

		self.Player:Give("weapon_rpg")
	end

	self.Player:SwitchToDefaultWeapon()
end

GM:RegisterClass("yawd_bomber", PLAYER)
