CLASS_ANY = -1 	// Used for buildings and class checks
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
		if not able then return false, reason end

		ply:SetTeam(TEAM_DEFENDER)
		ply:SetPlayerClass(class)

		class = self.PlayerClasses[class]
		player_manager.SetPlayerClass(ply, class)

		hook.Run("YAWDPlayerSwitchedClass", ply, class)

		ply:Spawn()

		return true
	end
	-- Give players the weapons and traps
	local meleeWep = {"weapon_crowbar", "yawd_fists_extreme"} -- These weapons will remove yaw_fists
	local function GetMelee(ply)
		for k,v in ipairs(ply:GetWeapons()) do
			if table.HasValue(meleeWep, v:GetClass()) then return v:GetClass() end
		end

	end
	function GM:PlayerLoadout( ply )
		ply:StripWeapons()
		player_manager.RunClass( ply, "Loadout" )
		-- Allways give these
		ply:Give( "wep_build" )
		local melee = GetMelee( ply )
		if not melee then
			ply:Give( "yawd_fists" )
			ply:SelectWeapon( "yawd_fists" )
		else
			ply:SelectWeapon( melee )
		end
		
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
