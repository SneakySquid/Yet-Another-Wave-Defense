DEFINE_BASECLASS("player_default")

local PLAYER = {}
PLAYER.DisplayName = "YAWD Base Class"

PLAYER.Model = Model("models/player/alyx.mdl")
PLAYER.Hands = {
	model = Model("models/weapons/c_arms_citizen.mdl"),
	skin = 0,
	body = "0000000"
}

PLAYER.Description = "No description set."
PLAYER.BaseStats = {}

function PLAYER:SetupDataTables()
	local ply = self.Player

	ply:NetworkVar("Int", 0, "Currency")
	ply:NetworkVar("Int", 1, "PlayerClass")
	ply:NetworkVar("Int", 2, "MaxOverheal")

	ply:NetworkVar("Float", 0, "DeathTime")
	ply:NetworkVar("Float", 1, "SpawnDelay")

	if (SERVER) then
		ply:SetCurrency(ply:GetCurrency() or 0)
		ply:SetPlayerClass(ply:GetPlayerClass() or 0)
		ply:SetMaxOverheal(ply:GetMaxOverheal() or 0)

		ply:SetDeathTime(ply:GetDeathTime() or 0)
		ply:SetSpawnDelay(ply:GetSpawnDelay() or 5)
	end
end

function PLAYER:SetModel()
	util.PrecacheModel(self.Model)
	self.Player:SetModel(self.Model)
end

function PLAYER:Death(inflictor, attacker)
	self.Player:SetDeathTime(CurTime())
	self.Player:SetSpawnDelay(2)

	BaseClass.Death(self, inflictor, attacker)
end

function PLAYER:Loadout(...)
	self.Player:RemoveAllAmmo()

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

	self.Player:SwitchToDefaultWeapon()
end

function PLAYER:GetHandsModel()
	return self.Hands
end

GM:RegisterClass("player_yawd", PLAYER, "player_default")
