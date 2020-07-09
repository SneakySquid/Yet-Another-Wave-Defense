
local building_size = Vector(95, 95, 1.7)
local cos,sin,rad,max = math.cos, math.sin, math.rad, math.max
Building = {}
local buildings = {}
local building_meta = {}
local default_building = {}
    default_building.Name = "Unknown"
    default_building.Health = 200
    default_building.CanBuild = false
    default_building.BuildClass = CLASS_ANY
    default_building.Cost = 0
    default_building.IsSolid = false
    default_building.BuildingSize = {-Vector(95, 95, 10), Vector(95, 95, 95)}
    default_building.HasFoundation = false
building_meta.__index = default_building
function building_meta:__tostring()
    return 'BuildingData ["' .. self.Name .. '"]'
end

// Load buildings
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
// Buiilding functions
function Building.GetData( BuildingName )
    return buildings[BuildingName] 
end
function Building.CanPlayerBuild( ply, BuildingName )
    local bd = Building.GetData( BuildingName )
    // Check if valid
    if not bd then return false end
    if not bd.CanBuild and bd.CanBuild ~= nil then return false end
    // Check cost
    local cost = bd.Cost
    if cost < 0 then return false end
    if ply:GetCurrency() < cost then return false end
    // Check if team match
    if bd.BuildClass ~= CLASS_ANY then
        local team_name = GM.PlayerClasses[bd.BuildClass]
        if player_manager.GetPlayerClass(ply) ~= team_name then return false end
    end
    return true
end
function Building.GetSize( BuildingName )
    return Building.GetData( BuildingName ).BuildingSize
end

local max_angle = 6

local s_hull = building_size * 0.05
-- A mask that hits the map and water
local custom_mask = bit.bor( CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_WINDOW, CONTENTS_PLAYERCLIP, CONTENTS_GRATE, CONTENTS_WATER )
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
local function pointFree( vec )
    local content = util.PointContents( vec )
    if bit.band( content, CONTENTS_WATER ) == CONTENTS_WATER or bit.band( content, CONTENTS_SOLID ) == CONTENTS_SOLID then return false end
    return true
end
local function AngleMerge( ang1, ang2, amount)
    return math.ApproachAngle(ang1, ang2, math.AngleDifference(ang1, ang2) * amount) % 360
end
-- Checks to see if a building can be placed. Returns; success, position, angle. Position and angle for rendering.
function Building.CanPlaceOnFloor(BuildingName, vec, yaw, bAllowWater)
    if not yaw then yaw = 0 end
    local size = buildings[BuildingName].max_size
    local eye = vec + Vector(0,0,50)
    local r = rad(yaw)
    local TLO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
    local r = rad(yaw - 90)
    local TRO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
    -- Check the corners
    local TR = eye + TLO + TRO
    if not pointFree(TR) then return false, vec, Angle(0,yaw,0) end
    local TL = eye + TLO - TRO
    if not pointFree(TL) then return false, vec, Angle(0,yaw,0) end
    local BL = eye - TLO - TRO
    if not pointFree(BL) then return false, vec, Angle(0,yaw,0) end
    local BR = eye - TLO + TRO
    if not pointFree(BR) then return false, vec, Angle(0,yaw,0) end
    -- Check from center to corners
    if ET(TL, TR).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(TR, BR).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(BR, BL).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(BL, TL).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(TL, BR).Hit then return false, vec, Angle(0,yaw,0) end
    -- Trace the ground from corners
    local R_TL = ETHull(TL, TL - Vector(0,0,90), -s_hull, s_hull)
    local R_TR = ETHull(TR, TR - Vector(0,0,90), -s_hull, s_hull)
    local R_BL = ETHull(BL, BL - Vector(0,0,90), -s_hull, s_hull)
    local R_BR = ETHull(BR, BR - Vector(0,0,90), -s_hull, s_hull)
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
function Building.CanPlaceOnFloorFast(BuildingName, vec, yaw, bAllowWater)
    if not yaw then yaw = 0 end
    local size = buildings[BuildingName].max_size
    local eye = vec + Vector(0,0,50)
    local r = rad(yaw)
    local TLO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
    local r = rad(yaw - 90)
    local TRO = Vector( cos(r) * size.x, sin(r) * size.y, 0 ) * 0.95
    -- Check the corners
    local TR = eye + TLO + TRO
    if not pointFree(TR) then return false end
    local TL = eye + TLO - TRO
    if not pointFree(TL) then return false end
    local BL = eye - TLO - TRO
    if not pointFree(BL) then return false end
    local BR = eye - TLO + TRO
    if not pointFree(BR) then return false end
    -- Check from center to corners
    if ET(TL, TR).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(TR, BR).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(BR, BL).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(BL, TL).Hit then return false, vec, Angle(0,yaw,0) end
    if ET(TL, BR).Hit then return false, vec, Angle(0,yaw,0) end
    -- Trace the ground from corners
    local R_TL = ETHull(TL, TL - Vector(0,0,90), -s_hull, s_hull)
    if not R_TL.Hit or R_TL.MatType == MAT_SLOSH then return false, n_pos, n_ang end
    local R_TR = ETHull(TR, TR - Vector(0,0,90), -s_hull, s_hull)
    if not R_TR.Hit or (not bAllowWater and R_TR.MatType == MAT_SLOSH) then         return false, n_pos, n_ang end
    local R_BL = ETHull(BL, BL - Vector(0,0,90), -s_hull, s_hull)
    if not R_BL.Hit or (not bAllowWater and R_BL.MatType == MAT_SLOSH) then         return false, n_pos, n_ang end
    local R_BR = ETHull(BR, BR - Vector(0,0,90), -s_hull, s_hull)
    if not R_BR.Hit or (not bAllowWater and R_BR.MatType == MAT_SLOSH) then         return false, n_pos, n_ang end
    local R_Center = ETHull(eye, eye - Vector(0,0,90), -s_hull, s_hull)
    if not R_Center.Hit or (not bAllowWater and R_Center.MatType == MAT_SLOSH) then return false, n_pos, n_ang end
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
--local function CanPlaceAt(vec, )

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
-- Returns the core
function Building.GetCore()
    return gmod.GetGamemode().Building_Core
end

if SERVER then
    function Building.CreateBuilding( BuildingName, owner, pos, ang )
        local bd = Building.GetData( BuildingName )
        if not bd then ErrorNoHalt("Unknown building [" .. BuildingName .. "]") return end
        local c = "yawd_building"
        if BuildingName == "Core" then
            c = "yawd_building_core"
        elseif bd.IsSolid then
            c = "yawd_building_solid"
        end
        local e = ents.Create(c)
        e:SetNWString("building_name", BuildingName)
        e:SetPos( pos )
        e:SetAngles(ang)
        e.building_data = bd
        e.building_owner = owner
        e:Spawn()
        return e
    end
end