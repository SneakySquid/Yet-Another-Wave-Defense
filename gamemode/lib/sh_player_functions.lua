
local meta = FindMetaTable("Player")

-- Currency
if SERVER then
    function meta:GetCurrency()
        return self.currency or 0
    end
    function meta:SetCurrency( num )
        self.currency = num
        self:SetNWInt("yawd_currency", num)
    end
    function meta:AddCurrency( num )
        self:SetCurrency(self:GetCurrency() + num)
    end
else
    function meta:GetCurrency()
        return self:GetNWInt("yawd_currency", 0)
    end
end
