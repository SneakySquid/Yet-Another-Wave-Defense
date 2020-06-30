--[[

	Functions:
		SV:
			GM:StartWave, returns true if wave can start, false otherwise.
			GM:EndWave, returns true if wave can end, false otherwise.

		CL:
			None

		SH:
			GM:HasWaveStarted, returns true if wave status is WAVE_ACTIVE, false otherwise.

			GM:SetWaveNumber, returns nil.
			GM:GetWaveNumber, returns wave number.

			GM:SetWaveStatus, returns nil.
			GM:GetWaveStatus, returns WAVE enum.

]]

WAVE_WAITING = 0
WAVE_ACTIVE = 1
WAVE_POST = 2

function GM:HasWaveStarted()
	return self:GetWaveStatus() == WAVE_ACTIVE
end

if SERVER then
	AddCSLuaFile("wave/cl_wave.lua")
	include("wave/sv_wave.lua")
else
	include("wave/cl_wave.lua")
end

-- WIP Spawns a spawner at one of the corners of the map.

if SERVER then
	local function SpawnSpawners()
		-- Delete old spawners
		for k,v in ipairs(ents.FindByClass("yawd_npc_spawner")) do
			SafeRemoveEntity(v)
		end
		-- Create a list of all points, furthest from the center of the map.
		local c = Vector(0,0,0)
		local t = {}
		for id,node in ipairs(PathFinder.GetNodes()) do
			if node:GetType() ~= NODE_TYPE_GROUND then continue end
			table.insert(t, {node:GetID(),node:GetPos():Distance(c)})
		end
		table.sort( t, function(a, b) return a[2] > b[2] end ) -- [Node:ID, Distance]
		--SpawnSpawnerAtNode(t[1][1])
	end
	SpawnSpawners()
end
