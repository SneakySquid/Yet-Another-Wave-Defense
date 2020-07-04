do return end
local meta = FindMetaTable("Player")

-- Currency
if SERVER then
	local currency = {}
	function meta:GetCurrency()
		return currency[self:SteamID()] or 0
	end
	function meta:SetCurrency( num )
		currency[self:SteamID()] = num
		self:SetNWInt("yawd_currency", num)
	end
	function meta:AddCurrency( num )
		self:SetCurrency(self:GetCurrency() + num)
	end
	-- Update reconnecting players with their old currency.
	hook.Add("PlayerInitialSpawn", "yawd.currency.updater", function(ply)
		if not currency[ply:SteamID()] then return end
		ply:SetNWInt("yawd_currency", currency[ply:SteamID()])
	end)
	-- Resets the currency.
	function GM:ResetCurrency()
		currency = {}
		for k,v in ipairs(players.GetAll()) do
			v:SetNWInt("yawd_currency", 0)
		end
	end
else
	function meta:GetCurrency()
		return self:GetNWInt("yawd_currency", 0)
	end
end
