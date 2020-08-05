if SERVER then
	concommand.Add("yawd_change_class", function(ply, cmd, args)
		if not IsValid(ply) then return end

		local able, reason = GAMEMODE:UpdateClass(ply, tonumber(args[1]) or 0)

		if not able then
			ply:ChatPrint(reason)
		end
	end)
	-- Singleplayer Fix
	if game.SinglePlayer() then
		util.AddNetworkString("YAWD.SPlayerClassFix")
		hook.Add("PlayerButtonDown", "YAWD.KeyFix", function( ply, button )
			net.Start("YAWD.SPlayerClassFix")
				net.WriteInt(button,32)
			net.Send( ply )
		end)
	end
else
	function GM:CreateSelectionMenu()
		if self.ClassMenu then
			self.ClassMenu:Remove()
		end

		local frame = vgui.Create("DFrame")
		frame:SetSize(300, 60)
		frame:MakePopup()
		frame:Center()

		local scroller = frame:Add("DHorizontalScroller")
		scroller:Dock(FILL)

		for i, class in ipairs(self.PlayerClasses) do
			local btn = vgui.Create("DButton")
			btn:Dock(LEFT)
			btn:SetText(language.GetPhrase(class))
			btn:SizeToContentsX(10)

			function btn.DoClick()
				RunConsoleCommand("yawd_change_class", i)
				self:CloseSelectionMenu()
			end

			scroller:AddPanel(btn)
		end

		self.ClassMenu = frame
	end

	function GM:OpenSelectionMenu()
		if not IsValid(self.ClassMenu) then
			self:CreateSelectionMenu()
		end

		self.ClassMenu:SetVisible(true)
	end

	function GM:CloseSelectionMenu()
		if self.ClassMenu then
			self.ClassMenu:SetVisible(false)
		end
	end

	concommand.Add("yawd_select_class", function()
		GAMEMODE:OpenSelectionMenu()
	end)

	hook.Add("YAWDVoteFinished", "Class.Select", function(vote_type)
		if vote_type == VOTE_TYPE_CORE then
			GAMEMODE:OpenSelectionMenu()
			chat.AddText("Use 'yawd_select_class' to change classes.")
		end
	end)

	hook.Add("YAWDPostEntity", "Class.Select", function()
		if GAMEMODE.Building_Core:IsValid() then
			GAMEMODE:OpenSelectionMenu()
			chat.AddText("Use 'yawd_select_class' to change classes.")
		end
	end)

	-- We look after the button 'G' if yawd_class_select isn't bound.
	local function OnKey( _, button_code )
		if button_code ~= KEY_G then return end
		if input.LookupBinding( "yawd_change_class" ) then return end -- Command already bound
		GAMEMODE:OpenSelectionMenu()
	end
	hook.Add("PlayerButtonDown", "YAWD.ClassMenuDefault", OnKey)
	-- Singleplayer fix
	if game.SinglePlayer() then
		net.Receive("YAWD.SPlayerClassFix", function()
			OnKey(_, net.ReadInt(32))
		end)
	end
end
