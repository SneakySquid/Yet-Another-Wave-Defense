util.AddNetworkString("yawd.upgrades.purchase")
util.AddNetworkString("yawd.upgrades.sell")
util.AddNetworkString("yawd.upgrades.menu")

function GM:OpenUpgradesMenuOnPlayer(ply)
	net.Start("yawd.upgrades.menu")
	net.Send(ply)
end

local function read_upgrade()
	local key = net.ReadUInt(32)

	return GAMEMODE:GetUpgrade(key)
end

net.Receive("yawd.upgrades.purchase", function(len, ply)
	local upgrade = read_upgrade()
	local tier_new = net.ReadUInt(8)

	if upgrade and tier_new > 0 and (isnumber(upgrade.price) or tier_new <= upgrade.tiers)
		and (isfunction(upgrade.can_purchase) and upgrade.can_purchase(ply, tier_new) or true) then

		local tier_owned = GAMEMODE:GetPlayerUpgradeTier(ply, upgrade.k)
		local upgrade_price = GAMEMODE:GetUpgradePrice(upgrade.k, tier_new, tier_owned)
		if tier_new > tier_owned and tier_new <= upgrade.tiers and ply:GetCurrency() >= upgrade_price then
			ply:AddCurrency(-upgrade_price)
			GAMEMODE:PlayerSetUpgradeTier(ply, upgrade.k, tier_new)

			if isfunction(upgrade.on_purchase) then
				upgrade.on_purchase(ply, tier_owned, tier_new)
			end

			DebugMessage(string.format("%s purchased upgrade '%s':%d for %d",
				ply:Nick(), upgrade.name, tier_new, upgrade_price))
		end
	end
end)

net.Receive("yawd.upgrades.sell", function(len, ply)
	local upgrade = read_upgrade()
	local tier_new = net.ReadUInt(8)

	if upgrade then
		local tier_owned = GAMEMODE:GetPlayerUpgradeTier(ply, upgrade.k)
		if tier_owned > tier_new then
			local refund_amount = GAMEMODE:GetUpgradeRefundAmount(upgrade.k, tier_new, tier_owned)
			ply:AddCurrency(refund_amount)
			GAMEMODE:PlayerSetUpgradeTier(ply, upgrade.k, tier_new)

			if isfunction(upgrade.on_sell) then
				upgrade.on_sell(ply, tier_owned, tier_new)
			end

			DebugMessage(string.format("%s sold %d tiers of upgrade '%s' for %d",
				ply:Nick(), tier_owned - tier_new, upgrade.name, refund_amount))
		end
	end
end)
