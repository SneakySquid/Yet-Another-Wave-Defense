
local b = {}
b.Name = "Ammo Station"
b.Icon = Material("yawd/hud/ammo_box.png")
b.BuildClass = {CLASS_BOMBER, CLASS_FIGHTER, CLASS_JUGGERNAUT, CLASS_GUNNER }
b.Cost = 350
b.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}

b.TrapTriggerTime = 0	-- Time it takes to trigger
b.TrapResetTime = 0	-- Time it takes to reset
b.TrapDurationTime = 0	-- Time it takes to stop

local mdl = Model("models/Items/ammocrate_smg1.mdl")
-- Trap logic
	if CLIENT then
		local on_create = function(self, mdl)
			mdl:SetPos(self:GetPos())
			mdl:SetNoDraw(true)
			mdl:SetModelScale(1)
		end
		function b:Init()
			self:CreateClientMdl( mdl, on_create)
		end
	end
	function b:StartTouch( ent )
		if not self.OnTrap then self.OnTrap = {} end
		if not ent:IsPlayer() then return end
		table.insert(self.OnTrap, ent)
	end
	function b:EndTouch(ent)
		if not self.OnTrap then self.OnTrap = {} end
		if not ent:IsPlayer() then return end
		table.RemoveByValue(self.OnTrap, ent)
	end
	function b:HasEnemiesOn() return false end
	function b:GetEnemiesOn() return false end

	if SERVER then
		function b:Think()
			if self:GetDisabled() then return end
			if #self.OnTrap < 1 then return end
			if (self.n_Timer or 0) > CurTime() then return end
			self.n_Timer = CurTime() + 5
			for _,ply in ipairs(self.OnTrap) do
				ply:YAWDGiveAmmo(0.2)
			end
		end
	else
		function b:Think()
			if not IsValid(LocalPlayer()) then return end
			local b = LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 9400
			if not self.n_Open and b then
				local c_ent = self:GetClientMdl( mdl )
				if c_ent and IsValid( c_ent ) then
					c_ent:ResetSequence("close")
				end
				self.n_Open = true
				self:EmitSound("items/ammocrate_open.wav")
			elseif self.n_Open and not b then
				local c_ent = self:GetClientMdl( mdl )
				if c_ent and IsValid( c_ent ) then
					c_ent:ResetSequence("open")
				end
				self.n_Open = false
				self:EmitSound("items/ammocrate_close.wav")
			end
		end
	end
if SERVER then return b end 

function b:OnTrapTrigger( )
	local c_ent = self:GetClientMdl( mdl )
	if c_ent and IsValid( c_ent ) then
		c_ent:ResetSequence("close")
	end
end

function b:Draw()
	-- Renders the bottom of the trap
	self:RenderBase()
	-- Render turret
	local c_ent = self:GetClientMdl( mdl )
	if c_ent and IsValid( c_ent ) then
		c_ent:SetRenderOrigin(self:LocalToWorld(Vector(0,0,16)))
		c_ent:DrawModel()
		c_ent:SetRenderAngles(self:GetAngles())
	end
	-- Renders the trap area
	self:RenderTrapArea()
end
function b:DrawSelection( )
	self:RenderBase()
	self:RenderTrapArea()
end
return b