--[[
	TODO:
		- Open menu when client +uses the core
		- Menu

	Upgrade ideas:
		- Speed
		- Resistance(s)
		- Armour
		- Health regen
		- Max health
		- Weapon clip increase
]]

local registered_upgrades = {}

--[[ RegisterUpgrade() table format
{
	name,			the name of the upgrade
	price,			the price of the upgrade, can either be a number or a table for prices of each tier
	can_purchase, 	optional function override for upgrades that aren't just restricted by price. args: tbd
	on_purchase,	optional function that is called when a player purchases the upgrade
}
--]]
function GM:RegisterUpgrade(t)
	local function _assert(cond, key)
		assert(cond, string.format("Upgrade table given to RegisterUpgrade has invalid key: %s", key))
	end

	_assert(isstring(t.name), "name")
	_assert(isnumber(t.price) or istable(t.price), "price")
	_assert(t.can_purchase == nil or isfunction(t.can_purchase), "can_purchase")
	_assert(t.on_purchase == nil or isfunction(t.on_purchase), "on_purchase")

	t.tiers = istable(t.price) and #t.price or nil

	local k = table.insert(registered_upgrades, t)
	t.k = k

	DebugMessage(string.format("Registered upgrade '%s'", t.name))

	return k
end

function GM:GetUpgradesTable()
	return registered_upgrades
end

function GM:GetUpgrade(key)
	return registered_upgrades[key]
end

function GM:GetUpgradeByName(name)
	for _, upgrade in ipairs(registered_upgrades) do
		if upgrade.name == name then
			return upgrade
		end
	end
end

-- NOTE: A client's upgrades aren't networked to other clients
function GM:PlayerHasUpgrade(ply, key)
	for _, upgrade in ipairs(ply.yawd_upgrades or {}) do
		if upgrade.k == key then
			return true, upgrade.tier or 1
		end
	end

	return false
end

function GM:GetPlayerUpgrades(ply)
	return ply.yawd_upgrades or {}
end

function GM:GetUpgradeRefundPercentage()
	return 0.5
end

function GM:GetUpgradeRefundAmount(upgrade, purchased_upgrade_tiers)
	local amt = 0

	if isnumber(upgrade.price) then
		amt = purchased_upgrade_tiers * upgrade.price
	elseif istable(upgrade.price) then
		for i = 1, math.min(purchased_upgrade_tiers, #upgrade.price) do
			amt = amt + upgrade.price[i]
		end
	end

	return amt * GAMEMODE:GetUpgradeRefundPercentage()
end

if SERVER then
	AddCSLuaFile("upgrades/cl_upgrades.lua")

	include("upgrades/sv_upgrades.lua")
	include("upgrades/sv_net.lua")
else
	include("upgrades/cl_upgrades.lua")
end

---------- Upgrades ----------

YAWD_UPGRADE_MOVEMENTSPEED = GM:RegisterUpgrade({
	name = "Movement Speed",
	price = {100, 200, 300, 400, 500},
})

-- TODO: There should probably be a resistance upgrade for each element
YAWD_UPGRADE_RESISTANCE = GM:RegisterUpgrade({
	name = "Resistance",
	price = 500,
})

YAWD_UPGRADE_ARMOUR = GM:RegisterUpgrade({
	name = "Armour",
	price = 500,
})

YAWD_UPGRADE_HEALTHREGEN = GM:RegisterUpgrade({
	name = "Health Regen",
	price = 500,
})

YAWD_UPGRADE_MAXHEALTH = GM:RegisterUpgrade({
	name = "Max Health",
	price = 500,
})

YAWD_UPGRADE_WEAPONCLIPSIZE = GM:RegisterUpgrade({
	name = "Weapon Clip Size",
	price = 500,
})
