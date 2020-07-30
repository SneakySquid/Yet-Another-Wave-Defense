function GM:CreateUpgradesMenu()
	DebugMessage("Opening player upgrades menu")

	local localplayer = LocalPlayer()

	local frame = vgui.Create("DFrame")
	frame:SetTitle("Upgrades")
	frame:MakePopup()
	frame:SetSize(ScrW() / 1.4, ScrH() / 1.4)
	frame:Center()

	local pnl_scroll = frame:Add("DScrollPanel")
	pnl_scroll:Dock(FILL)
	pnl_scroll:DockMargin(10, 10, 10, 10)

	for _, v in ipairs(GAMEMODE:GetUpgradesTable()) do
		local pnl = pnl_scroll:Add("DPanel")
		pnl:SetTall(100)
		pnl:Dock(TOP)
		pnl:DockMargin(0, 0, 0, 5)
		pnl.Paint = function() end

		local name = pnl:Add("DLabel")
		name:SetText(v.name)
		name:Dock(TOP)
		name:SetTall(50)

		for i = 1, v.tiers do
			local price = istable(v.price) and v.price[i] or v.price
			local owned_tier = GAMEMODE:GetPlayerUpgradeTier(localplayer, v.k)
			local is_owned = owned_tier >= i
			local text_col = is_owned and Color(180, 0, 0, 255) or Color(0, 140, 0, 255)

			local btn_purchase_tier = pnl:Add("DButton")
			btn_purchase_tier:SetText(
				is_owned and "Sell" or "Purchase" .. string.format(" Tier %s ($%d)", i, price)
			)
			btn_purchase_tier:SizeToContentsX()
			btn_purchase_tier:Dock(LEFT)
			btn_purchase_tier:SetTextColor(text_col)

			function btn_purchase_tier:DoClick()
				GAMEMODE:RequestPurchaseUpgrade(v.k, i)
			end
		end
	end
end
