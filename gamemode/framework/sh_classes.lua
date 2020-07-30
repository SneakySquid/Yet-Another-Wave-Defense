CLASS_ANY = -1 	-- Used for buildings and class checks
CLASS_BASE = 0
CLASS_BOMBER = 1
CLASS_CONSTRUCTOR = 2
CLASS_FIGHTER = 3
CLASS_GUNNER = 4
CLASS_HEALER = 5
CLASS_JUGGERNAUT = 6
CLASS_RUNNER = 7

GM.PlayerClasses = {
	[CLASS_BASE] = "player_yawd",
	[CLASS_BOMBER] = "yawd_bomber",
	[CLASS_CONSTRUCTOR] = "yawd_constructor",
	[CLASS_FIGHTER] = "yawd_fighter",
	[CLASS_GUNNER] = "yawd_gunner",
	[CLASS_HEALER] = "yawd_healer",
	[CLASS_JUGGERNAUT] = "yawd_juggernaut",
	[CLASS_RUNNER] = "yawd_runner",
}

function GM:RegisterClass(name, tbl, base)
	if CLIENT then
		language.Add(name, tbl.DisplayName)
	end

	player_manager.RegisterClass(name, tbl, base or "player_yawd")
end

function GM:YAWDCanSwitchClass(ply, class)
	if class == 0 then
		return false, "Can't switch to the base class."
	elseif not self.PlayerClasses[class] then
		return false, "Can't switch to non-existant classes."
	elseif self:GetWaveStatus() ~= WAVE_WAITING then
		return false, "Can't switch class while waves are active."
	elseif self.m_VoteStarted and self.m_VoteType == VOTE_TYPE_CORE then
		return false, "Can't change class while the core vote is active."
	end

	return true
end

if SERVER then
	util.AddNetworkString("Class.Loadout")

	AddCSLuaFile("classes/class_base.lua")
	AddCSLuaFile("classes/class_bomber.lua")
	AddCSLuaFile("classes/class_constructor.lua")
	AddCSLuaFile("classes/class_fighter.lua")
	AddCSLuaFile("classes/class_gunner.lua")
	AddCSLuaFile("classes/class_healer.lua")
	AddCSLuaFile("classes/class_juggernaut.lua")
	AddCSLuaFile("classes/class_runner.lua")

	function GM:UpdateClass(ply, class)
		local able, reason = hook.Run("YAWDCanSwitchClass", ply, class)
		if able == false then return false, reason end

		ply:SetTeam(TEAM_DEFENDER)
		ply:SetPlayerClass(class)

		class = self.PlayerClasses[class]
		player_manager.SetPlayerClass(ply, class)

		hook.Run("YAWDPlayerSwitchedClass", ply, class)

		ply:Spawn()

		return true
	end

	local PLAYER = FindMetaTable("Player")

	function PLAYER:YAWDGiveAmmo(f)
		if not self.m_StartingAmmo then return false end

		f = f or 0.2

		for type, start_amt in pairs(self.m_StartingAmmo) do
			local current_amt = self:GetAmmoCount(type)

			if current_amt < start_amt then
				local new_amt = math.min(start_amt, math.floor(start_amt * f))

				if new_amt + current_amt <= start_amt then
					self:GiveAmmo(new_amt, type, false)
				else
					self:GiveAmmo(start_amt - current_amt, type, false)
				end
			end
		end

		return true
	end
end

include("classes/class_base.lua")
include("classes/class_bomber.lua")
include("classes/class_constructor.lua")
include("classes/class_fighter.lua")
include("classes/class_gunner.lua")
include("classes/class_healer.lua")
include("classes/class_juggernaut.lua")
include("classes/class_runner.lua")

hook.Add("YAWDPlayerUpgradesLoaded", "Classes.PlayerUpgradesLoaded", function()
	do -- Base class weapons
		YAWD_UPGRADE_CROWBAR = GM:RegisterUpgrade({
			name = "Crowbar",
			price = 50,

			on_purchase = function(ply)
				if SERVER then
					ply:Give("weapon_crowbar")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("weapon_crowbar")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})

		YAWD_UPGRADE_PISTOL = GM:RegisterUpgrade({
			name = "Pistol",
			price = 200,

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["Pistol"] = 50
					ply:Give("yawd_pistol")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_pistol")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})

		YAWD_UPGRADE_SMG = GM:RegisterUpgrade({
			name = "SMG",
			price = 400,

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["SMG1"] = 256

					if ply:GetPlayerClass() == CLASS_BOMBER then
						ply.m_StartingAmmo["SMG1_Grenade"] = 5
					end

					ply:Give("weapon_smg1")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_pistol")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})
	end

	do -- Bomber weapons
		YAWD_UPGRADE_GRENADE = GM:RegisterUpgrade({
			name = "Grenades",
			price = 500,

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_BOMBER
			end,

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["grenade"] = 15
					ply:Give("weapon_frag")
				else
					GAMEMODE:PrecacheSlots()
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("grenade_frag")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})

		YAWD_UPGRADE_RPG = GM:RegisterUpgrade({
			name = "RPG",
			price = 1000,

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_BOMBER
			end,

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["RPG_Round"] = 15
					ply:Give("weapon_rpg")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("weapon_rpg")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})
	end

	do -- Fighter weapons
		YAWD_UPGRADE_SHOTGUN = GM:RegisterUpgrade({
			name = "Shotgun",
			price = 750,

			can_purchase = function(ply)
				local class = ply:GetPlayerClass()
				return class == CLASS_FIGHTER or class == CLASS_GUNNER
			end,

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["Buckshot"] = 164
					ply:Give("yawd_shotgun")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_shotgun")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})
	end

	do -- Gunner weapons
		YAWD_UPGRADE_RIFLE = GM:RegisterUpgrade({
			name = "Rifle",
			price = 750,

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_GUNNER
			end,

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["AR2"] = 300
					ply:Give("yawd_rifle")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_rifle")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})
	end

	do -- Healer weapons
		YAWD_UPGRADE_MEDKIT = GM:RegisterUpgrade({
			name = "Medkit",
			price = 350,

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_HEALER
			end,

			on_purchase = function(ply)
				if SERVER then
					ply:Give("weapon_medkit")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("weapon_medkit")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})
	end

	do -- Juggernaut weapons
		YAWD_UPGRADE_LMG = GM:RegisterUpgrade({
			name = "LMG",
			price = 750,

			can_purchase = function(ply)
				local class = ply:GetPlayerClass()
				return class == CLASS_JUGGERNAUT or class == CLASS_GUNNER
			end,

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["AR2"] = 500
					ply:Give("yawd_lmg")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_lmg")
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})
	end
end)
