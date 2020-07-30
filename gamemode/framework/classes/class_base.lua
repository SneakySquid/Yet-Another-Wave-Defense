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

	ply:NetworkVar("Int", 0, "Buffs")
	ply:NetworkVar("Int", 1, "Debuffs")
	ply:NetworkVar("Int", 2, "Currency")
	ply:NetworkVar("Int", 3, "PlayerClass")
	ply:NetworkVar("Int", 4, "MaxOverheal")

	ply:NetworkVar("Float", 0, "DeathTime")
	ply:NetworkVar("Float", 1, "SpawnDelay")

	if (SERVER) then
		ply:SetBuffs(ply:GetBuffs() or 0)
		ply:SetDebuffs(ply:GetDebuffs() or 0)
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
	self.Player:StripWeapons()
	self.Player:RemoveAllAmmo()

	self.Player:Give("wep_build")
	self.Player:Give("yawd_fists")

	self.Player.m_StartingAmmo = {}

	for type in pairs(game.GetAmmoTypes()) do
		self.Player.m_StartingAmmo[type] = self.Player:GetAmmoCount(type)
	end

	net.Start("Class.Loadout")
	net.Send(self.Player)
end

function PLAYER:GetHandsModel()
	return self.Hands
end

GM:RegisterClass("player_yawd", PLAYER, "player_default")
