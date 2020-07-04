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

GM:RegisterClass("yawd_bomber", PLAYER)
