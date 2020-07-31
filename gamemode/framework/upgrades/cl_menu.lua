local frame

function GM:CreateUpgradesMenu()
	DebugMessage("Opening player upgrades menu")

	local localplayer = LocalPlayer()

	frame = vgui.Create("DFrame")
	frame:SetTitle("Upgrades")
	frame:MakePopup()
	frame:SetSize(600, ScrH() / 1.4)
	frame:Center()

	local pnl_scroll = frame:Add("DScrollPanel")
	pnl_scroll:Dock(FILL)
	pnl_scroll:DockMargin(10, 10, 10, 10)

	for _, v in ipairs(GAMEMODE:GetUpgradesTable()) do
		if v.can_purchase(localplayer, 1) then
			local pnl = pnl_scroll:Add("DPanel")
			pnl:SetTall(100)
			pnl:Dock(TOP)
			pnl:DockMargin(0, 0, 0, 20)
			pnl.Paint = function() end

			local name = pnl:Add("DLabel")
			name:SetText(v.name)
			name:Dock(TOP)
			name:SetTall(30)

			for i = 1, v.tiers do
				local owned_tier = GAMEMODE:GetPlayerUpgradeTier(localplayer, v.k)
				local is_owned = owned_tier >= i
				local price = istable(v.price) and v.price[i] or v.price

				if is_owned then
					price = price * GAMEMODE:GetUpgradeRefundPercentage()
				end

				local text_col = is_owned and Color(180, 0, 0, 255) or Color(0, 140, 0, 255)
				local text = string.format("%s Tier %s for $%d", is_owned and "Sell" or "Purchase", i, price)

				local btn_purchase_tier = pnl:Add("DButton")
				btn_purchase_tier:SetText(text)
				btn_purchase_tier:SizeToContentsX()
				btn_purchase_tier:DockMargin(5, 0, 0, 0)
				btn_purchase_tier:Dock(LEFT)
				btn_purchase_tier:SetTextColor(text_col)

				function btn_purchase_tier:DoClick()
					if is_owned then
						GAMEMODE:RequestSellUpgrade(v.k, i - 1)
					else
						GAMEMODE:RequestPurchaseUpgrade(v.k, i)
					end
				end

				if not is_owned and not v.can_purchase(localplayer, i) then
					btn_purchase_tier:SetEnabled(false)
				end
			end
		end
	end
end

function GM:RefreshUpgradesMenu()
	if IsValid(frame) then
		frame:Remove()
		GAMEMODE:CreateUpgradesMenu()
	end
end
