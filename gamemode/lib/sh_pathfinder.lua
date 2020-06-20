
local floor = math.floor

-- AIN files: https://developer.valvesoftware.com/wiki/AIN
local version = 0
local map_version = 0
local nodes = {}
local links = {}
local lookup = {}

--[[ Description
	PathFinder.CreateNewPath(v_From, v_To, n_max_distance, max_jump, max_jumpdown) 	Returns a pathobject. Returns false if not found a path.
	PathFinder.FindClosestNode( vec ) 												Returns nearest nodeobject.	

	PathObjects:
		:IsValid() 					If the goal is an entity, will check to see if it is valid.
		:GetGoal() 					Returns the goal. (Vector or Entity)
		:IsFollowingEntity() 		Returns true if goal is an entity.
		:GetPosition( num_joint )	Returns a position on the path. Paths start at max and ends at 1.
		:GetPositions() 			Returns the number of positions on the path.
		:DebugOverlay(lifetime)		Renders the path using DebugOverlay.

	NodeObjects:
		:GetPos() 		Returns the position of the node.
		:GetType() 		Returns the type of the node.
		:GetInfo() 		Returns the nodeinfo.
		:GetZone() 		Returns the nodezone.
		:GetConnectedNodes( max_jump, max_jumpdown, HULL ) 	Returns a list of valid nodes
		:GetID() 		Returns the node-id.
		:<A few path-related functions>
]]

--------------- TODO :: Add airnode support ---------------

NODE_TYPE_INVALID = 1
NODE_TYPE_GROUND = 2
NODE_TYPE_AIR = 3
NODE_TYPE_CLIMB = 4
NODE_TYPE_WATER = 5

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
	for k, v in ipairs(links[self]) do
		local deltaheight = v[2][HULL]
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
local function FindClosestNode(vec)
	-- Search the nodes in the nearest grid.
	local g_nodes = GetNodesFromGrid(vec)
	if g_nodes and #g_nodes > 0 then
		local d,c = -1
		for k, v in ipairs( g_nodes ) do
			if v:GetType() ~= NODE_TYPE_GROUND then continue end 	-- :: TODO Add airnode support.
			local dis = vec:Distance(v:GetPos())
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
	if n.nodeType > 5 or n.nodeType < 1 then
		n.nodeType = NODE_TYPE_INVALID
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
local function PathFind(node_start, node_goal, max_distance, max_jump, max_jumpdown, HULL)
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
			if ( ( neighbor:IsOpen() || neighbor:IsClosed() ) && neighbor:GetCostSoFar() <= newCostSoFar ) then
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
PathFinder = {}
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
-- Creates a new path to a point or entity. Note max_jumpdown is negative.
function PathFinder.CreateNewPath(vec_from, vec_or_ent_to, max_distance, max_jump, max_jumpdown)
	local t
	if type(vec_or_ent_to) == "Entity" then
		t = PathFind( FindClosestNode(vec_from) , FindClosestNode(vec_or_ent_to), max_distance, max_jump, max_jumpdown)
		if not t then return false end
		t.ent_goal = true
	else
		t,reached_limit = PathFind( FindClosestNode(vec_from) , FindClosestNode(vec_or_ent_to), max_distance, max_jump, max_jumpdown)
		if not t then return false end
	end
	t.start = vec_from
	if not t.reached_limit then
		table.insert(t, 1, vec_or_ent_to) -- Add the last point
	end
	setmetatable(t,path_meta)
	return t 
end
-- Locates the closest node
function PathFinder.FindClosestNode( vec )
	return FindClosestNode( vec )
end

-- Load the AIN and setup the links.
LoadAin()

-- Debug
--[[
if CLIENT then
	local min,max = Vector(-15,-15,-10),Vector(15,15,10)
	hook.Add("PostDrawOpaqueRenderables", "debugrender", function()
		if true then return end
		render.SetColorMaterial()
		if #nodes < 1 then return end
		local p = LocalPlayer():GetPos()
		for k, v in ipairs( nodes ) do
			if v.pos:DistToSqr(p) > 1000000 then continue end
			local c = Color(155,155,155)
			if v.nodeType == NODE_TYPE_AIR then
				c = Color(0,0,255)
			elseif v.nodeType == NODE_TYPE_GROUND then
				c = Color(0,255,0)
			end
			render.DrawBox(v.pos, Angle(0,v.yaw,0), min,max, c )
			for k, c2 in ipairs( v:GetConnectedNodes() ) do
				render.DrawLine(v:GetPos(), c2:GetPos(), c)
			end
		end
	end)
end]]