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

local function SpawnBot( ply, ent_class )
	local var = "m_" .. ent_class
	if IsValid( ply[var] ) then print("BOT THERE") return end
	local e = ents.Create(ent_class)
	if not IsValid(e) then return end
	e:SetPos( ply:GetPos() )
	e:SetAngles( ply:GetAngles() )
	e:Spawn()
	ply[var] = e
end

function PLAYER:Loadout(...)
	BaseClass.Loadout(self, ...)

	self.Player:SwitchToDefaultWeapon()
end


GM:RegisterClass("yawd_fighter", PLAYER)
