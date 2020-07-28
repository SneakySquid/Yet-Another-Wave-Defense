
local floor = math.floor

-- AIN files: https://developer.valvesoftware.com/wiki/AIN
local version = 0
local map_version = 0
local nodes = {}
local links = {}
local lookup = {}
PathFinder = {}

--[[ Description
	PathFinder.CreateNewPath(v_From, v_To, NODE_TYPE,  max_distance, max_jump, max_jumpdown, HULL) 	Returns a pathobject. Returns false if not found a path.
	PathFinder.FindClosestNode( vec, NODE_TYPE, bIgnoreTrace )										Returns nearest nodeobject.
	PathFinder.GetNodes( NODE_TYPE = NODE_TYPE_ANY ) Returns table of found nodes and count.
	PathFinder.GetNode( id ) 		Returns the given node by id.
	PathFinder.HasScannedMapNodes() Returns true if we have scanned the map for "map nodes".
	Pathfinder.GetMapNodes() 		Returns a table of nodes connected with a playerspawn.
	PathFinder.FindHULL(radius, tall)	Returns a HULL that fits the arguments.
	PathFinder.FindEntityHULL( ent )	Returns a hull that fits the entity.
	PathFinder.GetHULLs()				Returns all valid hulls.

	PathObjects:
		:IsValid() 					If the goal is an entity, will check to see if it is valid.
		:GetGoal() 					Returns the goal. (Vector or Entity)
		:IsFollowingEntity() 		Returns true if goal is an entity.
		:GetPosition( num_joint )	Returns a position on the path. Paths start at max and ends at 1.
		:GetPositions() 			Returns the number of positions on the path.
		:FindClosestPosition( vec )	Returns the closest position-number to the given position.
		:DebugOverlay(lifetime)		Renders the path using DebugOverlay.
		:GetDistance()				Returns the distance for the path.

	NodeObjects:
		:GetPos() 		Returns the position of the node.
		:GetType() 		Returns the type of the node.
		:GetInfo() 		Returns the nodeinfo.
		:GetZone() 		Returns the nodezone.
		:GetConnectedNodes( max_jump, max_jumpdown, HULL ) 	Returns a list of valid nodes
		:GetID() 		Returns the node-id.
		:IsMapNode() 	Returns true if it is connected with the playerspawn. (Walkable connections)
		:IsNearSpawn() 	Returns true if this node is closest to a playerspawn.
		:<A few path-related functions>

	Hooks:
		YAWDPathFinderNodesLoaded 		Called when the script has scanned the map for nodes, connecting with the player-spawns.
]]

--------------- TODO :: Check MVM map spawn ---------------
--------------- TODO :: Some maps might have crazy nodes --
--------------- TODO :: Spawnpoints don't get networked ---

NODE_TYPE_INVALID = -1
NODE_TYPE_ANY = 0 		-- Used to specify any type of node (for search)
NODE_TYPE_DELETED = 1 	-- Used in wc_edit mode to remove nodes during runtime
NODE_TYPE_GROUND = 2
NODE_TYPE_AIR = 3
NODE_TYPE_CLIMB = 4
NODE_TYPE_WATER = 5

--[[ Hulls
HULL_HUMAN 			= 0		30w, 73t
HULL_SMALL_CENTERED = 1		40w, 40t
HULL_WIDE_HUMAN		= 2		?
HULL_TINY			= 3		24w, 24t
HULL_WIDE_SHORT		= 4		?
HULL_MEDIUM			= 5		36w, 65t
HULL_TINY_CENTERED	= 6		16w, 8t
HULL_LARGE			= 7		80w, 100t
HULL_LARGE_CENTERED = 8		?
HULL_MEDIUM_TALL	= 9		36w, 100t
]]
function PathFinder.GetHULLs()
	return {HULL_TINY_CENTERED, HULL_TINY, HULL_SMALL_CENTERED, HULL_MEDIUM, HULL_HUMAN, HULL_MEDIUM_TALL, HULL_LARGE}
end
function PathFinder.FindHULL(wide, tall)
	if wide <= 16 and tall <= 8 then
		return HULL_TINY_CENTERED
	elseif wide <= 24 and tall <= 24 then
		return HULL_TINY
	elseif wide <= 40 and tall <= 40 then
		return HULL_SMALL_CENTERED
	elseif wide <= 36 and tall <= 65 then
		return HULL_MEDIUM
	elseif wide <= 32 and tall <= 73 then
		return HULL_HUMAN
	elseif wide <= 36 and tall <= 100 then
		return HULL_MEDIUM_TALL
	else
		return HULL_LARGE
	end
end
function PathFinder.FindEntityHULL( ent )
	local s = ent:OBBMaxs() - ent:OBBMins()
	return PathFinder.FindHULL(math.max(s.x, s.y) / 2, s.z)
end

local scanned = false -- Will be true after the map got scanned

-- Node meta
local node_meta = {}
node_meta.__index = node_meta
function node_meta:GetPos()
	return self.pos
end
function node_meta:GetType()
	return self.nodeType
end
function node_meta:GetInfo()
	return self.nodeInfo
end
function node_meta:GetZone()
	return self.zone
end
function node_meta:GetConnectedNodes( max_jump, max_jumpdown, HULL )
	if not HULL then HULL = 1 end
	if not max_jumpdown then max_jumpdown = 0 end
	if not max_jump then max_jump = 0 end
	local t = {}
	for k, v in ipairs(links[self] or {}) do
		local deltaheight = v[2][HULL + 1]
		if deltaheight == -1 then -- Invalid
			continue
		elseif deltaheight == 0 then -- Walk
			table.insert(t, v[1])
		else -- Jump down or up
			if deltaheight > 0 and deltaheight < max_jump then -- Jump
				table.insert(t, v[1])
			elseif deltaheight < 0 and deltaheight > max_jumpdown then --Jumpdown
				table.insert(t, v[1])
			end
		end
	end
	return t
end
function node_meta:GetID()
	return self.id or -1
end
function node_meta:__tostring()
	return "Node [" .. self:GetID() .. "]"
end
function node_meta:IsNodeType( node_type )
	if self.nodeType <= NODE_TYPE_INVALID or self.nodeType > NODE_TYPE_WATER then return false end
	if node_type == NODE_TYPE_ANY then return true end
	return self.nodeType == node_type
end
local cache = {}
-- Returns the higest hull for the given node.
function node_meta:GetHigestHull()
	if cache[self] then return cache[self] end
	local n = 1
	local t = 1 -- We need two nodes with the higest number
	for k, v in ipairs(links[self] or {}) do
		local l_n = 1
		for i = 1, 10 do
			if v[2][i] ~= 0 then break end
			l_n = i
		end
		if t > n and l_n >= t then
			n = t
		end
		t = math.max(t,l_n) -- Set the current temp
	end
	cache[self] = n
	return n
end
-- Node_meta path
local close_list = {}
	function node_meta:AddToClosedList()
		close_list[self] = true
	end
	function node_meta:IsClosed()
		return close_list[self] and true or false
	end
	function node_meta:RemoveFromClosedList()
		close_list[self] = nil
	end
local open_list = {}
	function node_meta:AddToOpenList()
		table.insert(open_list, {self,self:GetTotalCost()})
	end
	function node_meta:IsOpen()
		for _, node in ipairs( open_list ) do
			if node[1] == self then return true end
		end
		return false
	end
	function node_meta:IsOpenListEmpty()
		return next(open_list) == nil
	end
	function node_meta:UpdateOnOpenList()
		table.sort( open_list, function(a, b) return a[2] < b[2] end )
	end
	function node_meta:PopOpenList()
		return table.remove(open_list, 1)[1]
	end
local cost_list = {}
	function node_meta:SetCostSoFar( int )
		cost_list[self] = int
	end
	function node_meta:GetCostSoFar() return cost_list[self] end
local total_cost_list = {}
	function node_meta:SetTotalCost(int)
		total_cost_list[self] = int
	end
	function node_meta:GetTotalCost()
		return total_cost_list[self]
	end



local valid_mapnodes = {}
function node_meta:ClearSearchLists()
	open_list = {}
	close_list = {}
end

-- Gird table This will make it cheaper to lookup nodes
local gridSize = 600
local Grid = {}
local function AddToGrid(x,y,node)
	if not Grid[x] 		then Grid[x] = {} end
	if not Grid[x][y] 	then Grid[x][y] = {} end
	table.insert(Grid[x][y], node)
end
local function AddNodeToGrid(node)
	local p = node:GetPos()
	local x = floor(p.x / gridSize)
	local y = floor(p.y / gridSize)
	AddToGrid(x,y,node)

	-- Locate nearest grid. Add this node in case it is bordering the nother grid.
	local xf = (p.x / gridSize) - x
	local yf = (p.y / gridSize) - y
	if xf < 0.25 then
		xf = -1
	elseif xf > 0.75 then
		xf = 1
	else
		xf = 0
	end
	if yf < 0.25 then
		yf = -1
	elseif yf > 0.75 then
		yf = 1
	else
		yf = 0
	end
	if xf == 0 and yf == 0 then return end -- In the center. No near grid.
	AddToGrid(x + xf,y + yf,node)
	if xf != 0 and yf != 0 then -- Corner, need to add two other places too
		AddToGrid(x + xf,y,node)
		AddToGrid(x,y + yf,node)
	end
end
local function GetNodesFromGrid(vec)
	local x = floor(vec.x / gridSize)
	local y = floor(vec.y / gridSize)
	return Grid[x][y]
end
local TraceLine = util.TraceLine
local function ET(vec1, vec2)
	return TraceLine( {
		start = vec1,
		endpos = vec2,
		mask = MASK_PLAYERSOLID_BRUSHONLY
	} )
end
local function FindClosestNode(vec, NODE_TYPE, bIgnoreTrace)
	-- Search the nodes in the nearest grid.
	local g_nodes = GetNodesFromGrid(vec)
	if g_nodes and #g_nodes > 0 then
		local d,c = -1
		for k, v in ipairs( g_nodes ) do
			if not v:IsNodeType(NODE_TYPE) then continue end
			local dis = vec:Distance(v:GetPos())
			if not bIgnoreTrace and ET(vec, v:GetPos() + Vector(0,0,30) ).Hit then
				continue
			end
			if d < 0 or dis < d then
				d = dis
				c = v
			end
		end
		return c
	end
	-- We're outside the grid. This is going to be expensive.
	-- Search all nodes and return the closest result.
	local d,c = -1
	for k, v in ipairs( nodes ) do
		if not v:IsNodeType(NODE_TYPE) then continue end
		local dis = vec:Distance(v:GetPos())
		if d < 0 or dis < d then
			d = dis
			c = v
		end
	end
	return c
end

-- Load the ain file
local function unsigned(n)
	if n >= 2^31 then
		return n - 2^32
	end
	return n
end
local function ReadNode(f)
	local n = {}
	n.pos = Vector( f:ReadFloat(),f:ReadFloat(),f:ReadFloat()) 	-- Vector
	n.yaw = f:ReadFloat()										-- Float
	n.flOffsets = {}
	for i = 1, (NUM_HULLS or 10) do
		n.flOffsets[i] = f:ReadFloat()							-- Float
	end
	n.nodeType = f:ReadByte() 									-- Byte
	n.nodeInfo = unsigned(f:ReadShort())						-- UShort
	n.zone = f:ReadShort()										-- Short
	setmetatable(n, node_meta)
	-- Mark invalid nodes
	if n.nodeType > NODE_TYPE_WATER or n.nodeType <= NODE_TYPE_ANY then -- NODE_TYPE_ANY too
		n.nodeType = NODE_TYPE_INVALID
	elseif n.nodeType == NODE_TYPE_DELETED then -- Well it should had been deleted, but NPC's use it anyway.
		n.nodeType = NODE_TYPE_GROUND
	end
	-- Trace down
	if n.nodeType == NODE_TYPE_GROUND then
		local t = ET( n.pos + Vector(0,0,30), n.pos - Vector(0,0,30) )
		if t.HitPos then
			n.pos = t.HitPos
		end
	end
	return n
end
local function ReadLink(f)
	local l = {}
	local srcId = f:ReadShort() + 1 		-- Short
	local destId = f:ReadShort() + 1		-- Short
	l.node1 = nodes[srcId]
	l.node2 = nodes[destId]
	l.node1moves = {}
	l.node2moves = {}
	for i = 1, (NUM_HULLS or 10) do
		local n = f:ReadByte() 	-- Byte
		if n == 0 then -- Invalid
			l.node1moves[i] = -1
			l.node2moves[i] = -1
		elseif n == 1 then 		-- Walkable
			l.node1moves[i] = 0
			l.node2moves[i] = 0
		else -- Jump up or down
			local delta = l.node1:GetPos().z - l.node2:GetPos().z
			if delta == -1 then delta = -1.1 end -- We already use -1
			l.node1moves[i] = -delta
			l.node2moves[i] = delta
		end
	end
	return l
end
local function LoadAin()
	if not file.Exists("maps/graphs/" .. game.GetMap() .. ".ain", "GAME") then return false end
	local f = file.Open( "maps/graphs/" .. game.GetMap() .. ".ain", "rb", "GAME" )
	-- Clear
	nodes = {}
	links = {}
	lookup = {}
	-- Header
	version = f:ReadLong()
	map_version = f:ReadLong()
	if version ~= 37 then return false end
	-- Number of nodes
	local num = f:ReadLong()
	-- Nodes
	for i = 1,num do
		nodes[i] = ReadNode(f)
		nodes[i].id = i
		AddNodeToGrid(nodes[i])
	end
	-- Number of links
	local num_link = f:ReadLong()
	-- Links
	for i = 1,num_link do
		local link = ReadLink(f)
		local node = link.node1
		local node2 = link.node2
		if not links[node] then links[node] = {} end
		if not links[node2] then links[node2] = {} end
		table.insert(links[node], {node2,link.node1moves})
		table.insert(links[node2], {node,link.node2moves})
	end
	-- lookup
	for i = 1, num do
		lookup[i] = f:ReadLong()
	end
	f:Close()
	DebugMessage(string.format("AIN loaded. %i nodes. %i links.", #nodes, num_link))
end
-- Pathfinder.
local function heuristic_cost_estimate( start, goal )
	// Perhaps play with some calculations on which corner is closest/farthest or whatever
	return start:GetPos():Distance( goal:GetPos() )
end
local function reconstruct_path( cameFrom, current, reached_limit )
	local total_path = { current }
	current = current:GetID()
	while ( cameFrom[ current ] ) do
		current = cameFrom[ current ]
		table.insert( total_path, nodes[current] )
	end
	total_path.reached_limit = reached_limit or false
	return total_path
end
-- Pathfinmds and returns true if we're at goal. Will returns a uncomplete path if given a max_distance.
local function PathFind(node_start, node_goal, NODE_TYPE,  max_distance, max_jump, max_jumpdown, HULL)
	if not node_start or not node_goal then return false end -- Invalid
	if node_start == node_goal then return true end	-- We're already there

	node_start:ClearSearchLists()
	node_start:AddToOpenList()
	local came_from = {}
	node_start:SetCostSoFar(0)
	node_start:SetTotalCost(heuristic_cost_estimate( node_start, node_goal ))
	node_start:UpdateOnOpenList()

	for i = 1,#nodes do -- Loop
		if node_start:IsOpenListEmpty() then return false end -- No path to point
		local current = node_start:PopOpenList()
		if current == node_goal then
			return reconstruct_path( came_from, current )
		elseif max_distance and current:GetCostSoFar() >= max_distance then
			return reconstruct_path( came_from, current, true )
		end
		current:AddToClosedList()

		for k, neighbor in pairs( current:GetConnectedNodes(max_jump, max_jumpdown, HULL) ) do
			local newCostSoFar = current:GetCostSoFar() + heuristic_cost_estimate( current, neighbor )

			-- Filter
			if not neighbor:IsNodeType(NODE_TYPE) then continue end
			if ( ( neighbor:IsOpen() or neighbor:IsClosed() ) and neighbor:GetCostSoFar() <= newCostSoFar ) then
				continue
			else
				neighbor:SetCostSoFar( newCostSoFar );
				neighbor:SetTotalCost( newCostSoFar + heuristic_cost_estimate( neighbor, node_goal ) )

				if ( neighbor:IsClosed() ) then
					neighbor:RemoveFromClosedList()
				end

				if ( neighbor:IsOpen() ) then
					// This area is already on the open list, update its position in the list to keep costs sorted
					neighbor:UpdateOnOpenList()
				else
					neighbor:AddToOpenList()
				end
				came_from[ neighbor:GetID() ] = current:GetID()
			end
		end
	end
	return false
end

-- Pathfinder meta
local path_meta = {}
path_meta.__index = path_meta
function path_meta:__tostring()
	return "Lua Path"
end
-- Returns true if the paht is valid
function path_meta:IsValid()
	if not self:IsFollowingEntity() then return true end
	return IsValid( self:GetGoal() )
end
-- Returns the goal
function path_meta:GetGoal()
	if not self:IsValid() then return end
	return self[#self]
end
-- Returns true if it is following an entity
function path_meta:IsFollowingEntity()
	return self.ent_goal
end
-- Points. Returns the position of the given joint of the path.
function path_meta:GetPosition( id )
	local c = self[id]
	if type(c) == "Vector" then return c end
	return c:GetPos() -- Node or Entity
end
function path_meta:GetPositions()
	return #self
end
function path_meta:DebugOverlay( lifetime )
	if not lifetime then lifetime = 10 end
	local n = self:GetPositions()
	local p = 360 / n
	for i = 1, n do
		if i < n then
			debugoverlay.Line(self:GetPosition(i), self:GetPosition(i + 1), lifetime, HSLToColor( p * i, 0.5, 0.5))
			debugoverlay.Text(self:GetPosition(i), i, lifetime)
		else
			debugoverlay.Line(self:GetPosition(i), self.start, lifetime, HSLToColor( p * i, 0.5, 0.5))
			debugoverlay.Text(self:GetPosition(i), i, lifetime)
			debugoverlay.Text(self.start, "Start", lifetime)
		end

	end
end
function path_meta:FindClosestPosition( vec )
	local c,n = -1
	for i = 1, self:GetPositions() do
		local dis = self:GetPosition( i ):DistToSqr( vec )
		if c < 0 or dis < c then
			c = dis
			n = i
		end
	end
	return n
end
function path_meta:GetDistance()
	return self.distance or 0
end
-- Creates a new path to a point or entity. Note max_jumpdown is negative. Returns true if reached.
function PathFinder.CreateNewPath(vec_from, vec_or_ent_to, NODE_TYPE, max_distance, max_jump, max_jumpdown, HULL)
	if not scanned then return false end
	local t
	if type(vec_or_ent_to) == "Entity" then
		t = PathFind( FindClosestNode(vec_from, NODE_TYPE), FindClosestNode(vec_or_ent_to, NODE_TYPE),NODE_TYPE, max_distance, max_jump, max_jumpdown, HULL)
		if not t then return false end
		t.ent_goal = true
	else
		t,reached_limit = PathFind( FindClosestNode(vec_from, NODE_TYPE), FindClosestNode(vec_or_ent_to, NODE_TYPE),NODE_TYPE, max_distance, max_jump, max_jumpdown, HULL)
		if not t then return false end
	end
	if type(t) == "boolean" and t then return true end
	t.start = vec_from
	t.distance = 0
	for i = 1, #t - 1 do
		t.distance = t.distance + t[i]:GetPos():Distance(t[i + 1]:GetPos())
	end
	if not t.reached_limit then
		table.insert(t, 1, vec_or_ent_to) -- Add the last point
	end
	setmetatable(t,path_meta)
	return t
end
-- Locates the closest node
function PathFinder.FindClosestNode( vec, NODE_TYPE )
	return FindClosestNode( vec, NODE_TYPE )
end
local type_cache = {}
function PathFinder.GetNodes(NODE_TYPE)
	if not scanned then return {}, 0 end
	NODE_TYPE = NODE_TYPE or NODE_TYPE_ANY
	if not type_cache[NODE_TYPE] then
		local found, count = {}, 0
		for i, node in ipairs(nodes) do
			if node:IsNodeType(NODE_TYPE) then
				count = count + 1
				found[count] = node
			end
		end
		type_cache[NODE_TYPE] = {found, count}
	end
	local cache = type_cache[NODE_TYPE]
	return cache[1], cache[2]
end
-- Returns the node matching the id
function PathFinder.GetNode(id)
	return nodes[id]
end

--	Locate the nodes connecting with the player spawn. We call these "mapnodes".
local spawnpoints = {"info_player_start", "info_player_deathmatch", "info_player_combine", "info_player_rebel", "info_player_counterterrorist", "info_player_terrorist",
"info_player_axis", "info_player_allies", "gmod_player_start", "info_player_teamspawn", "ins_spawnpoint", "aoc_spawnpoint", "dys_spawn_point", "info_player_pirate",
"info_player_viking", "info_player_knight", "diprip_start_team_blue", "diprip_start_team_red","info_player_red", "info_player_blue", "info_player_coop","info_player_human",
"info_player_zombie", "info_player_zombiemaster", "info_player_fof", "info_player_desperado", "info_player_vigilante", "info_survivor_rescue"}

-- I miss my BSP reader
-- Scan the map for spawn entites and scan the connected nodes.
local starting_nodes = {}
local function scan_map(starting_nodes)
	valid_mapnodes = {}
	for k,v in ipairs(starting_nodes) do
		valid_mapnodes[ v ] = true
	end
	local higest = -1 -- Accept any size node at the start
	-- For each of those nodes, find the connected nodes and add them to a list.
	local n = #nodes
	DebugMessage("Starting nodes: " .. table.Count(starting_nodes))
	for i = 1, n * 2 do
		local node = table.remove(starting_nodes, 1)
		if not node then break end -- Done scanning
		for k, v in ipairs(node:GetConnectedNodes()) do
			if valid_mapnodes[ v ] then continue end -- Already scanned
			local n = v:GetHigestHull()
			if n <= higest then continue end
			if n > higest and higest < 4 then
				higest = math.min(n, 4)
			end
			table.insert(starting_nodes, v) -- Scan this node next
			valid_mapnodes[ v ] = true -- Add it to the list of valid nodes
		end
	end
	scanned = true
	MsgN("[Yawd] Map-nodes scanned. Found [" .. table.Count(valid_mapnodes) .. "] valid nodes.")
	hook.Run("YAWDPathFinderNodesLoaded")
end
if SERVER then -- Serverside (We look at the spawn-entities)
	util.AddNetworkString("yawd.pathfind.init")
	hook.Add("YAWDPostEntity", "MapInit", function()
		-- Load the AIN and setup the links.
		LoadAin()
		local nodes_to_scan = {}
		-- Locate nodes near spawn
		for _,ent in ipairs( ents.GetAll() ) do
			if not table.HasValue(spawnpoints, ent:GetClass()) then continue end
			local node = FindClosestNode(ent:GetPos() + Vector(0,0,30), NODE_TYPE_GROUND)
			if not node then continue end
			nodes_to_scan[node] = true
		end
		starting_nodes = table.GetKeys(nodes_to_scan) -- For the clients
		scan_map(table.GetKeys(nodes_to_scan)) -- Scan the rest of the map
	end)
	local t = {}
	net.Receive("yawd.pathfind.init", function(len,ply)
		if t[ply] then return end
		net.Start("yawd.pathfind.init")
			net.WriteInt(#starting_nodes, 32)
			for k,v in ipairs(starting_nodes) do
				net.WriteInt(v:GetID(), 16)
			end
		net.Send(ply)
		t[ply] = true
	end)
else 	-- Clientside (We ask for the starting nodes from the server)
	-- Ask for starting nodes
	hook.Add("YAWDPostEntity", "MapInit", function()
		timer.Simple(1, function()
			-- Load the AIN and setup the links.
			LoadAin()
			net.Start("yawd.pathfind.init")
			net.SendToServer()
		end)
	end)
	net.Receive("yawd.pathfind.init", function()
		starting_nodes = {}
		local t = {}
		for i = 1,net.ReadInt(32) do
			local node = PathFinder.GetNode( net.ReadInt(16))
			table.insert(starting_nodes, node)
			table.insert(t, node)
		end
		scan_map(t)
	end)
end

function node_meta:IsMapNode()
	return valid_mapnodes[ self ] or false
end

function node_meta:IsNearSpawn()
	return table.HasValue(starting_nodes, self)
end

function PathFinder.HasScannedMapNodes()
	return scanned
end

local node_cache
function PathFinder.GetMapNodes()
	if not scanned then return {} end
	if not node_cache then
		node_cache = table.GetKeys(valid_mapnodes)
	end
	return node_cache
end

-- Debug
if CLIENT then
	local debug_paths = CreateClientConVar("yawd_debug_paths", "0", false)

	local min,max = Vector(-15,-15,-10),Vector(15,15,10)
	hook.Add("PostDrawOpaqueRenderables", "debugrender", function()
		if not debug_paths:GetBool() then return end
		render.SetColorMaterial()
		if #nodes < 1 then return end
		local p = LocalPlayer():GetPos()
		for k, v in ipairs( nodes ) do
			if v.pos:DistToSqr(p) > 1000000 then continue end
			local c = Color(155,155,155)
			if v.nodeType == NODE_TYPE_AIR then
				c = Color(0,0,255)
			elseif v.nodeType == NODE_TYPE_GROUND then
				if v:IsMapNode() then
					c = Color(0,255,0)
				else
					c = Color(55,55,55)
				end
			elseif v.nodeType == NODE_TYPE_INVALID then
				c = Color(255,0,0)
			end
			render.DrawBox(v.pos, Angle(0,v.yaw,0), min,max, c)
			local c = Color(155,155,155)
			for k, c2 in ipairs( v:GetConnectedNodes() ) do
				if v.nodeType == NODE_TYPE_AIR or c2.nodeType == NODE_TYPE_AIR then
					c = Color(0,0,255)
				elseif v.nodeType == NODE_TYPE_GROUND then
					if v:IsMapNode() and c2:IsMapNode() then
						c = Color(0,255,0)
					else
						c = Color(55,55,55)
					end
				elseif v.nodeType == NODE_TYPE_INVALID then
					c = Color(255,0,0)
				else
					c = Color(155,155,155)
				end
				render.DrawLine(v:GetPos(), c2:GetPos(), c)
			end
		end
	end)
end
