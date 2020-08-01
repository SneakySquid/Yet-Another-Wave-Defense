local is_restarting = false
local function RestartGamemode()
	game.CleanUpMap()
	for k,v in ipairs(player.GetAll()) do
		v:SetPlayerClass(CLASS_BASE)
		player_manager.SetPlayerClass(v, GAMEMODE.PlayerClasses[CLASS_BASE])
		v:SetCurrency(0)
		v:Spawn()
	end
	GAMEMODE:StartVote(VOTE_TYPE_CORE)
	GAMEMODE:SetWaveNumber(0)
	Controller.ResetSpawnerCheck()
	is_restarting = false
end
hook.Add("EntityRemoved", "YAWD.CoreEnd", function( ent )
	if not IsValid(ent) or ent:GetClass() ~= "yawd_npc_base" then return end
	local core = Building.GetCore()
	if is_restarting or not IsValid(core) or core:Health() > 0 then return end
	-- Core is dead, round is over
	PrintMessage(HUD_PRINTTALK, "Core is dead. You reached wave [" .. GAMEMODE:GetWaveNumber() .. "].")
	PrintMessage(HUD_PRINTTALK, "Restarting gamemode in 10 seconds..")
	GAMEMODE:SetWaveStatus(WAVE_WAITING)
	is_restarting = true
	timer.Simple(10, RestartGamemode)
end)