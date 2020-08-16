

util.AddNetworkString("YAWD.WeaponSlotUpdate")

local update_cache = {}
hook.Add("WeaponEquip", "YAWDWeaponSelect", function( wep, ply )
	if (update_cache[ply] or 0) > CurTime() then return end
	if ply:HasWeapon( wep:GetClass() ) then return end
	net.Start("YAWD.WeaponSlotUpdate")
		net.WriteBool( true )
		net.WriteString( wep:GetClass() )
	net.Send( ply )
	update_cache[ply] = CurTime() + .5
end)

local meta = FindMetaTable("Player")

_YAWDORIGINAL_SelectWeapon = _YAWDORIGINAL_SelectWeapon or meta.SelectWeapon
function meta:SelectWeapon( className )
	net.Start("YAWD.WeaponSlotUpdate")
		net.WriteBool( false )
		net.WriteString( className )
	net.Send( self )
	_YAWDORIGINAL_SelectWeapon( self, className )
end