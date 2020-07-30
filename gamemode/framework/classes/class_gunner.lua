DEFINE_BASECLASS("player_yawd")

local PLAYER = {}
PLAYER.DisplayName = "Gunner"

PLAYER.Model = Model("models/player/combine_soldier.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_combine.mdl"),
	skin = 0,
	body = "0000000",
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

	self.Player:SetAmmo(300, "AR2")
	self.Player.m_StartingAmmo["AR2"] = 300

	self.Player:Give("yawd_rifle")

	self.Player:SwitchToDefaultWeapon()
end

GM:RegisterClass("yawd_gunner", PLAYER)
