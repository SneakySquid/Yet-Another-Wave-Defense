
--[[
	The base of buildings.
		! = Internal function and shouldn't be used

	Functions
		SV	ENT:SetDisabled( bool )	Disables the building.
		SV	ENT:GetDisabled( )		Returns true if the building is disabled.
		SV	ENT:UpgradeBuilding() 	Increases the building upgrade by one.
		SH	ENT:GetUpgrades()		Returns the amount of upgrades.
		SH	ENT:DamageInfo()		Returns a DamageInfo with owner details.
		SH 	ENT:GetBuildingData()	Returns the buildingdata.
		CL	ENT:IsMine()			Returns true if it is your building.

	Trapfunctions
	!	SH	ENT:EnableTrigger( vMin, vMax )		Spawns a trigger entity
	!	SH	EMT:SetTriggerSize( vMin, vMax )	Changes the triggersize. (This won't update clients and trap-area)
		SH	ENT:GetTrapArea()					Returns the trap-area defined by buildingdata.
		SH 	ENT:OnTrapTrigger( ListOfEnemies )	Gets called when the trap triggers
		SH 	ENT:OnTrapThink()					Gets called every tick the trap is active.
		SH	ENT:OnTrapEnd()						Gets called when the trap stops.
		SH	ENT:OnTrapReset()					Gets called when the trap resets.
		SV	ENT:HasEnemiesOn()					Returns true if the trap has enemies on.
		SV	ENT:GetEnemiesOn()					Returns a list of current enemies on the trap.
	!	SV	ENT:StartTouch( ent )
	!	SV	ENT:EndTouch( ent )
		CL	ENT:RenderTrapArea( color )			Renders the trap-area defined by buildingdata.
		CL	ENT:RenderBase(top_texture)			Renders the bottom of traps.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.DisableDuplicator = true

ENT.Model = Model( "models/hunter/plates/plate4x4.mdl" )
ENT.RenderGroup = RENDERGROUP_BOTH
if SERVER then
	util.AddNetworkString("yawd.traptrigger")
end
-- Trap functions and variables
ENT.TrapArea = {-Vector(95, 95, 1.7), Vector(95, 95, 95)}
ENT.TrapTriggerTime = -1
ENT.TrapResetTime = -1
ENT.TrapDurationTime = -1
-- Gets called when the trap triggers
function ENT:OnTrapTrigger()
end
-- Gets called on think within the trap duration
function ENT:OnTrapThink()
end
-- Gets called when the trap duration ends
function ENT:OnTrapEnd()
end
-- Gets called when the trap resets
function ENT:OnTrapReset()
end
-- Gets called when the trap upgrades
function ENT:OnTrapUpgrade()
end
-- Creats a damageinfo for the trap.
function ENT:DamageInfo()
	local dm = DamageInfo()
	dm:SetAttacker( self:GetBuildingOwner() )
	dm:SetInflictor( self )
	return dm
end
function ENT:Initialize()
	self:SetModel( self.Model )
	if SERVER then
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:Sleep()
		end
		self:SetUseType( SIMPLE_USE )
	end
	if self.TrapArea then
		self:EnableTrigger(self.TrapArea[1], self.TrapArea[2])
	end
	if CLIENT then
		Building.ApplyFunctions( self )
	end
	self.OnTrap = {}
end

if SERVER then
	function ENT:UpgradeBuilding()
		self:SetUpgrades( self:GetUpgrades() +1 )
		self:OnTrapUpgrade()
	end
	function ENT:EnableTrigger(vMin, vMax)
		if self.e_trigger then return end
		self.e_trigger = ents.Create("yawd_building_trigger")
		self.e_trigger:SetPos(self:GetPos())
		self.e_trigger:SetAngles(self:GetAngles())
		self.e_trigger:SetArea(vMin, vMax)
		self.e_trigger:SetOwner(self)
		self.e_trigger:Spawn()
		self.e_trigger:SetParent(self)
	end
	function ENT:OnRemove()
		SafeRemoveEntity(self.e_trigger)
		if self.b_OnRemove then
			self.b_OnRemove(self)
		end
	end
	function ENT:SetTriggerSize(vMin, vMax)
		self.e_trigger:SetArea(vMin, vMax)
	end
	function ENT:GetBuildingData()
		return self.builddata
	end
	local function ClearTouch(self)
		for i = #self.OnTrap, 1, -1 do
			if not IsValid(self.OnTrap[i]) then
				table.remove(self.OnTrap, i)
			end
		end
	end
	function ENT:StartTouch( ent )
		if not self.OnTrap then self.OnTrap = {} end
		if not Building.CanTarget( ent ) then return end
		table.insert(self.OnTrap, ent)
	end
	function ENT:EndTouch(ent)
		if not self.OnTrap then self.OnTrap = {} end
		if not Building.CanTarget( ent ) then return end
		table.RemoveByValue(self.OnTrap, ent)
	end
	function ENT:HasEnemiesOn()
		if not self.OnTrap then self.OnTrap = {} end
		ClearTouch(self)
		return next( self.OnTrap ) ~= nil
	end
	function ENT:GetEnemiesOn()
		ClearTouch(self)
		return self.OnTrap
	end
	-- Trap logic
	function ENT:Think()
		-- Check if this trap can trigger
		if not IsValid(self.e_trigger) then return end 	-- No trigger
		if self.TrapTriggerTime < 0 then return end 	-- Wait for spring
		-- Check if the trap has triggered
		if self.i_duration then
			if self.i_duration > CurTime() and not self:GetDisabled() then
				self:OnTrapThink()
			else
				self.i_duration = nil
				self.i_reset = CurTime() + self.TrapResetTime
				self:OnTrapEnd()
			end
			return
		end
		-- Don't trigger if disabled
		if self:GetDisabled() then return end
		if self.i_duration then return end -- Still on
		if self.i_reset then
			if self.i_reset >= CurTime() then return end
			self.i_reset = nil
		end
		-- Check if there are enemies on it [ BUG: Triggers seems to go on and off randomlly.]
		if not self:HasEnemiesOn() and not self.i_triggerpoint then
			return
		end
		-- Set the springtime
		if not self.i_triggerpoint then
			self.i_triggerpoint = CurTime() + self.TrapTriggerTime
			DebugMessage(string.format("%s: Trigger-timer started ..", self))
		elseif self.i_triggerpoint <= CurTime() then -- Trigger the trap
			--[[if not self:HasEnemiesOn() then -- They ran away
				self.i_triggerpoint = nil
				DebugMessage(string.format("%s: I'm empty. Reset trigger.", self))
				return
			end]]
			local t = self:OnTrapTrigger( self:GetEnemiesOn() )
			if not t and t == false then -- Trap returned false
				self.i_triggerpoint = nil
				DebugMessage(string.format("%s: I'm not allowe to trigger", self))
				return
			end
			-- Trigger it
			t = t or self:GetEnemiesOn()
			net.Start("yawd.traptrigger")
				net.WriteEntity(self)
				net.WriteInt(#t, 32)
				for i = 1, #t do
					net.WriteEntity( t[i] )
				end
			net.Broadcast()
			DebugMessage(string.format("%s: Trap triggered.", self))
			self.i_triggerpoint = nil
			self.i_duration = CurTime() + self.TrapDurationTime
		end
	end
else
	net.Receive("yawd.traptrigger", function()
		local ent = net.ReadEntity()
		if not ent or not IsValid( ent ) then return end
		local n = net.ReadInt(32)
		local t = {}
		for i = 1, n do
			t[i] = net.ReadEntity()
		end
		ent:OnTrapTrigger( t )
		ent.i_duration = CurTime() + (ent.TrapDurationTime or 0)
	end)
	function ENT:EnableTrigger( vMin, vMax )
		self.TrapArea, self.TrapArea = vMin, vMax
	end
	function ENT:SetTriggerSize( vMin, vMax )
		self.TrapArea, self.TrapArea = vMin, vMax
	end
	function ENT:IsMine()
		if not IsValid(self:GetBuildingOwner()) then return false end
		return self:GetBuildingOwner() == LocalPlayer()
	end
	function ENT:GetBuildingData()
		if self.builddata then return self.builddata end
		local bn = self:GetBuildingName()
		if bn == "" then return {} end
		self.builddata = Building.GetData( bn )
		return self.builddata
	end
	local mat = Material("yawd/trap_area.png","nocull")
	local default = Color(155,155,255,20)
	local default_disabled = Color(255,155,155,20)
	function ENT:RenderTrapArea( color )
		if GAMEMODE:HasWaveStarted() then return end -- Only render trap area when the wave hasn't started.
		local vmin,vmax = self:GetTrapArea()
		color = color or self:GetDisabled() and default_disabled or default
		color.a = 20
		render.SetMaterial(mat)
		render.DrawBox(self:GetPos(), self:GetAngles(), vmin,vmax, color)
		render.SetColorMaterial()
		color.a = 15
		render.DrawBox(self:GetPos(), self:GetAngles(), vmin,vmax, color)
	end
	function ENT:Think()
		if self.i_duration then
			if self.i_duration >= CurTime() then
				self:OnTrapThink()
			else
				self.i_duration = nil
				self.i_reset = CurTime() + (self.TrapResetTime or 0)
				self:OnTrapEnd()
			end
		end
		if not self.i_reset then return end
		if self.i_reset > CurTime() then return end
		self.i_reset = nil
		self:OnTrapReset()
	end
	local base = Material("yawd/models/trap_base")
	local side = Material("yawd/models/trap_side")

	-- Source can't handle Meshes on loading.
	local TopMesh
	local SideMesh
	local function GenerateMesh()
		TopMesh = Mesh(Material("yawd/models/trap_base"))
		local udata = {Vector(0,0,0),Vector(0,0,0),Vector(0,0,0),Vector(0,0,0)}
		local function Quad(tab)	-- LT RT RB LB
			local t = {}
			table.insert(t, tab[1])
			table.insert(t, tab[2])
			table.insert(t, tab[3])
			table.insert(t, tab[3])
			table.insert(t, tab[4])
			table.insert(t, tab[1])
			return t
		end
		TopMesh:BuildFromTriangles(Quad({
			{ pos = Vector( -0.5,-0.5,0.5 ), u = 0, v = 0, normal = vector_up , tangent = Vector(0, 1, 0), userdata = {-4.371,0.999,0,-1}},
			{ pos = Vector( -0.5,0.5, 0.5 ), u = 0, v = 1, normal = vector_up , tangent = Vector(0, 1, 0), userdata = {-4.371,0.999,0,-1}},
			{ pos = Vector( 0.5, 0.5, 0.5 ), u = 1, v = 1, normal = vector_up , tangent = Vector(0, 1, 0), userdata = {-4.371,0.999,0,-1}},
			{ pos = Vector( 0.5,-0.5, 0.5 ), u = 1, v = 0, normal = vector_up , tangent = Vector(0, 1, 0), userdata = {-4.371,0.999,0,-1}}
		}))
		SideMesh = Mesh(Material("yawd/models/trap_side"))
		local t = {}
		local h = Vector(0,0,0.5)
		local b = Vector(0,0,-10)
		for i = 0, 3 do
			local d = i * 90
			local a = Angle(0,d,0)
			local n = a:Forward()
			local tan = -a:Right()
			for _,t2 in ipairs(Quad({
				{ pos = h + -n * 0.5 + tan *  0.5,     u = 0, v = 0, normal = -n,tangent = tan, userdata = {0.999, 4.37, 0,-1}}, -- LT
				{ pos = h + -n * 0.5 + tan * -0.5,     u = 1, v = 0, normal = -n,tangent = tan, userdata = {0.999, 4.37, 0,-1}}, -- RT
				{ pos =-h + -n * 0.5 + tan * -0.5 + b, u = 1, v = 1, normal = -n,tangent = tan, userdata = {0.999, 4.37, 0,-1}}, -- RB
				{ pos =-h + -n * 0.5 + tan *  0.5 + b, u = 0, v = 1, normal = -n,tangent = tan, userdata = {0.999, 4.37, 0,-1}}  -- LB
				})) do
				table.insert(t, t2)
			end
		end
		SideMesh:BuildFromTriangles(t)
	end
	function ENT:RenderBase(top_texture)
		if not TopMesh or not SideMesh then
			GenerateMesh()
		end
		local mins,maxs = self:OBBMins(), self:OBBMaxs()
		local matr = Matrix()
		matr:SetAngles(self:GetAngles())
		matr:SetTranslation(self:GetPos())
		matr:Scale(maxs - mins)
		cam.PushModelMatrix(matr)
			render.SetMaterial( top_texture or base)
			TopMesh:Draw()
			render.SetMaterial( side)
			SideMesh:Draw()
		cam.PopModelMatrix()
		-- Flashlight support
		local flashLight = LocalPlayer():FlashlightIsOn()
		if flashLight then
			render.PushFlashlightMode( flashLight )
			cam.PushModelMatrix(matr)
				render.SetMaterial( top_texture or base)
				TopMesh:Draw()
				render.SetMaterial( side)
				SideMesh:Draw()
			cam.PopModelMatrix()
			render.PopFlashlightMode()
		end
	end
	local mat_nopower = Material("yawd/no_power.png")
	local col = Color(255,0,0)
	function ENT:Draw()
		if self.b_Draw then
			-- This is a bug in gmod. Shadows won't be made if the model isn't "rendered".
			render.SetBlend(0)
				self:DrawModel()
			render.SetBlend(1)
			self:b_Draw()
		else
			self:DrawModel()
		end
		if self:GetDisabled() then
			render.SetMaterial(mat_nopower)
			local p = math.sin(CurTime() * 5)
			col.a = p * 100 + 150
			local s = 48 + p
			render.DrawSprite(self:GetPos() + Vector(0,0,60), s, s, col)
		end

		local pos = self:GetPos()
		local ply = LocalPlayer()
		local delta = pos - ply:GetShootPos()
		delta:Normalize()

		local dot = ply:GetAimVector():Dot(delta)
		dot = math.deg(math.acos(dot))

		if dot >= 30 or pos:DistToSqr(ply:GetPos()) > 600 * 600 then return end

		local eyeang = ply:EyeAngles()
		eyeang:RotateAroundAxis(eyeang:Right(), 90)
		eyeang:RotateAroundAxis(eyeang:Up(), -90)

		cam.Start3D2D(pos + Vector(0, 0, 90), eyeang, 0.5)
			local hp = self:Health()
			local max_hp = self:GetMaxHealth()

			self.m_HealthLerp = self.m_HealthLerp or PercentLerp(0.5, 0.25, true)

			local bw, bh = 250, 25
			local bx, by = 0, 0

			local _, th = draw.SimpleText(self:GetBuildingName() or "Unknown Building", "HUD.Building", bx, by, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			local y_offset = th + 5

			if max_hp > 0 then
				by = by + y_offset

				surface.SetDrawColor(35, 35, 35, 200)
				surface.DrawRect(bx - bw * 0.5, by, bw, bh)

				local p = math.Clamp(hp / max_hp, 0, 1)
				local lp = self.m_HealthLerp(hp, max_hp)

				local x_offset = bw - bw * lp
				x_offset = x_offset * 0.5

				surface.SetDrawColor(255, 75, 75)
				surface.DrawRect(bx - bw * 0.5 + x_offset, by, bw * lp, bh)

				x_offset = bw - bw * p
				x_offset = x_offset * 0.5

				surface.SetDrawColor(136, 181, 55)
				surface.DrawRect(bx - bw * 0.5 + x_offset, by, bw * p, bh)

				y_offset = y_offset + bh + 5
			end

			if self.TrapTriggerTime >= 0 and self.TrapResetTime >= 0 and self:DurationProcent() > 0 then
				by = by + y_offset

				surface.SetDrawColor(35, 35, 35, 200)
				surface.DrawRect(bx - bw * 0.5, by, bw, bh)

				local n = self:DurationProcent()
				local p = math.Clamp(n, 0, 1)

				local x_offset = bw - bw * p
				x_offset = x_offset * 0.5

				surface.SetDrawColor(121, 0, 185)
				surface.DrawRect(bx - bw * 0.5 + x_offset, by, bw * p, bh)

				y_offset = y_offset + bh + 5
			end
		cam.End3D2D()
	end
	function ENT:OnRemove()
		if self.b_OnRemove then
			self.b_OnRemove(self)
		end
	end
end

function ENT:DurationProcent()
	if not self.i_duration or not self.TrapDurationTime then return 0 end
	return math.max(0, (self.i_duration - CurTime()) / self.TrapDurationTime)
end

function ENT:ResetProcent()
	if not self.i_reset then return 1 end
	local n = (self.TrapResetTime or 0)
	return 1 - (self.i_reset - CurTime()) / n
end

function ENT:GetTrapArea()
	return self.TrapArea[1], self.TrapArea[2]
end

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "BuildingName" )
	self:NetworkVar( "Entity", 0, "BuildingOwner" )
	self:NetworkVar( "Int", 0, "Upgrades" )
	self:NetworkVar( "Bool", 1, "Disabled" )
end

function ENT:Use(ply)
	if not IsValid(ply) then return end
	if self:GetBuildingOwner() ~= ply then return end
	-- Sell trap
	local cost = self:GetBuildingData().Cost or 100
	SafeRemoveEntity(self)
	ply:AddCurrency( cost )
	ply:EmitSound("ambient/levels/labs/coinslot1.wav")
end
