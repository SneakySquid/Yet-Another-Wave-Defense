local SpawnRateAim = 2 * 60 	-- 4 mins. This is how much time we aim for pr wave.
local MinSpawnRate = 8			-- This is the slowest spawnrate we accept.
local MaxSpawnRate = 0.1		-- This is the max spawnrate we accept.

local SpawnWaveRatio = 3 * math.pi * 2 	-- This calculates how many "waves" we want.
-- Returns a random NPC type
function NPC.SpawnType(npc_type, tOverwrite)
	local t = ents.FindByClass("yawd_npc_spawner")
	if not t or #t < 1 then return false end
	local r_spawner = table.Random(t)
	NPC.Create(npc_type, r_spawner:GetPos() + Vector(0,0,10),tOverwrite)
	return true
end
-- Spawn a golden bug
local function SpawnGoldBug()
	return NPC.SpawnType("ant_lion_gold")
end
-- Gets a random NPC (or gets a cheaper one)
local function GetNPCType(max_coins)
	local l = NPC.GetAll( true, GAMEMODE:GetWaveNumber() )
	local n = math.Round(PRNG.Random( 1, #l))
	local npc_type = l[n]
	local cost = NPC.GetData(npc_type).Currency or 12
	if max_coins < cost then -- Try find another NPC for this wave
		local cur_cost, cur_npc = cost, npc_type
		if n < #l then
			for i = n + 1, #l do
				local c_npc_type = l[i]
				cost = NPC.GetData(c_npc_type).Currency or 12
				if cost > cur_cost then continue end -- This NPC cost more.
				if cost < max_coins then -- This NPC can be used.
					return c_npc_type
				end
				-- This NPC is cheaper than the last one. Set it.
				npc_type = c_npc_type
				cur_cost = cost
			end
		end
		for i = 1, n do
			local c_npc_type = l[i]
			cost = NPC.GetData(c_npc_type).Currency or 12
			if cost > cur_cost then continue end -- This NPC cost more.
			if cost < max_coins then -- This NPC can be used.
				return c_npc_type
			end
			-- This NPC is cheaper than the last one. Set it.
			npc_type = c_npc_type
			cur_cost = cost
		end
	end
	return npc_type
end
local function GenerateNPCList()
	local num = GAMEMODE:GetWaveNumber() or 0
	local max_coins = 50 + 80 * num + math.random(45) * (1 + (#player.GetAll() - 1) * 0.5 )
	-- Easter egg :)
	local core = Building.GetCore()
	if num == 19 and core and IsValid(core) and core:Health() >= 1000 then
		local n = max_coins / NPC.GetData("gman").Currency
		return {{"gman", n}}, n
	end
	local t2 = {}
	-- Dr freemaaaan
	if num > 0 and ((num + 1) % 5) == 0 then
		local n = PRNG.Random(1,3)
		max_coins = max_coins - (NPC.GetData("gman").Currency) * n
		table.insert(t2, {"gman", n})
	end
	local t = {}
	local n = 2 + math.Round( PRNG.Random(#NPC.GetAll() - 1) ) // The amount of diffrent types
	-- Create a NPC list
	local max_runs = 10
	for i = 1, n do
		-- Get the NPC type
		local npc_type = GetNPCType(max_coins * 0.40) -- (By lieing to the NPC picker, we can get some weaker enemies in the start of the wave)
		local npc_data = NPC.GetData(npc_type)
		local cur_amount = t[npc_type] or 0
		-- Get the amount of coins we spent on said NPC
		local amount
		if i == n then
			amount = 1
		else
			amount = PRNG.Random(0.2,0.5)
		end
		-- Calculate the amount
		local cost = NPC.GetData(npc_type).Currency or 12
		local spent = (max_coins * amount)
		local amount = math.ceil( spent / cost + 0.01 )
		-- Check the max amount
		local max_amount = npc_data.MaxPrWave or -1
		if max_amount > -1 then
			amount = math.min(max_amount, amount - cur_amount)
		end
		-- If amount is 0, then spawn something else
		if amount <= 0 then
			i = i - 1
			max_runs = max_runs - 1
			if max_runs > 0 then
				continue
			else -- After 10 times, we give up and give some golden antlions instead
				npc_type = "ant_lion_gold"
				amount = max_coins / NPC.GetData(npc_type).Currency
			end
		else
			max_runs = 10
		end
		max_coins = max_coins - amount * cost
		t[npc_type] = (t[npc_type] or 0) + amount
	end
	-- Sort the list. In this way we can make the large amount of NPC's the primary
	local total = 0
	for k,v in pairs(t) do
		total = total + v
		table.insert(t2, {k,v})
	end
	table.sort(t2, function(a,b) return a[2] < b[2] end)
	return t2, total
end
local npc_list, wave_coroutine = {}
local spawn_rate = MinSpawnRate
local function CoroutineWave()
	local s_wave = CurTime()
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
		-- CalcSpawnrate
		local w_time = CurTime() - s_wave
		local w_procent = w_time / SpawnRateAim
		local n = (1.4 + math.sin(w_procent * SpawnWaveRatio)) / 2 -- 0.2 to 1.2
		coroutine.wait( math.max( MaxSpawnRate, spawn_rate * n )  )
		coroutine.yield( )
	end
end
local npc_total = 0
local function GenerateWave()
	npc_list,npc_total = GenerateNPCList()
	-- Calculate the spawn_rate (We will randomize it a bit)
	spawn_rate = math.min( (SpawnRateAim / npc_total), MinSpawnRate)
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
		if GAMEMODE:GetWaveNumber() == 1 or math.random(50) <= 5 then
			SpawnGoldBug()
		end
		DebugMessage("No more NPCs to spawn. Waiting for NPCs to be slain.")
		wave_coroutine = nil
	elseif not wave_coroutine and GAMEMODE:HasWaveStarted() and check_timer <= CurTime() then -- Need to kill the rest
		check_timer = CurTime() + 1
		if #ents.FindByClass("yawd_npc_base") < 1 then
			DebugMessage("Ending wave.")
			GAMEMODE:EndWave()
		end
	end
end )