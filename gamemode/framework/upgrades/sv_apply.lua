
local function UpdateUpgrades( ply )
	local apply = {}
	-- First remove
	for k,v in ipairs( ply.yawd_upgrades ) do
		local upgrade = v.upgrade
		if upgrade then
			if upgrade.can_purchase and not upgrade.can_purchase( ply ) then
				if upgrade.on_unequip and table.HasValue(ply.m_AppliedUpgrades or {}, upgrade.k) then
					upgrade.on_unequip( ply, v.tier )
				end
			elseif upgrade.on_equip then
				table.insert(apply, {upgrade.on_equip, v.tier, upgrade.k})
			end
		end
	end
	ply.m_AppliedUpgrades = {}
	for _,v in ipairs(apply) do
		v[1]( ply, v[2] or 0)
		table.insert(ply.m_AppliedUpgrades, v[3])
	end
	for id,num in ipairs( ply:GetAmmo() ) do
		local ammo_name = game.GetAmmoName( id )
		local ammo_max = (ply.m_StartingAmmo[ammo_name] or 0)
		if num > ammo_max then
			ply:SetAmmo( ammo_max , id)
		end
	end
end
hook.Add("YAWDApplyUpgrades", "YAWDUpdateUpgrades", UpdateUpgrades)

hook.Add("PlayerDeath", "YAWDDeathUpgrade", function(ply, _, attacker)
	for k,v in ipairs( ply.yawd_upgrades ) do
		local upgrade = v.upgrade
		if not upgrade then continue end
		if not upgrade.on_kill then continue end
		upgrade.on_kill(ply, v.tier or 1, attacker)
	end
end)