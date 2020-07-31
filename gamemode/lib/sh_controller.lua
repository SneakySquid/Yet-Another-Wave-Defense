local CONTROLLER = {}
CONTROLLER.__index = CONTROLLER

AccessorFunc(CONTROLLER, "m_Path", "Path")
AccessorFunc(CONTROLLER, "m_Target", "Target")
AccessorFunc(CONTROLLER, "m_PathPoint", "PathPoint")
AccessorFunc(CONTROLLER, "m_JumpRange", "JumpRange")
AccessorFunc(CONTROLLER, "m_LastUpdate", "LastUpdate")

function CONTROLLER:Age()
	return CurTime() - self.m_LastUpdate
end

function CONTROLLER:IsValid()
	return self.m_Path and self.m_PathPoint > 0 and self:Age() <= 30
end

function CONTROLLER:MakeInvalid()
	self.m_Path = nil
end

function CONTROLLER:SetPath(path)
	self:SetPathPoint(#path)
	self:SetLastUpdate(CurTime())

	self.m_Path = path
end

function CONTROLLER:GetGoal()
	if not self:IsValid() then return false end

	if self.m_PathPoint == 1 then
		return self.m_Path[1]
	end

	return self.m_Path[self.m_PathPoint]:GetPos()
end

function CONTROLLER:NextGoal()
	self:SetPathPoint(self.m_PathPoint - 1)

	if self.m_PathPoint == 0 then
		return true
	end

	self:SetLastUpdate(CurTime())

	return false
end

Controller = {}

function Controller.RequestPath(hull, start_pos, target_pos, jump_down, jump_up, fuzzy_amount, bIgnoreTrace)
	hull = hull or HULL_LARGE
	start_pos = start_pos or Vector()
	target_pos = target_pos or (Building.GetCore():GetPos() + Building.GetCore():OBBCenter())
	jump_up = jump_up or 0
	jump_down = jump_down or 0

	return PathFinder.CreateNewPath(
		start_pos, target_pos,
		NODE_TYPE_GROUND,
		nil,
		jump_down, jump_up,
		hull,
		fuzzy_amount,
		bIgnoreTrace
	)
end

function Controller.RequestEntityPath(ent, target_pos, jump_down, jump_up, fuzzy_amount, bIgnoreTrace)
	local hull = ent:GetHULLType()
	return Controller.RequestPath(hull, ent:GetPos() + ent:OBBCenter(), target_pos, jump_down, jump_up, fuzzy_amount, bIgnoreTrace)
end

function Controller.New(target, jump_down, jump_up)
	local controller = setmetatable({}, CONTROLLER)

	controller:SetTarget(target)
	controller:SetLastUpdate(CurTime())
	controller:SetJumpRange({jump_down or 0, jump_up or 0})

	return controller
end

if SERVER then
	-- Handles the spawning of spawners on the map
	local spawners = {} -- holds the locations of spawners.
	local aim_distance = 4000 ^ 2
	-- Finds the furthest node from start_node in the general direction of yaw.
	local function LocateSpawnerNode( start_node, yaw )
		local t = {}
		local sp = start_node:GetPos()
		for _,node in ipairs(PathFinder.GetMapNodes()) do
			local pos = node:GetPos()
			local n_yaw = math.deg(math.atan2( pos.x - sp.x, pos.y - sp.y))
			local diff = 1 + (math.abs(math.AngleDifference(n_yaw, yaw)) / 360)
			local dis = pos:DistToSqr(sp) * diff    // Distance point
			for _,sp in ipairs(spawners) do
				dis = dis + math.max(0, (100000 - sp:DistToSqr(pos) * 1.5))
			end
			table.insert(t, {node, dis})
		end
		table.sort(t, function(a,b) return a[2] < b[2] end)
		local fallback
		for i = 1, #t do
			local next_bigger = i ~= #t
			local dis = t[i][2]
			if next_bigger and dis < aim_distance then  -- Next one might be a better one
				fallback = t[i][1]
				continue 
			end
			return t[i][1]
		end
		return fallback
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
				start = pos + Vector(0,0,60),
				endpos = pos - Vector(0,0,100),
				mask = MASK_PLAYERSOLID_BRUSHONLY
			} )
			local e = ents.Create("yawd_npc_spawner")
			e:SetPos( tr.Hit and (tr.HitPos + tr.HitNormal * 0.03) or pos )
			local a = Angle(0,0,0)
			if tr.Hit then
				a = tr.HitNormal:Angle()
				a:RotateAroundAxis(a:Right(), 90)
				a:RotateAroundAxis(a:Forward(), 180)
			end
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
		core = Building.GetCore()
		return true
	end
	hook.Add("YAWDPathFinderNodesLoaded", "YAWD.SpawnSpawners", Controller.TrySpawnSpawners)
end
