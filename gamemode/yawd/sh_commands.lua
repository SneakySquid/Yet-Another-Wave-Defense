-- Adds a few concommands
-- Gives currency
concommand.Add( "yawd_give_currency", function(ply, cmd,_ , args)
	local num = tonumber(args) or 0
	if not ply then
		for k,v in ipairs( player.GetAll() ) do
			v:AddCurrency(num)
		end
	elseif IsValid( ply ) then
		ply:AddCurrency(num)
	end
end, nil, "Gives currency", FCVAR_CHEAT )

-- Sets the wavenumber
concommand.Add( "yawd_set_wave", function(ply, cmd,_ , args)
	local num = tonumber(args) or 0
	GAMEMODE:SetWaveNumber( num )
end, nil, "Sets the wave number", FCVAR_CHEAT )

-- Deletes all NPCs from current wave
concommand.Add( "yawd_delete_npcs", function(ply, cmd)
	for k,v in ipairs( ents.FindByClass("yawd_npc_base") ) do
		SafeRemoveEntity( v )
	end
end, nil, "Deletes all NPCs", FCVAR_CHEAT )