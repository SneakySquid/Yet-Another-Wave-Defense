
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
	end
	if self.TrapArea then
		self:EnableTrigger(self.TrapArea[1], self.TrapArea[2])
	end
	if CLIENT then
		Building.ApplyFunctions( self )
	end
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
	ENT.OnTrap = {}
	function ENT:StartTouch( ent )
		if not Building.CanTarget( ent ) then return end
		self.OnTrap[ent] = true
	end
	function ENT:EndTouch(ent)
		self.OnTrap[ent] = nil
	end
	function ENT:HasEnemiesOn()
		return next( self.OnTrap ) ~= nil
	end
	function ENT:GetEnemiesOn()
		return table.GetKeys( self.OnTrap )
	end
	-- Trap logic
	function ENT:Think()
		-- Check if this trap can trigger
		if not IsValid(self.e_trigger) then return end
		if self.TrapTriggerTime < 0 then return end
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
		-- Check if there are enemies on it
		if not self:HasEnemiesOn() then 
			self.i_triggerpoint = nil
			return
		end
		-- Set the springtime
		if not self.i_triggerpoint then
			self.i_triggerpoint = CurTime() + self.TrapTriggerTime
		elseif self.i_triggerpoint <= CurTime() then -- Trigger the trap
			if not self:HasEnemiesOn() then -- They ran away
				self.i_triggerpoint = nil
				return 
			end
			local t = self:GetEnemiesOn()
			if self:OnTrapTrigger( t ) == false then -- Trap returned false
				self.i_triggerpoint = nil
				return 
			end
			-- Trigger it
			net.Start("yawd.traptrigger")
				net.WriteEntity(self)
				net.WriteInt(#t, 32)
				for i = 1, #t do
					net.WriteEntity( t[i] )
				end
			net.Broadcast()
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