--[[
	! = Internal functins and shouldn't be used.

	Functions:
		SH  Building.GetData( BuildingName )    							Returns the building init-data.
		SH	Building.CanPlayerBuild( ply, BuildingName )					Returns true if the player can build said building.
		SH	Building.GetPlayerBuildings( ply )								Returns a list of buildings the given player made.
		SH	Building.CanPlaceOnFloor(BuildingName, vec, yaw, bAllowWater)	Returns a bool, position and angle.
		SH	Building.CanPlaceOnFloorFast(BuildingName, vec, yaw, bAllowWater)	Returns a bool.
		SH	Building.CanPlaceCore( node )									Returns true if the core can be placed at said node.
		SH	Building.GetCore()												Returns the core building (If placed).
	!	SH	Building.ApplyFunctions( ent )									Applies the building functions to the given building.
		SH	Building.CanTarget( ent )										Returns true if the building can target the entity.
		SV	Building.Create( BuildingName, ply , pos, ang )			Creats a building at the given position and angle.

	Debug Functions:
		SV	Building.RespawnCore()			Respawns the core at the same location.
]]
local building_size = Vector(95, 95, 95)
local cos,sin,rad,max = math.cos, math.sin, math.rad, math.max
Building = {}

local META = FindMetaTable("Entity")
function META:IsBuilding()
	local cl = self:GetClass()
	return cl == "yawd_building" or cl == "yawd_building_core" or cl == "yawd_building_solid"
end

local cores = ents.FindByClass( "yawd_building_core" )
if #cores > 0 then
	GM.Building_Core = cores[1]
else
	GM.Building_Core = NULL
end

local buildings = {}
local building_meta = {}
local default_building = {}
	default_building.Name = "Unknown"
	default_building.Health = 200
	default_building.CanBuild = true
	default_building.BuildClass = CLASS_ANY
	default_building.Cost = 0
	default_building.IsSolid = false
	default_building.BuildingSize = {-Vector(95, 95, 10), Vector(95, 95, 95)}
	default_building.HasFoundation = false
building_meta.__index = default_building
function building_meta:__tostring()
	return 'BuildingData ["' .. self.Name .. '"]'
end

-- Load buildings
hook.Add("YAWDPreLoaded","YAWD_LoadBuildings",function()
	local files,folders = file.Find( GM.FolderName .. "/gamemode/buildings/*.lua" ,"LUA")
	for k,v in ipairs(files) do
		local fil = GM.FolderName .. "/gamemode/buildings/" .. v
		AddCSLuaFile(fil)
		local t = include(fil)
		if not t or type(t) ~= "table" then ErrorNoHalt("Empty building file [" .. fil .. "]") continue end
		if not t.Name then ErrorNoHalt("Invalid building data  [" .. fil .. "]") continue end
		setmetatable(t, building_meta)
		t.max_size = Vector( math.max( -t.BuildingSize[1].x, t.BuildingSize[2].x ), math.max( -t.BuildingSize[1].y, t.BuildingSize[2].y ),math.max( -t.BuildingSize[1].z, t.BuildingSize[2].z ))
		buildings[t.Name] = t
	end
end)

-- Buiilding functions
function Building.GetAll()
	return table.GetKeys(buildings)
end
function Building.GetData( BuildingName )
	return buildings[BuildingName]
end
local cache = {}
local function isClassAllowed( BuildingName, CLASS )
	if CLASS == CLASS_ANY then return true end
	if not cache[BuildingName] then cache[BuildingName] = {} end
	if cache[BuildingName][CLASS] ~= nil then
		return cache[BuildingName][CLASS]
	end
	local bd = Building.GetData( BuildingName )
	if not bd then return false end
	if bd.CanBuild ~= nil and bd.CanBuild == false then return false end
	if type( bd.BuildClass ) == "table" then
		for _,bclass in ipairs( bd.BuildClass ) do
			if bclass == CLASS or bclass == CLASS_ANY then
				cache[BuildingName][CLASS] = true
				return true
			end
		end
	elseif bd.BuildClass == CLASS_ANY or bd.BuildClass == CLASS then
		cache[BuildingName][CLASS] = true
		return true
	end
	cache[BuildingName][CLASS] = false
	return false
end
function Building.CanClassBuild(BuildingName, CLASS)
	return isClassAllowed(BuildingName, CLASS)
end
function Building.CanPlayerBuild( ply, BuildingName )
	local bd = Building.GetData( BuildingName )
	// Check cost
	local cost = bd.Cost
	if cost < 0 then return false end
	if ply:GetCurrency() < cost then return false end
	// Check if class match
	return isClassAllowed( BuildingName, ply:GetPlayerClass() )
end
function Building.GetPlayerBuildings( ply )
	local t = {}
	for _,ent in ipairs( ents.FindByClass( "yawd_building*" ) ) do
		if not ent:IsBuilding() then continue end
		local ow = ent:GetBuildingOwner()
		if IsValid(ow) and ow == ply then
			table.insert(t, ent)
		end
	end
	return t
end

local max_angle = 6

local s_hull = building_size * 0.05
-- A mask that hits the map and water
local custom_mask = bit.bor( CONTENTS_EMPTY, CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_WINDOW, CONTENTS_PLAYERCLIP, CONTENTS_WATER, CONTENTS_GRATE  )
local function ET(vec1, vec2)
	return util.TraceLine( {
		start = vec1,
		endpos = vec2,
		mask = custom_mask
	} )
end
local function ETHull(vec1, vec2, mins, maxs)
	return util.TraceHull( {
		start = vec1,
		endpos = vec2,
		maxs = maxs,
		mins = mins,
		mask = custom_mask
	} )
end
local function CheckForBuilding(vec1, vec2, mins, maxs, ent)
	local t = util.TraceHull( {
		start = vec1,
		endpos = vec2,
		maxs = maxs,
		mins = mins,
		collisiongroup = COLLISION_GROUP_WEAPON, 
		ignoreworld = true,
		filter = ent
	} )
	return t.Hit and t.Entity or nil
end
local function pointFree( vec )
	local content = util.PointContents( vec )
	if bit.band( content, CONTENTS_WATER ) == CONTENTS_WATER or bit.band( content, CONTENTS_SOLID ) == CONTENTS_SOLID then return false end
	return true
end
local function AngleMerge( ang1, ang2, amount)
	return math.ApproachAngle(ang1, ang2, math.AngleDifference(ang1, ang2) * amount) % 360
end
-- Checks to see if a building can be placed. Returns; success, position, angle. Position and angle for rendering.
function Building.CanPlaceOnFloor(BuildingName, vec, yaw, bAllowWater, e_IgnoreEntity, b_StopSnap)
	if not yaw then yaw = 0 end
	local size = buildings[BuildingName].max_size
	-- Change the place location if there is a trap nearby
	local height = Vector(0,0,50 + size.z * 2)
	local m_size = size * 0.95
	local ent = CheckForBuilding(vec + height, vec - height, -m_size, m_size, e_IgnoreEntity)
	if ent and IsValid(ent) then -- We found a trap. Snap to it
		if not ent:IsBuilding() or b_StopSnap then -- This is not a building. Can't snap.
			return false, vec
		end
		local offset = vec - ent:GetPos()
		vec = ent:GetPos()
		if math.abs(offset.x) >= math.abs(offset.y) then -- X
			if offset.x >= 0 then -- +
				vec.x = vec.x + ent:OBBMaxs().x + size.x
			else -- -
				vec.x = vec.x + ent:OBBMins().x - size.x
			end
		else -- Y
			if offset.y >= 0 then -- +
				vec.y = vec.y + ent:OBBMaxs().y + size.y
			else -- -
				vec.y = vec.y + ent:OBBMins().y - size.y
			end
		end
		-- We snapped, check if there is a building (or something else) at new location
		if CheckForBuilding(vec + height, vec - height, -m_size, m_size, e_IgnoreEntity) then
			return false, vec
		end
	end
	local eye = vec + Vector(0,0,50)
	local r = rad(yaw)
	local TLO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
	local r = rad(yaw - 90)
	local TRO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
	-- Check the corners (Anything solid)
	local TR = vec + TLO + TRO + Vector(0,0,10)
	local TL = vec + TLO - TRO + Vector(0,0,10)
	local BL = vec - TLO - TRO + Vector(0,0,10)
	local BR = vec - TLO + TRO + Vector(0,0,10)
	if not pointFree(TR) then return false, vec end
	if not pointFree(TL) then return false, vec end
	if not pointFree(BL) then return false, vec end
	if not pointFree(BR) then return false, vec end
	-- Trace the ground from corners
	local R_TL = ETHull(TL + Vector(0,0,40), TL - Vector(0,0,90), -s_hull, s_hull)
	local R_TR = ETHull(TR + Vector(0,0,40), TR - Vector(0,0,90), -s_hull, s_hull)
	local R_BL = ETHull(BL + Vector(0,0,40), BL - Vector(0,0,90), -s_hull, s_hull)
	local R_BR = ETHull(BR + Vector(0,0,40), BR - Vector(0,0,90), -s_hull, s_hull)
	if not R_TL.Hit or not R_TR.Hit or not R_BL.Hit or not R_BR.Hit then return false, vec end
	-- Lifts the detection a bit
	TL.z = R_TL.HitPos.z + 20
	TR.z = R_TR.HitPos.z + 20
	BL.z = R_BL.HitPos.z + 20
	BR.z = R_BR.HitPos.z + 20
	-- Check from center to corners (Solid)
	local t = ET(TL, TR)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(TR, BR)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(BR, BL)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(BL, TL)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(TL, BR)
	if t.Hit or t.StartSolid then return false, vec end

	local R_Center = ETHull(eye, eye - Vector(0,0,90), -s_hull, s_hull)
	-- Get the position
	local center_z = max(( R_TL.HitPos.z + R_TR.HitPos.z + R_BL.HitPos.z + R_BR.HitPos.z ) / 4, R_Center.HitPos.z)
	-- Calculate the yaw and pitch.
	local p1,p2 =  (R_TL.HitPos - R_TR.HitPos ):Angle().p, (R_BL.HitPos - R_BR.HitPos ):Angle().p
	local Pitch = AngleMerge(p1,p2,0.5)
	local r1,r2 = ( R_TR.HitPos - R_BR.HitPos ):Angle().p, ( R_TL.HitPos - R_BL.HitPos ):Angle().p
	local Roll = AngleMerge(r1,r2,0.5)
	-- Calculate the angle
	local n_ang = Angle(0,yaw,0)
	n_ang:RotateAroundAxis(n_ang:Forward(), -Pitch)
	n_ang:RotateAroundAxis(n_ang:Right(), -Roll)

	local n_pos = Vector(eye.x,eye.y,center_z)
	if math.abs(math.AngleDifference(Pitch,0)) > max_angle then                     return false, n_pos, n_ang end
	if math.abs(math.AngleDifference(Roll,0)) > max_angle then                      return false, n_pos, n_ang end
	if not R_TR.Hit or (not bAllowWater and R_TR.MatType == MAT_SLOSH) then         return false, n_pos, n_ang end
	if not R_TL.Hit or (not bAllowWater and R_TL.MatType == MAT_SLOSH) then         return false, n_pos, n_ang end
	if not R_BL.Hit or (not bAllowWater and R_BL.MatType == MAT_SLOSH) then         return false, n_pos, n_ang end
	if not R_BR.Hit or (not bAllowWater and R_BR.MatType == MAT_SLOSH) then         return false, n_pos, n_ang end
	if not R_Center.Hit or (not bAllowWater and R_Center.MatType == MAT_SLOSH) then return false, n_pos, n_ang end
	return true, n_pos, n_ang
end
-- Checks to see if a building can be placed. However this function is faster and doesn't calculate the angle.
function Building.CanPlaceOnFloorFast(BuildingName, vec, yaw, bAllowWater, e_IgnoreEntity, b_StopSnap)
	if not yaw then yaw = 0 end
	local size = buildings[BuildingName].max_size
	-- Change the place location if there is a trap nearby
	local height = Vector(0,0,50 + size.z * 2)
	local m_size = size * 0.95
	local ent = CheckForBuilding(vec + height, vec - height, -m_size, m_size, e_IgnoreEntity)
	if ent and IsValid(ent) then -- We found a trap. Snap to it
		if not ent:IsBuilding() or b_StopSnap then -- This is not a building. Can't snap.
			return false, vec
		end
		local offset = vec - ent:GetPos()
		vec = ent:GetPos()
		if math.abs(offset.x) >= math.abs(offset.y) then -- X
			if offset.x >= 0 then -- +
				vec.x = vec.x + ent:OBBMaxs().x + size.x
			else -- -
				vec.x = vec.x + ent:OBBMins().x - size.x
			end
		else -- Y
			if offset.y >= 0 then -- +
				vec.y = vec.y + ent:OBBMaxs().y + size.y
			else -- -
				vec.y = vec.y + ent:OBBMins().y - size.y
			end
		end
		-- We snapped, check if there is a building (or something else) at new location
		if CheckForBuilding(vec + height, vec - height, -m_size, m_size, e_IgnoreEntity) then
			return false, vec
		end
	end
	local eye = vec + Vector(0,0,50)
	local r = rad(yaw)
	local TLO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
	local r = rad(yaw - 90)
	local TRO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
	-- Check the corners (Anything solid)
	local TR = vec + TLO + TRO + Vector(0,0,10)
	local TL = vec + TLO - TRO + Vector(0,0,10)
	local BL = vec - TLO - TRO + Vector(0,0,10)
	local BR = vec - TLO + TRO + Vector(0,0,10)
	if not pointFree(TR) then return false, vec end
	if not pointFree(TL) then return false, vec end
	if not pointFree(BL) then return false, vec end
	if not pointFree(BR) then return false, vec end
	-- Trace the ground from corners
	local R_TL = ETHull(TL + Vector(0,0,40), TL - Vector(0,0,90), -s_hull, s_hull)
	local R_TR = ETHull(TR + Vector(0,0,40), TR - Vector(0,0,90), -s_hull, s_hull)
	local R_BL = ETHull(BL + Vector(0,0,40), BL - Vector(0,0,90), -s_hull, s_hull)
	local R_BR = ETHull(BR + Vector(0,0,40), BR - Vector(0,0,90), -s_hull, s_hull)
	if not R_TL.Hit or not R_TR.Hit or not R_BL.Hit or not R_BR.Hit then return false, vec end
	TL.z = R_TL.HitPos.z + 20
	TR.z = R_TR.HitPos.z + 20
	BL.z = R_BL.HitPos.z + 20
	BR.z = R_BR.HitPos.z + 20
	-- Check from center to corners (Solid)
	local t = ET(TL, TR)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(TR, BR)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(BR, BL)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(BL, TL)
	if t.Hit or t.StartSolid then return false, vec end
	local t = ET(TL, BR)
	if t.Hit or t.StartSolid then return false, vec end

	local R_Center = ETHull(eye, eye - Vector(0,0,90), -s_hull, s_hull)
	-- Get the position
	local center_z = max(( R_TL.HitPos.z + R_TR.HitPos.z + R_BL.HitPos.z + R_BR.HitPos.z ) / 4, R_Center.HitPos.z)
	-- Calculate the yaw and pitch.
	local p1,p2 =  (R_TL.HitPos - R_TR.HitPos ):Angle().p, (R_BL.HitPos - R_BR.HitPos ):Angle().p
	local Pitch = AngleMerge(p1,p2,0.5)
	local r1,r2 = ( R_TR.HitPos - R_BR.HitPos ):Angle().p, ( R_TL.HitPos - R_BL.HitPos ):Angle().p
	local Roll = AngleMerge(r1,r2,0.5)
	if math.abs(math.AngleDifference(Pitch,0)) > max_angle then return false end
	if math.abs(math.AngleDifference(Roll,0)) > max_angle then return false end
	return true
end
-- Returns the buildingsize. (This is not the traparea)
function Building.GetSize( BuildingName )
	local bd = Building.GetData( BuildingName )
	if not bd or not bd.BuildingSize then return -Vector(95, 95, 1.7), Vector(95, 95, 95) end
	return bd.BuildingSize
end

local n_c = {}
-- Returns a table of position and angle, if node is valid for the objective.
function Building.CanPlaceCore( node )
	-- Check to see if the node is valid or cached
	if not node then return false end
	if n_c[node] ~= nil then return n_c[node] end
	if not node:IsMapNode() then return false end
	if #node:GetConnectedNodes(nil, nil, NODE_TYPE_GROUND) < 3 then -- Check to see if there are more than 3 nodes connected to this.
		n_c[node] = false
		return false
	end
	if not Building.CanPlaceOnFloorFast("Core", node:GetPos(), 0, false) then
		n_c[node] = false
		return false
	end
	local _,vec,ang = Building.CanPlaceOnFloor("Core", node:GetPos(), 0, false)
	n_c[node] = {vec,ang}
	return n_c[node]
end
-- A debug function to respawn the core.
function Building.RespawnCore()
	local e = Building.GetCore()
	local n = Building.Create( "Core", nil, e:GetPos(), e:GetAngles() )
	SafeRemoveEntity(e)
end
-- Returns the core
function Building.GetCore()
	return gmod.GetGamemode().Building_Core
end
-- Applies the functions
function Building.ApplyFunctions( ent )
	local BuildingName = ent:GetBuildingName()
	if not BuildingName then return end
	local bd = Building.GetData( BuildingName )
	if not bd then return end
	ent.builddata = bd
	for k,v in pairs( bd ) do
		if k == "Init" and type(v) == "function" then
			v(ent)
		elseif k == "Health" and SERVER then
			ent:SetMaxHealth( v )
			ent:SetHealth( v )
		elseif k == "TrapArea" and CLIENT then
			ent:SetRenderBounds( v[1], v[2] )
			ent[k] = v
		elseif k == "Draw" then
			ent.b_Draw = v
		elseif k == "OnRemove" then
			ent.b_OnRemove = v
		elseif not (k == "Think" and ent:GetClass() == "yawd_building_ghost") then
			ent[k] = v
		end
	end
end
-- Checks to see if the entity is an enemy
function Building.CanTarget( ent )
	if ent:Health() <= 0 then return false end
	if ent:IsNPC() or ent:IsNextBot() or ent:GetClass() == "yawd_npc_base" then
		return true
	end
	return false
end

if SERVER then
	-- Used to apply force on targets
	function Building.ApplyTrapForce(target, vec)
		if type(target) == "Player" then
			target:SetVelocity(target:GetVelocity() + Vector(vec.x / 2, vec.y / 2, vec.z))
		else
			if target.GetRagdolled and target:GetRagdolled() then
				return
			end
			if target.Fling and not target.m_CantBePushed then
				target:Fling( vec )
			else
				local phys = target:GetPhysicsObject()
				if IsValid(phys) then
					phys:Wake()
					target:SetVelocity(target:GetVelocity() + Vector(vec.x * 2, vec.y * 2, vec.z) )
				end
			end
		end
	end
	-- Creats a building.
	function Building.Create( BuildingName, owner, pos, ang )
		local bd = Building.GetData( BuildingName )
		if not bd then ErrorNoHalt("Unknown building [" .. BuildingName .. "]") return end
		local c = "yawd_building"
		if BuildingName == "Core" then
			c = "yawd_building_core"
		elseif bd.IsSolid then
			c = "yawd_building_solid"
		end
		local e = ents.Create(c)
		e:SetBuildingName( BuildingName )
		e:SetPos( pos )
		e:SetAngles( ang or Angle(0,0,0))
		e.building_data = bd
		e:SetBuildingOwner( owner )
		Building.ApplyFunctions( e )
		e:Spawn()
		return e
	end
	-- Checks current buildings and disables those that aren't allowed.
	hook.Add("YAWDPlayerSwitchedClass", "Buildings.Disable", function(ply, class)
		for _,ent in ipairs( Building.GetPlayerBuildings( ply ) ) do
			local allowed = isClassAllowed( ent:GetBuildingName() , ply:GetPlayerClass() )
			if ent:GetDisabled() and allowed then
				ent:SetDisabled(false)
			elseif not ent:GetDisabled() and not allowed then
				ent:SetDisabled(true)
			end
		end
	end)
else
	-- Easy StencilCut
	-- Starts the stencil. Anything rendered will determined the area that gets rendered.
	function Building.StencilMask()
		render.ClearStencil();
		render.SetStencilEnable( true );
		render.SetStencilCompareFunction( STENCIL_ALWAYS );
		render.SetStencilPassOperation( STENCIL_REPLACE );
		render.SetStencilFailOperation( STENCIL_KEEP );
		render.SetStencilZFailOperation( STENCIL_KEEP );
		render.SetStencilWriteMask( 1 );
		render.SetStencilTestMask( 1 );
		render.SetStencilReferenceValue( 1 );
	end
	-- Anything rendered after this, will be cut to match the mask.
	function Building.StencilRender()
		render.SetStencilCompareFunction( STENCIL_EQUAL );
		render.ClearBuffersObeyStencil( 0,0,0,0, true );
	end
	-- Ends the stencil.
	function Building.StencilEnd()
		render.SetStencilEnable( false )
	end
end

-- Reload support
for _,ent in ipairs(ents.FindByClass("yawd_building*")) do
	if not ent:IsBuilding() then continue end
	Building.ApplyFunctions( ent )
end
