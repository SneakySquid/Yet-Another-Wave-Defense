function GM:RequestPurchaseUpgrade(upgrade_key, tier_desired)
	net.Start("yawd.upgrades.purchase")
		net.WriteUInt(upgrade_key, 32)
		net.WriteUInt(tier_desired, 8)
	net.SendToServer()

	DebugMessage(string.format("Requested to purchase upgrade %d:%d", upgrade_key, tier_desired))
end

function GM:RequestSellUpgrade(upgrade_key, tier_desired)
	net.Start("yawd.upgrades.sell")
		net.WriteUInt(upgrade_key, 32)
		net.WriteUInt(tier_desired, 8)
	net.SendToServer()

	DebugMessage(string.format("Requested to sell upgrade %d to tier %d", upgrade_key, tier_desired))
end

net.Receive("yawd.upgrades.menu", function()
	GAMEMODE:CreateUpgradesMenu()
end)

net.Receive("yawd.upgrades.owned", function()
	local num = net.ReadUInt(32)
	local upgrades = {}

	for i = 1, num do
		upgrades[i] = {
			upgrade = GAMEMODE:GetUpgrade(net.ReadUInt(32)),
			tier = net.ReadUInt(8),
		}
	end

	GAMEMODE:PlayerSetUpgrades(LocalPlayer(), upgrades)

	DebugMessage("Received owned player upgrades from server")
end)
