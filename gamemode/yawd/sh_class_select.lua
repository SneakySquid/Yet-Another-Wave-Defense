if SERVER then
	util.AddNetworkString("Class.Select")

	function GM:UpdateClass(ply, class)
		if self:IsVoteWave() then return false, "You need a Core first." end
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
else
	local function CloseClassMenu()
		if CLASS_MENU then
			CLASS_MENU:Remove()
		end
	end
	local function OpenClassMenu()
		if CLASS_MENU then
			CLASS_MENU:Remove()
		end
		CLASS_MENU = vgui.Create("DFrame")
		CLASS_MENU:SetSize(800, 300)
		CLASS_MENU:Center()
		local wide = 800 / (table.Count(GAMEMODE.PlayerClasses) - 1)
		for k,v in ipairs(GAMEMODE.PlayerClasses) do
			local class_button = vgui.Create("DButton", CLASS_MENU)
			class_button:SetSize( wide , wide * 0.4 )
			class_button:SetPos(k * wide - wide , 100)
			class_button:SetText("#" .. v)
			function class_button:DoClick()
				RunConsoleCommand("yawd_change_class", k)
				CloseClassMenu()
			end
		end
	end
	-- Force the class menu up if we're done voting and no class.
	hook.Add("Wave.VoteFinished", "OpenClassSelect", function()
		if player_manager.GetPlayerClass( LocalPlayer() ) ~= "player_yawd" then return end
		OpenClassMenu()
	end)
	hook.Add("Wave.InfoReceived", "OpenClassSelect", function()
		if GAMEMODE:IsVoteWave() then return end
		if player_manager.GetPlayerClass( LocalPlayer() ) ~= "player_yawd" then return end
		OpenClassMenu()
	end)
end
