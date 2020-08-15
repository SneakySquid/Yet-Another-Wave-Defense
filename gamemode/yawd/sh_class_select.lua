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

	local function Paint(self, w, h )
		if ( !IsValid( self.Entity ) ) then return end
		if self.PaintBG then
			self.PaintBG( self, w, h)
		end
		local x, y = self:LocalToScreen( 0, 0 )
		self:LayoutEntity( self.Entity )
		local ang = self.aLookAngle
		if ( !ang ) then
			ang = ( self.vLookatPos - self.vCamPos ):Angle()
		end
		cam.Start3D( self.vCamPos, ang, self.fFOV, x, y, w, h, 5, self.FarZ )
		render.SuppressEngineLighting( true )
		render.SetLightingOrigin( self.Entity:GetPos() )
		render.ResetModelLighting( self.colAmbientLight.r / 255, self.colAmbientLight.g / 255, self.colAmbientLight.b / 255 )
		render.SetColorModulation( self.colColor.r / 255, self.colColor.g / 255, self.colColor.b / 255 )
		render.SetBlend( ( self:GetAlpha() / 255 ) * ( self.colColor.a / 255 ) ) -- * surface.GetAlphaMultiplier()
		for i = 0, 6 do
			local col = self.DirectionalLight[ i ]
			if ( col ) then
				render.SetModelLighting( i, col.r / 255, col.g / 255, col.b / 255 )
			end
		end
		self:DrawModel()
		render.SuppressEngineLighting( false )
		cam.End3D()
		self.LastPaint = RealTime()
	end
	local textSize = .32
	local bg_color = Color(155,155,155)
	local fg_color = Color(100,100,100)
	local hover_color = color_white
	local function CreateClassIcon( class, frame )
		local tab = baseclass.Get( class )
		if not tab then return end
		local icon = vgui.Create("DPanel", frame)
		local name = vgui.Create("DPanel", icon)
		local selection = vgui.Create("DPanel", icon)
		local mdl = vgui.Create("DModelPanel", icon)
		local overlay = vgui.Create("DButton", icon)
		icon:SetSize(158, 134)
		-- Set name and model
		name.Name = language.GetPhrase(class) or class
		function name:Paint(w,h)
			surface.SetDrawColor(fg_color)
			surface.DrawRect(0,0,w,h)

			surface.DrawRect(5,5,w - 10,h - 9)
			draw.DrawText(self.Name,"HUD.WeaponSelect",  w / 2,h / 4, color_white, TEXT_ALIGN_CENTER)
		end
		mdl:SetModel( tab.Model )
		-- Make the overlay dock the icon. We use this for selection
		overlay:Dock(FILL)
		overlay:SetText("")
		function overlay:Paint() end
		function overlay.DoClick()
			local id = table.KeyFromValue(GAMEMODE.PlayerClasses,class)
			RunConsoleCommand("yawd_change_class", id)
			GAMEMODE:CloseSelectionMenu()
		end
		-- Place elements correctly
		function icon:PerformLayout( w, h)
			local mdl_h = h * (1 - textSize)
			selection:Dock(FILL)
			mdl:SetSize(w, mdl_h)
			name:SetSize(w - 10, h - mdl_h - 4)
			name:SetPos(5,mdl_h)
			overlay:SetSize(w,h)
		end
		function icon:Paint(w,h)
			local bx,by,bw,bh = 5, 5, w - 10, h - 10
			surface.SetDrawColor(bg_color)
			surface.DrawRect(bx,by,bw,bh)
		end
		function selection:Paint(w,h)
			if overlay:IsHovered() then
				frame.SelectedClass = class
				local bx,by,bw,bh = 5, 5, w - 10, h - 10
				surface.SetDrawColor(hover_color)
				local w2 = w - 1
				local h2 = h - 1
				surface.DrawLine(0,0,w2 * 0.10,0)
				surface.DrawLine(0,0,0,w2 * 0.10)
				surface.DrawLine(w2,0,w2 * 0.90,0)
				surface.DrawLine(w2,0,w2,w2 * 0.10)
				surface.DrawLine(0,h2,w2 * 0.10,h2)
				surface.DrawLine(0,h2,0,h2 * .9)
				surface.DrawLine(w2,h2,w2 * .90,h2)
				surface.DrawLine(w2,h2,w2,h2 * .9)

				surface.DrawOutlinedRect(bx,by,bw,bh)
			end
		end
		-- Setup Model
		local iconEnt = mdl.Entity
		local eyepos = iconEnt:GetBonePosition(iconEnt:LookupBone("ValveBiped.Bip01_Head1")) or (Vector(0,0,iconEnt:OBBMaxs().z) + iconEnt:GetPos())
		mdl:SetLookAt(eyepos + Vector(0,0,0))
		local v = Vector(-26, 5, 4):GetNormalized()
		mdl:SetCamPos(eyepos - v * 22 + Vector(0,0,6))
		mdl:SetFOV(90)
		function mdl:LayoutEntity( ent ) end
		
		return icon
	end -- 132, 110

	local function AddEqupmentIcon( icon, cost, frame )
		local equip_info = vgui.Create("DPanel", frame )
		equip_info.cost = cost
		function equip_info:Paint() end
		function equip_info:PaintOver(w, h)
			if not self.cost then return end
			draw.SimpleText(self.cost, "HUD.WeaponSelect", w / 2, w, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
		local img = vgui.Create("DImage", equip_info)
		if icon then
			img:SetMaterial(icon)
		end
		equip_info:SetWide(132)		
		function equip_info:PerformLayout(w, h)
			local s = math.min(w, h)
			img:SetSize(s, s)
		end
		frame:AddPanel(equip_info)
	end

	function GM:CreateSelectionMenu()
		if self.ClassMenu then
			self.ClassMenu:Remove()
		end

		local frame = vgui.Create("DFrame")
		frame:SetSize(800, 300)
		frame:MakePopup()
		frame:Center()
		frame:SetTitle("Select Class")

		-- Add class slection
		local scroller = frame:Add("DHorizontalScroller")
		scroller:SetTall(134)
		scroller:Dock(TOP)
		frame.SelectedClass = nil
		for i, class in ipairs(self.PlayerClasses) do
			local iconB = CreateClassIcon(class, frame )
			iconB:SetSize( 132, 110)
			scroller:AddPanel(iconB)
		end
	
		-- Add selection box
		local selection = vgui.Create("DPanel",frame)
		selection:Dock(FILL)
	
		-- Add buildings
		function selection:UpdateClass( class )
			-- Delete old scroller
			if self.b_scroller then
				self.b_scroller:Remove()
			end
			local id = table.KeyFromValue(GAMEMODE.PlayerClasses,class) or -1
			self.b_scroller = selection:Add("DHorizontalScroller")
			self.b_scroller:Dock(FILL)
			-- Add hidden stuff
			if id == CLASS_JUGGERNAUT then
				AddEqupmentIcon( Material("entities/yawd_fists_extreme.png"), "", self.b_scroller )
			end
			AddEqupmentIcon( Material("entities/yawd_pistol.png"), 200, self.b_scroller )
			-- Add all weapons
			for k,v in ipairs(GAMEMODE.GetUpgradesTable()) do
				if not v.can_purchase_class then continue end
				if not table.HasValue(v.can_purchase_class, id) then continue end
				local equip_info = AddEqupmentIcon( v.icon, v.price, self.b_scroller )
			end

			-- Add all buildings
				local buildings = {}
				for i, building in ipairs(Building.GetAll()) do
					if Building.CanClassBuild(building, id) then
						table.insert(buildings, building)
					end
				end
				table.sort(buildings, function(a, b)
					return Building.GetData(a).Cost < Building.GetData(b).Cost
				end)
				for i, building in ipairs(buildings) do
					local b_data = Building.GetData( building )
					local equip_info = AddEqupmentIcon( b_data.Icon, b_data.Cost, self.b_scroller )
				end
		end
		function selection:Paint( w, h)
			local selected = frame.SelectedClass
			if not selected then return end
			if self.l_select ~= selected then
				self.l_select = selected
				self:UpdateClass( selected )
			end
			
		end

		self.ClassMenu = frame
	end

	function GM:OpenSelectionMenu()
		if not IsValid(self.ClassMenu) then
			self:CreateSelectionMenu()
		end
		self.ClassMenu:SetVisible(true)
		surface.PlaySound("garrysmod/ui_click.wav")
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
