if SERVER then
	concommand.Add("yawd_change_class", function(ply, cmd, args)
		if not IsValid(ply) then return end

		local able, reason = GAMEMODE:UpdateClass(ply, tonumber(args[1]) or 0)

		if not able then
			ply:ChatPrint(reason)
		end
	end)
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
end
