if SERVER then
	util.AddNetworkString("Class.Select")

	function GM:UpdateClass(ply, class)
		if self:HasWaveStarted() then return false, "Can't change classes while wave is active." end
		if not self.PlayerClasses[class] then return false, "Class doesn't exist." end

		ply:SetTeam(TEAM_DEFENDER)
		ply:SetPlayerClass(class)

		class = self.PlayerClasses[class]
		player_manager.SetPlayerClass(ply, class)

		ply:Spawn()

		return true
	end

	net.Receive("Class.Select", function(_, ply)
		local a, b = GAMEMODE:UpdateClass(ply, net.ReadUInt(3))

		if a then
			ply:ChatPrint(string.format("Couldn't change class: '%s'", b))
		end
	end)

	concommand.Add("yawd_change_class", function(ply, cmd, args, arg_str)
		if not IsValid(ply) then return end

		local a, b = GAMEMODE:UpdateClass(ply, tonumber(args[1]) or 0)

		if not a then
			ply:ChatPrint(b)
		end
	end)
end
