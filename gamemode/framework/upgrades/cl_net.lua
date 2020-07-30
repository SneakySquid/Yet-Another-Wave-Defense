function GM:RequestPurchaseUpgrade(upgrade_key, tier_desired)
	net.Start("yawd.upgrades.purchase")
		net.WriteUInt(upgrade_key, 32)
		net.WriteUInt(tier_desired, 8)
	net.SendToServer()
end

function GM:RequestSellUpgrade(upgrade_key, tier_desired)
	net.Start("yawd.upgrades.sell")
		net.WriteUInt(upgrade_key, 32)
		net.WriteUInt(tier_desired, 8)
	net.SendToServer()
end

net.Receive("yawd.upgrades.menu", function()
	GAMEMODE:CreateUpgradesMenu()
end)
