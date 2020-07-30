AddCSLuaFile()

if CLIENT then
   SWEP.PrintName          = "Building Wep"
   SWEP.Slot               = 1

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 54

   SWEP.Icon               = "vgui/ttt/icon_glock"
   SWEP.IconLetter         = "c"
end

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.ShootSound = Sound( "NPC_CScanner.TakePhoto" )

SWEP.UseHands              = true
SWEP.ViewModel = 			"models/weapons/c_357.mdl"
SWEP.WorldModel            = "models/weapons/w_pist_glock18.mdl"

function SWEP:Initialize()
	self:SetHoldType( "magic" )
end

if SERVER then
	util.AddNetworkString("yawd_building_placment")
	net.Receive("yawd_building_placment", function(len,ply)
		-- Check for weapon
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "wep_build" then return end
		local building = net.ReadString()
		local Rotate = net.ReadUInt(3)
		-- Do we have the coins?
		local bd = Building.GetData( building )
		if not bd then return end -- Not a building
		if not Building.CanPlayerBuild( ply, building ) then return end -- You can't build that
		-- Get placment
		local pos = ply:GetEyeTrace().HitPos
		local shift = net.ReadBool()
		local succ, pos, ang = Building.CanPlaceOnFloor(building, pos, Rotate * 90, bAllowWater)
		if not succ then return end -- You can't place it there
		local b = Building.Create( building, ply , pos, ang )
		if b then
			b:EmitSound("ambient/machines/thumper_startup1.wav")
		end
		ply:SetCurrency(ply:GetCurrency() - (bd.Cost or 100))
	end)
else
	function SWEP:SetBuilding(str)
		self.Building = str
		if IsValid(self.GhostEntity) then
			self.GhostEntity:SetBuildingName( self:GetBuilding() )
			self.GhostEntity.DrawSelection = nil
			Building.ApplyFunctions( self.GhostEntity )
		end
	end
	function SWEP:GetBuilding()
		return self.Building
	end
	local base = Material("yawd/models/trap_base")
	local side = Material("yawd/models/trap_side")
	local TopMesh
	local SideMesh
	local Rotate = 0
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
	function SWEP:RemoveGhost()
		if self.GhostEntity then
			SafeRemoveEntity(self.GhostEntity)
		end
		self.GhostEntity = nil
	end
	function SWEP:MakeGhost()
		if not IsValid(self.GhostEntity) then
			local ent = ents.CreateClientside( "yawd_building_ghost")
			if self:GetBuilding() then
				ent:SetBuildingName( self:GetBuilding() )
				Building.ApplyFunctions(ent)
			end
			ent:Spawn()
			self.GhostEntity = ent
		end
	end
	function SWEP:Deploy()		self:MakeGhost() return end
	function SWEP:Holster()		self:RemoveGhost() return end
	function SWEP:OnRemove()	self:RemoveGhost() return end
	local m_Reload = false
	function SWEP:Think()
		self:MakeGhost()
		local b = LocalPlayer():KeyDown( IN_RELOAD ) or LocalPlayer():KeyDown( IN_ATTACK2 )
		if m_Reload~=b then
			m_Reload = b
			if m_Reload then
				Rotate = (Rotate + 1) % 4
				self:EmitSound("garrysmod/ui_click.wav")
			end
		end
	end
	local mat_invalid = Material("effects/select_dot")
	function SWEP:DrawBuilding()
		local bldData = Building.GetData( self:GetBuilding() )
		if not bldData then return end -- Invaliod building
		local ow = self:GetOwner()
		local tr = ow:GetEyeTrace()
		local pos = tr.HitPos
		local succ, pos, ang = Building.CanPlaceOnFloor(self:GetBuilding(), pos, Rotate * 90, bAllowWater, self.GhostEntity, input.IsShiftDown())
		if not succ then
			if IsValid(self.GhostEntity) then
				self.GhostEntity:SetNoDraw(true)
			end
			render.SetMaterial(mat_invalid)
			render.DrawSprite(pos, 20,20, Color(255,0,0))
		else
			local ghost = self.GhostEntity
			if IsValid(ghost) then
				ghost:SetNoDraw(false)
				ghost:SetPos(pos)
				ghost:SetAngles(ang)
			end
		end
	end
	function SWEP:DrawWorldModel()
	end
	function SWEP:CalcViewModelView( vm, oldPos, oldAng, pos, ang )
		return pos + Vector(0,0,0), ang
	end
	function SWEP:PreDrawViewModel()
		render.SetBlend(0)
	end
	function SWEP:ViewModelDrawn()
		render.SetBlend(1)
	end
	function SWEP:PostDrawViewModel()
		render.SetBlend(1)
		self:DrawBuilding()
	end
	local n_timer = 0
	function SWEP:PrimaryAttack()
		if n_timer > CurTime() then return end
		n_timer = CurTime() + 1
		-- Do we have the coins and class match?
		if not Building.CanPlayerBuild( LocalPlayer(), self:GetBuilding() ) then 
			self:EmitSound("buttons/button8.wav")
			return 
		end
		-- Make sure we can place the building first
		local pos = LocalPlayer():GetEyeTrace().HitPos
		local succ, pos, ang = Building.CanPlaceOnFloorFast(self:GetBuilding(), pos, 0, bAllowWater, self.GhostEntity, input.IsShiftDown())
		if not succ then 
			return 
		end
		-- Tell the server we want to place it
		net.Start("yawd_building_placment")
			net.WriteString(self:GetBuilding())
			net.WriteUInt(Rotate, 3)
			net.WriteBool(input.IsShiftDown())
		net.SendToServer()
	end
	local n2_timer = 0
	function SWEP:SecondaryAttack()
	end
	
end