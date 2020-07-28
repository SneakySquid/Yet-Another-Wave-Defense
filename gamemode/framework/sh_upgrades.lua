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
	hooks,			optional table of hooks that allow this upgrade to function. format follows.
					{
						{
							event		e.g. PlayerSpawn
							callback
						}
					}
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
	_assert(t.hooks == nil or istable(t.hooks), "hooks")

	t.tiers = istable(t.price) and #t.price
	t.hooks = t.hooks or {}

	for _, v in ipairs(t.hooks) do
		hook.Add(v.event, string.format("yawd.upgrade.%s", t.name), v.callback)
	end

	table.insert(registered_upgrades, t)

	DebugMessage(string.format("Registered upgrade '%s' with %d hooks", t.name, #t.hooks))
end

function GM:GetUpgradesTable()
	return registered_upgrades
end

if SERVER then
	AddCSLuaFile("upgrades/cl_upgrades.lua")

	include("upgrades/sv_upgrades.lua")
else
	include("upgrades/cl_upgrades.lua")
end

---------- Upgrades ----------

GM:RegisterUpgrade({
	name = "Movement Speed",
	price = {100, 200, 300, 400, 500},
})

-- TODO: There should probably be a resistance upgrade for each element
GM:RegisterUpgrade({
	name = "Resistance",
	price = 500,
})

GM:RegisterUpgrade({
	name = "Armour",
	price = 500,
})

GM:RegisterUpgrade({
	name = "Health Regen",
	price = 500,
})

GM:RegisterUpgrade({
	name = "Max Health",
	price = 500,
})

GM:RegisterUpgrade({
	name = "Weapon Clip Size",
	price = 500,
})
