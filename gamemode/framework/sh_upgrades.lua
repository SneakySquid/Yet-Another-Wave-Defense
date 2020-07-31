--[[
	TODO:
		- make on_purchase and on_sell shared
--]]

local registered_upgrades = {}

--[[ RegisterUpgrade() table format
name,			required. upgrade name.
price,			required. can either be a number or a table for prices of each tier.
hooks,			optional. hook table: { { event, realm, callback }, ... } (realm="client/server/shared")
can_purchase, 	optional function for upgrades that aren't just restricted by price. args: ply, tier
on_purchase,	optional function. args: ply, tier_old, tier_new
on_sell,		optional function. args: ply, tier_old, tier_new
--]]
function GM:RegisterUpgrade(t)
	local function _assert(cond, key)
		assert(cond, string.format("Upgrade table given to RegisterUpgrade has invalid key: %s", key))
	end

	_assert(isstring(t.name), "name")
	_assert(isnumber(t.price) or istable(t.price), "price")
	_assert(t.hooks == nil or istable(t.hooks), "hooks")
	_assert(t.can_purchase == nil or isfunction(t.can_purchase), "can_purchase")
	_assert(t.on_purchase == nil or isfunction(t.on_purchase), "on_purchase")
	_assert(t.on_sell == nil or isfunction(t.on_sell), "on_sell")

	t.can_purchase = t.can_purchase or function() return true end
	t.tiers = istable(t.price) and #t.price or 1

	for _, v in ipairs(t.hooks or {}) do
		local r = v.realm
		local n = string.format("yawd.upgrades.%s", t.name)

		if (SERVER and (r == nil or r == "server"))
			or (CLIENT and r == "client")
			or r == "shared" then

			hook.Add(v.event, n, v.callback)
		end
	end

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
function GM:GetPlayerUpgradeTier(ply, upgrade_key)
	for _, v in ipairs(ply.yawd_upgrades or {}) do
		if v.upgrade.k == upgrade_key then
			return v.tier
		end
	end

	return 0
end

function GM:PlayerSetUpgradeTier(ply, upgrade_key, new_tier)
	ply.yawd_upgrades = ply.yawd_upgrades or {}

	if GAMEMODE:GetPlayerUpgradeTier(ply, upgrade_key) > 0 then
		for k, v in ipairs(ply.yawd_upgrades) do
			if v.upgrade.k == upgrade_key then
				if new_tier <= 0 then
					table.remove(ply.yawd_upgrades, k)
					break
				else
					v.tier = new_tier
					break
				end
			end
		end
	else
		table.insert(ply.yawd_upgrades, {
			upgrade = GAMEMODE:GetUpgrade(upgrade_key),
			tier = new_tier,
		})
	end

	GAMEMODE:NetworkUpgrades(ply)
end

function GM:PlayerSetUpgrades(ply, upgrades)
	ply.yawd_upgrades = upgrades

	if SERVER then
		GAMEMODE:NetworkUpgrades(ply)
	end
end

function GM:GetPlayerUpgrades(ply)
	return ply.yawd_upgrades or {}
end

function GM:GetUpgradePrice(upgrade_key, tier_desired, tier_owned)
	local upgrade = GAMEMODE:GetUpgrade(upgrade_key)
	if upgrade.tiers > 1 and isnumber(upgrade.price) then
		return upgrade.price * (tier_owned - tier_desired)
	elseif upgrade.tiers == 1 then
		return upgrade.price
	elseif upgrade.tiers > 1 and istable(upgrade.price) then
		local total_price = 0

		for i = tier_owned + 1, math.min(tier_desired, #upgrade.price) do
			total_price = total_price + upgrade.price[i]
		end

		return total_price
	end
end

function GM:GetUpgradeRefundAmount(upgrade_key, tier_desired, tier_owned)
	return self:GetUpgradePrice(upgrade_key, tier_owned, tier_desired)
		* GAMEMODE:GetUpgradeRefundPercentage()
end

function GM:GetUpgradeRefundPercentage()
	return 0.5
end

if SERVER then
	AddCSLuaFile("upgrades/cl_net.lua")
	AddCSLuaFile("upgrades/cl_menu.lua")

	include("upgrades/sv_net.lua")
else
	include("upgrades/cl_net.lua")
	include("upgrades/cl_menu.lua")
end

---------- Upgrades ----------

do
	local lookup = {
		50, 100, 150, 200, 250,
	}

	local function apply(ply, old_tier, new_tier)
		local tier = new_tier or GAMEMODE:GetPlayerUpgradeTier(ply, YAWD_UPGRADE_MOVEMENTSPEED)
		if tier > 0 then
			local x = lookup[tier]

			timer.Simple(0, function() -- Disgusting workaround
				if IsValid(ply) then
					ply:SetWalkSpeed(ply:GetWalkSpeed() + x)
					ply:SetRunSpeed(ply:GetRunSpeed() + x)
				end
			end)
		end
	end

	YAWD_UPGRADE_MOVEMENTSPEED = GM:RegisterUpgrade({
		name = "Movement Speed",
		price = {500, 750, 1000, 1250, 1500},
		on_purchase = apply,
		hooks = {
			{
				event = "PlayerSpawn",
				realm = "server",
				callback = function(ply, is_transition)
					apply(ply)
				end,
			},
		},
	})
end

-- TODO: Resistance upgrade for each element?
do
	local lookup = {
		0.98, 0.96, 0.94, 0.92, 0.9,
	}

	YAWD_UPGRADE_RESISTANCE = GM:RegisterUpgrade({
		name = "Resistance",
		price = {1000, 1500, 2000, 2500, 3000},
		hooks = {
			{
				event = "EntityTakeDamage",
				realm = "server",
				callback = function(ent, dmg)
					if ent:IsPlayer() then
						local tier = GAMEMODE:GetPlayerUpgradeTier(ent, YAWD_UPGRADE_RESISTANCE)
						local mul = lookup[tier]

						if mul then
							dmg:ScaleDamage(mul)
						end
					end
				end,
			},
		},
	})
end

do
	local lookup = {
		25, 50, 75, 100, 125,
	}

	local function apply(ply, old_tier, new_tier)
		local tier = new_tier or GAMEMODE:GetPlayerUpgradeTier(ply, YAWD_UPGRADE_ARMOUR)
		if tier > 0 then
			timer.Simple(0, function() -- Disgusting workaround
				if IsValid(ply) then
					ply:SetArmor(lookup[tier])
				end
			end)
		end
	end

	YAWD_UPGRADE_ARMOUR = GM:RegisterUpgrade({
		name = "Armour",
		price = {300, 600, 900, 1200, 1500},
		on_purchase = apply,
		hooks = {
			{
				event = "PlayerSpawn",
				realm = "server",
				callback = function(ply, transition)
					apply(ply)
				end,
			},
		},
	})
end

do
	local COOLDOWN_AFTER_DAMAGE = 5
	local REGEN_RATE = .2
	local HEALTH_PER_REGEN = 1

	YAWD_UPGRADE_HEALTHREGEN = GM:RegisterUpgrade({
		name = "Health Regen",
		price = 3000,
		hooks = {
			{
				event = "Think",
				realm = "server",
				callback = function()
					for _, ply in ipairs(player.GetAll()) do
						if ply:Alive() then
							local tier = GAMEMODE:GetPlayerUpgradeTier(ply, YAWD_UPGRADE_HEALTHREGEN)

							if tier > 0 then
								local time = CurTime()
								local health = ply:Health()

								if health < ply:GetMaxHealth()
									and time > (ply.last_damage_time or 0) + COOLDOWN_AFTER_DAMAGE
									and time > (ply.next_health_regen or 0) then

									ply:SetHealth(health + HEALTH_PER_REGEN)
									ply.next_health_regen = CurTime() + REGEN_RATE
								end
							end
						end
					end
				end,
			},
			{
				event = "EntityTakeDamage",
				realm = "server",
				callback = function(ent, dmg)
					if ent:IsPlayer() then
						ent.last_damage_time = CurTime()
					end
				end,
			},
		},
	})
end

do
	local lookup = {
		1.04, 1.08, 1.12
	}

	local function apply(ply, tier_old, tier_new)
		local tier = tier_new or GAMEMODE:GetPlayerUpgradeTier(ply, YAWD_UPGRADE_MAXOVERHEAL)
		local mul = lookup[tier]

		if mul then
			timer.Simple(0, function() -- Disgusting workaround
				if IsValid(ply) then
					ply:SetMaxHealth(ply:GetMaxHealth() * mul)
				end
			end)
		end
	end

	YAWD_UPGRADE_MAXOVERHEAL = GM:RegisterUpgrade({
		name = "Max Overheal",
		price = { 1500, 3000, 4500 },
		on_purchase = apply,
		hooks = {
			{
				event = "PlayerSpawn",
				realm = "server",
				callback = function(ply, transition)
					apply(ply)
				end,
			},
		},
	})
end

YAWD_UPGRADE_WEAPONCLIPSIZE = GM:RegisterUpgrade({
	name = "Weapon Clip Size",
	price = 500,
})

-- Let other stuff know we've loaded
hook.Run("YAWDPlayerUpgradesLoaded")
