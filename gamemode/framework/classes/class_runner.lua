DEFINE_BASECLASS("player_yawd")

local PLAYER = {}
PLAYER.DisplayName = "Runner"

PLAYER.Model = Model("models/player/group03/female_01.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_refugee.mdl"),
	skin = 0,
	body = "0100000",
}

PLAYER.WalkSpeed = 400
PLAYER.RunSpeed = 400 * 1.5

PLAYER.JumpPower = 275

PLAYER.MaxHealth = 125
PLAYER.StartHealth = 125

PLAYER.Description = "The #yawd_runner is highly mobile but fragile support class that regains health from collecting money."
PLAYER.BaseStats = {}

function PLAYER:Loadout(...)
	BaseClass.Loadout(self, ...)
	self.Player:SwitchToDefaultWeapon()
end


GM:RegisterClass("yawd_runner", PLAYER)
