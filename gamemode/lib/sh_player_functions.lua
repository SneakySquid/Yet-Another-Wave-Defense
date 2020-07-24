local PLAYER = FindMetaTable("Player")

-- Currency
if SERVER then
    function PLAYER:AddCurrency(amt)
        self:SetCurrency(self:GetCurrency() + amt)
    end
end
