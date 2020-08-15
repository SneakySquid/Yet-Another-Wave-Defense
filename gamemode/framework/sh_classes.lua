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
	local previous_class = ply:GetPlayerClass()

	if previous_class ~= CLASS_BASE then
		if class == 0 then
			return false, "Can't change to the base class."
		elseif class == previous_class then
			return false, "Can't change to the same class."
		elseif not self.PlayerClasses[class] then
			return false, "Can't change to non-existant class."
		elseif self.m_WaveStatus ~= WAVE_WAITING then
			return false, "Can't change class while waves are active."
		elseif self.m_VoteStarted and self.m_VoteType == VOTE_TYPE_CORE then
			return false, "Can't change class while core vote is active."
		end
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
			icon = Material("entities/weapon_crowbar.png"),
			price = 50,

			on_purchase = function(ply)
				if SERVER then
					ply:Give("weapon_crowbar")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("weapon_crowbar")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})

		YAWD_UPGRADE_PISTOL = GM:RegisterUpgrade({
			name = "Pistol",
			price = 200,
			icon = Material("entities/yawd_pistol.png"),

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["Pistol"] = 50
					ply:Give("yawd_pistol")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_pistol")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})

		YAWD_UPGRADE_SMG = GM:RegisterUpgrade({
			name = "SMG",
			price = 400,
			icon = Material("entities/weapon_smg1.png"),

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["SMG1"] = 256

					if ply:GetPlayerClass() == CLASS_BOMBER then
						ply.m_StartingAmmo["SMG1_Grenade"] = 5
					end

					ply:Give("weapon_smg1")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_pistol")
					ply:Spawn()
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
			icon = Material("entities/weapon_frag.png"),

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_BOMBER
			end,
			can_purchase_class = { CLASS_BOMBER },

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["grenade"] = 15
					ply:Give("weapon_frag")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("grenade_frag")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})

		YAWD_UPGRADE_RPG = GM:RegisterUpgrade({
			name = "RPG",
			price = 1000,
			icon = Material("entities/weapon_rpg.png"),

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_BOMBER
			end,
			can_purchase_class = { CLASS_BOMBER },

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["RPG_Round"] = 15
					ply:Give("weapon_rpg")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("weapon_rpg")
					ply:Spawn()
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
			icon = Material("entities/yawd_shotgun.png"),

			can_purchase = function(ply)
				local class = ply:GetPlayerClass()
				return class == CLASS_FIGHTER or class == CLASS_GUNNER
			end,
			can_purchase_class = { CLASS_FIGHTER, CLASS_GUNNER },

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["Buckshot"] = 164
					ply:Give("yawd_shotgun")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_shotgun")
					ply:Spawn()
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
			icon = Material("entities/yawd_rifle.png"),

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_GUNNER
			end,
			can_purchase_class = { CLASS_GUNNER },

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["AR2"] = 300
					ply:Give("yawd_rifle")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_rifle")
					ply:Spawn()
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
			icon = Material("entities/weapon_medkit.png"),

			can_purchase = function(ply)
				return ply:GetPlayerClass() == CLASS_HEALER
			end,
			can_purchase_class = { CLASS_HEALER },

			on_purchase = function(ply)
				if SERVER then
					ply:Give("weapon_medkit")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("weapon_medkit")
					ply:Spawn()
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
			icon = Material("entities/yawd_lmg.png"),
			can_purchase = function(ply)
				local class = ply:GetPlayerClass()
				return class == CLASS_JUGGERNAUT or class == CLASS_GUNNER
			end,
			can_purchase_class = { CLASS_JUGGERNAUT, CLASS_GUNNER },

			on_purchase = function(ply)
				if SERVER then
					ply.m_StartingAmmo["AR2"] = 500
					ply:Give("yawd_lmg")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,

			on_sell = function(ply)
				if SERVER then
					ply:StripWeapon("yawd_lmg")
					ply:Spawn()
				else
					GAMEMODE:PrecacheSlots()
				end
			end,
		})
	end
end)
