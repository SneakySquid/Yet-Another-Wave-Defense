local PLAYER = FindMetaTable("Player")

function PLAYER:AddCurrency(amt)
	self:SetCurrency(self:GetCurrency() + amt)
end
