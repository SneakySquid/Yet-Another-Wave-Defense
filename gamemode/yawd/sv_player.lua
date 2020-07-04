DEFINE_BASECLASS("gamemode_base")

GM.CurrencyCache = {}

function GM:PlayerInitialSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_yawd")
end

function GM:PlayerDeathThink(ply)
	local death_time = ply:GetDeathTime()
	local spawn_delay = ply:GetSpawnDelay()

	if death_time + spawn_delay <= CurTime() then
		ply:Spawn()
	end
end

function GM:PlayerSpawn(ply, transition)
	local class = ply:GetPlayerClass()
	class = self.PlayerClasses[class]

	if not class or class == "player_yawd" then
		self:PlayerSpawnAsSpectator(ply)
		return
	end

	BaseClass.PlayerSpawn(self, ply, transition)
end

function GM:PlayerSelectSpawn(ply, transition)
	local spawn_points = ents.FindByClass("yawd_spawnpoint")
	local spawn_ents = #spawn_points

	if spawn_ents ~= 0 then
		for i, spawn in ipairs(spawn_points) do
			if hook.Run("IsSpawnpointSuitable", ply, point, i == spawn_ents) then return spawn end
		end
	end

	if (false) then
		return self:GetEndGoal()
	else
		return BaseClass.PlayerSelectSpawn(self, ply, transition)
	end
end
