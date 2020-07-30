util.AddNetworkString("yawd.upgrades.purchase")
util.AddNetworkString("yawd.upgrades.sell")
util.AddNetworkString("yawd.upgrades.menu")
util.AddNetworkString("yawd.upgrades.owned")

function GM:OpenUpgradesMenuOnPlayer(ply)
	net.Start("yawd.upgrades.menu")
	net.Send(ply)
end

function GM:NetworkUpgrades(ply)
	local upgrades = GAMEMODE:GetPlayerUpgrades(ply)

	net.Start("yawd.upgrades.owned")
	net.WriteUInt(#upgrades, 32)

	for _, v in ipairs(upgrades) do
		net.WriteUInt(v.upgrade.k, 32)
		net.WriteUInt(v.tier, 8)
	end

	net.Send(ply)
end

local function read_upgrade()
	local key = net.ReadUInt(32)

	return GAMEMODE:GetUpgrade(key)
end

net.Receive("yawd.upgrades.purchase", function(len, ply)
	local upgrade = read_upgrade()
	local tier_new = net.ReadUInt(8)

	if upgrade and tier_new > 0 then
		local tier_owned = GAMEMODE:GetPlayerUpgradeTier(ply, upgrade.k)

		if tier_new > tier_owned and tier_new <= upgrade.tiers then
			local upgrade_price = GAMEMODE:GetUpgradePrice(upgrade.k, tier_new, tier_owned)

			if ply:GetCurrency() >= upgrade_price and (isfunction(upgrade.can_purchase)
				and upgrade.can_purchase(ply, tier_new) or true) then

				ply:AddCurrency(-upgrade_price)
				GAMEMODE:PlayerSetUpgradeTier(ply, upgrade.k, tier_new)

				if isfunction(upgrade.on_purchase) then
					upgrade.on_purchase(ply, tier_owned, tier_new)
				end

				DebugMessage(string.format("%s purchased upgrade '%s':%d for %d",
					ply:Nick(), upgrade.name, tier_new, upgrade_price))
			end
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
