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
	self.Player:RemoveAllAmmo()
	self.Player:Give("yawd_rifle")
	self.Player:GiveAmmo(300, "AR2", true)
	self.Player:SwitchToDefaultWeapon()
end

GM:RegisterClass("yawd_gunner", PLAYER)
