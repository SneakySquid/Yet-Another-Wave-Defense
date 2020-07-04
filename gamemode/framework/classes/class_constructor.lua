DEFINE_BASECLASS("player_yawd")

local PLAYER = {}
PLAYER.DisplayName = "Constructor"

PLAYER.Model = Model("models/player/odessa.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_citizen.mdl"),
	skin = 0,
	body = "0000000"
}

PLAYER.WalkSpeed = 300
PLAYER.RunSpeed = 300 * 1.3

PLAYER.JumpPower = 200

PLAYER.MaxHealth = 125
PLAYER.StartHealth = 125

PLAYER.Description = "The #yawd_constructor is a class that builds various constructs that supports their team by providing them with ammo and health sources and building traps and barricades to slow the enemy."
PLAYER.BaseStats = {}

GM:RegisterClass("yawd_constructor", PLAYER)
