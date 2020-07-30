
-- Returns a random NPC type
function NPC.SpawnType(npc_type, tOverwrite)
	local t = ents.FindByClass("yawd_npc_spawner")
	if not t or #t < 1 then return false end
	local r_spawner = table.Random(t)
	NPC.Create(npc_type, r_spawner:GetPos() + Vector(0,0,10),tOverwrite)
	return true
end

local function GetNPCType()
	local l = NPC.GetAll()
	local n = math.Round(PRNG.Random( 1, #l))
	return l[n]
end
local function GenerateNPCList()
	local num = GAMEMODE:GetWaveNumber()
	local max_coins = 100 + 250 * num + math.random(75)
	local t = {}
	local n = 2 + math.Round( PRNG.Random(#NPC.GetAll() - 1) ) // The amount of diffrent types
	for i = 1, n do
		-- Get the NPC type
		local npc_type = GetNPCType()
		-- Get the amount of coins spent on said NPC
		local amount
		if i == n then
			amount = 1
		else
			amount = PRNG.Random(0.2,0.5)
		end
		local cost = NPC.GetData(npc_type).Currency or 12
		local spent = (max_coins * amount)
		local amount = math.ceil( spent / cost )
		max_coins = max_coins - amount * cost
		t[npc_type] = (t[npc_type] or 0) + amount
	end
	-- Sort the list. In this way we can make the large amount of NPC's the primary
	local t2 = {}
	for k,v in pairs(t) do
		table.insert(t2, {k,v})
	end
	table.sort(t2, function(a,b) return a[2] < b[2] end)
	return t2
end
local npc_list, wave_coroutine = {}
local function CoroutineWave()
	while true do
		if #npc_list < 1 then
			-- We ended the wave
			coroutine.yield( true )
		end
		-- We're still in the wave. Pick a random NPC to spawn
		local row = math.Round(math.sqrt( PRNG.Random(1, (#npc_list) ^ 2) )) -- This will try and select the higest
		local npc_tab = npc_list[row]
		if not NPC.SpawnType(npc_tab[1]) then 
			coroutine.yield( true ) -- No spawners
		end
		npc_list[row][2] = npc_tab[2] - 1
		if npc_list[row][2] < 1 then
			table.remove(npc_list, row)
		end
		coroutine.wait( math.random(0.5, 1) )
		if PRNG.Random(1, 10) > 8 then
			coroutine.wait( PRNG.Random(5, 10) )
		end
		coroutine.yield( )
	end
end
local function GenerateWave()
	npc_list = GenerateNPCList()
	wave_coroutine = coroutine.wrap( CoroutineWave )
end
-- Generate a wave
hook.Add("YAWDWaveStarted", "GenerateNPCWave", function()
	GenerateWave()
end)
-- Spawner think
local check_timer = 0
hook.Add( "Think", "WaveSpawnerThink", function()
	if not GAMEMODE:HasWaveStarted() then return end
	if wave_coroutine and wave_coroutine() then
		-- No more NPCs to spawn.
		print("No more NPCs to spawn")
		wave_coroutine = nil
	elseif not wave_coroutine and GAMEMODE:HasWaveStarted() and check_timer <= CurTime() then -- Need to kill the rest
		check_timer = CurTime() + 1
		if #ents.FindByClass("yawd_npc_base") < 1 then
			GAMEMODE:EndWave()
			GAMEMODE:SetWaveNumber( GAMEMODE:GetWaveNumber() + 1 )
		end
	end
end )