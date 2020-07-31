local PLAYER = FindMetaTable("Player")

-- Currency
if SERVER then
	function PLAYER:AddCurrency(amt)
		self:SetCurrency(self:GetCurrency() + amt)
	end

	function PLAYER:YAWDGiveAmmo(f)
		if not self.m_StartingAmmo then return false end

		f = f or 0.2

		for type, start_amt in pairs(self.m_StartingAmmo) do
			local current_amt = self:GetAmmoCount(type)

			if current_amt < start_amt then
				local new_amt = math.min(start_amt, math.floor(start_amt * f))

				if new_amt + current_amt <= start_amt then
					self:GiveAmmo(new_amt, type, false)
				else
					self:GiveAmmo(start_amt - current_amt, type, false)
				end
			end
		end

		return true
	end
else
	local avatars = {}
	function PLAYER:GetAvatar()
		local id = self:SteamID()

		if not avatars[id] then
			local a = vgui.Create("AvatarImage")
			a:SetSize(128, 128)
			a:SetPlayer(self, 128)
			a:SetPaintedManually(true)

			avatars[id] = a
		end

		return avatars[id]
	end
end
