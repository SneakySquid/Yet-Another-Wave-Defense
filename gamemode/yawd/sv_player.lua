DEFINE_BASECLASS("gamemode_base")

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

	if ply.m_SpawnedOnCore then
		ply.m_SpawnedOnCore = false
		ply:SetPos(ply:GetPos() + Vector(0, 0, 10))
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

	if self.Building_Core:IsValid() and hook.Run("IsSpawnpointSuitable", ply, self.Building_Core, true) then
		ply.m_SpawnedOnCore = true
		return self.Building_Core
	end

	return BaseClass.PlayerSelectSpawn(self, ply, transition)
end

function GM:PlayerDisconnected(ply)
	self:RemoveVote(ply)
end
