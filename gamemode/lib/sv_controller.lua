
--[[ Controls the PATHs and NPC directions
	Controller.CreatePathController( ent, ent_spawner, HULL, nJumpDown, nJumpUp )		Returns an npc_path object. Will generate its own path if given nJumpDown or nJumpUp.

	Controller obj:
		:IsValidPath()		Returns true if the path is valid.
		:NewPath()			Returns true if generated a new path.
		:GetCursor()		Returns the current goal.
		:NextCursor()		Returns the next goal. False if reached the end.	
		:GetCursorAge()		Returns the age of the current Cursor.
--]]


Controller = {}
local meta_npc = {}
local paths = {}
local function RequestPath( self, ent_spawner, HULL )
	HULL = HULL or PathFinder.FindEntityHULL( self )
	if ent_spawner and paths[ent_spawner] and paths[ent_spawner][HULL] then
		return paths[ent_spawner][HULL]
	end
	return PathFinder.CreateNewPath(ent_spawner:GetPos() + Vector(0,0,60), core:GetPos() + Vector(0,0,60), NODE_TYPE_GROUND, nil, 0, 0, HULL)
end

function Controller.CreatePathController( ent, ent_spawner, HULL, nJumpDown, nJumpUp )
	HULL = HULL or PathFinder.FindEntityHULL( self )
	local t = {}
	setmetatable(t, meta_npc)
	if not (nJumpDown and nJumpDown > 0) and not (nJumpUp and nJumpUp > 0) then
		t.path = RequestPath( ent, ent_spawner, HULL )
	else
		t.path = PathFinder.CreateNewPath(self.ent:GetPos() + self.ent:OBBCenter(), core:GetPos() + Vector(0,0,60), NODE_TYPE_GROUND, nil, nJumpDown, nJumpUp, HULL)
	end
	if t.path then
		t.pathpoint = #self.path
	else
		t.pathpoint = -1
	end
	t.ent = ent
	t.HULL = HULL
	t.age = CurTime()
	return t
end

-- Meta
-- Returns true if the path is valid
function meta_npc:IsValidPath()
	return self.path and true
end
-- Returns true if generated new path
function meta_npc:NewPath()
	self.path = PathFinder.CreateNewPath(self.ent:GetPos() + self.ent:OBBCenter(), core:GetPos() + Vector(0,0,60), NODE_TYPE_GROUND, nil, 0, 0, HULL)
	if self.path then
		self.pathpoint = #self.path
		self.age = CurTime()
	end
	return self.path and true
end

function meta_npc:GetCursor()
	if not self.path or self.pathpoint < 1 then 	-- Invalid path
		return self.ent:GetPos()
	elseif self.pathpoint == 1 then 				-- Last point is a vector
		return self.path[1]
	else											-- Return the node position
		local node = self.path[self.pathpoint]
		return node:GetPos()
	end
end

function meta_npc:NextCursor()
	self.pathpoint = self.pathpoint - 1
	if self.pathpoint < 1 then
		self.path = false
		return false
	end
	self.age = CurTime()
	return true
end

function meta_npc:GetCursorAge()
	return CurTime() - self.age
end



-- Handles the spawning of spawners on the map
local spawners = {} -- holds the locations of spawners.
-- Finds the furthest node from start_node in the general direction of yaw.
local function LocateSpawnerNode( start_node, yaw )
	local t = {}
	local sp = start_node:GetPos()
	for _,node in ipairs(PathFinder.GetMapNodes()) do
		local pos = node:GetPos()
		local n_yaw = math.deg(math.atan2( pos.x - sp.x, pos.y - sp.y))
		local diff = ( 180 - math.abs(math.AngleDifference(n_yaw, yaw)) ) / 180
		local dis = pos:DistToSqr(sp) * diff    // Distance point
		for _,sp in ipairs(spawners) do
			dis = math.min(dis, sp:DistToSqr(pos) * 1.5 )
		end
		table.insert(t, {node, dis})
	end
	table.sort(t, function(a,b) return a[2] > b[2] end)
	return t[1][1]
end
local function AddPath(ent_spawner)
	local core = Building.GetCore()
	local path = PathFinder.CreateNewPath(ent_spawner:GetPos() + Vector(0,0,60), core:GetPos() + Vector(0,0,60), NODE_TYPE_GROUND, nil, 0, 0, HULL)
	if not path then return end
	table.remove(path, 1) -- Remove the first point as it is a vector
	if not paths[ent_spawner] then paths[ent_spawner] = {} end
	paths[ent_spawner][HULL] = path
	return true
end
-- Locates and (re)spawns all spawners on the map
local function SpawnSpawners()
	-- Remove any old spawners
	for _,ent in ipairs(ents.FindByClass("yawd_npc_spawner")) do
		SafeRemoveEntity(ent)
	end
	-- Place new spawners
	local core = Building.GetCore()
	local c_node = PathFinder.FindClosestNode( core:GetPos(), NODE_TYPE_GROUND )
	if not c_node then return false end -- No node?
	spawners = {}
	local paths = PRNG.Random(2, 3)
	for i = 1, paths do
		local yaw = PRNG.Random(360)
		local node = LocateSpawnerNode( c_node, yaw )
		local pos = node:GetPos()
		table.insert(spawners, pos)
		-- Spawn entity
		local tr = util.TraceLine( {
			start = pos + Vector(0,0,50),
			endpos = pos - Vector(0,0,50),
			mask = MASK_PLAYERSOLID_BRUSHONLY
		} )
		local e = ents.Create("yawd_npc_spawner")
		e:SetPos( tr.Hit and (tr.HitPos + tr.HitNormal * 0.03) or pos )
		local a = tr.Hit and tr.HitNormal:Angle() or Angle(0,0,0)
		a:RotateAroundAxis(Vector(0,1,0), 90)
		e:SetAngles(a)
		e:Spawn()
	end
end
-- Check to see if we can spawn spawners. (This gets called by the [Ent Core]:Init too)
local spawned = false
function Controller.TrySpawnSpawners()
	if spawned then return end
	-- Check to see if the nodes have been scanned.
	if not PathFinder.HasScannedMapNodes() then return false end
	-- Check to see if the map has a core.
	if not IsValid(Building.GetCore()) then return false end
	SpawnSpawners()
	spawned = true
	return true
end
hook.Add("Nodes.Loaded", "YAWD.SpawnSpawners", Controller.TrySpawnSpawners)