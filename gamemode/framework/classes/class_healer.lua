DEFINE_BASECLASS("player_yawd")

local PLAYER = {}
PLAYER.DisplayName = "Healer"

PLAYER.Model = Model("models/player/group03m/female_06.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_refugee.mdl"),
	skin = 1,
	body = "0100000",
}

PLAYER.WalkSpeed = 320
PLAYER.RunSpeed = 320 * 1.3

PLAYER.JumpPower = 200

PLAYER.MaxHealth = 125
PLAYER.StartHealth = 125

PLAYER.Description = "The #yawd_healer is the backbone of a team that helps others survive through rough situations and picking them up when they fall."
PLAYER.BaseStats = {}

function PLAYER:Loadout(...)
	BaseClass.Loadout(self, ...)

	if GAMEMODE:GetPlayerUpgradeTier(self.Player, YAWD_UPGRADE_MEDKIT) ~= 0 then
		self.Player:Give("weapon_medkit")
	end

	self.Player:SwitchToDefaultWeapon()
end
GM:RegisterClass("yawd_healer", PLAYER)
