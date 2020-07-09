
-- Nodes.Loaded

-- Controls the PATHs and NPC directions
Controller = {}
local paths = {}

NPC_TYPE_NORMAL = 0
NPC_TYPE_FLYER = 1
NPC_TYPE_BOSS = 3
NPC_TYPE_ALL = 4

-- Handles the spawning of spawners on the map
if SERVER then
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
        print("Spawned")
    end
    -- Check to see if we can spawn spawners.
    function Controller.TrySpawnSpawners()
        print("Checking spawner..")
        -- Check to see if the nodes have been scanned.
        if not PathFinder.HasScannedMapNodes() then return false end
        -- Check to see if the map has a core.
        if not IsValid(Building.GetCore()) then return false end
        SpawnSpawners()
        return true
    end
    hook.Add("Nodes.Loaded", "YAWD.SpawnSpawners", Controller.TrySpawnSpawners)
end