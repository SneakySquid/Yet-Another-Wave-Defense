util.AddNetworkString("yawd.upgrades.purchase")
util.AddNetworkString("yawd.upgrades.sell")

-- TODO: unfinished

local function read_upgrade()
	local key = net.ReadUInt(32)

	return GAMEMODE:GetUpgrade(key)
end

net.Receive("yawd.upgrades.purchase", function(len, ply)
	local upgrade = read_upgrade()
	local tier = net.ReadUInt(8)

	if upgrade and tier > 0 and (isfunction(upgrade.can_purchase) and
		upgrade.can_purchase(ply) or self:GetCurrency() >= upgrade.price) then

		local tier_owned = GAMEMODE:GetPlayerUpgradeTier(ply, upgrade.k)
		if tier > tier_owned and tier <= upgrade.tiers then
			ply:AddCurrency(-GAMEMODE:GetUpgradePrice(upgrade, tier, tier_owned))
			upgrade.on_purchased(ply, tier)
		end
	end
end)

net.Receive("yawd.upgrades.sell", function(len, ply)
	local upgrade = read_upgrade()
	local tier_new = net.ReadUInt(8)

	if upgrade then
		local tier_owned = GAMEMODE:GetPlayerUpgradeTier(ply, upgrade.k)
		if tier_owned > tier_new then

		end
	end
end)
