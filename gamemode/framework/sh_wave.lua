--[[
	Hooks:
		SH:
			Wave.VoteStart			Called when the vote for the core location start.
			Wave.VoteFinished		Called when the vote for the core location is done.
			Wave.Started			Called when the wave start.
			Wave.Finished			Called wehn the wave end.

	Functions:
		SV:
			GM:StartWave, returns true if wave can start, false otherwise.
			GM:EndWave, returns true if wave can end, false otherwise.

		CL:
			None

		SH:
			GM:HasWaveStarted, returns true if wave status is WAVE_ACTIVE, false otherwise.
			GM:IsVoteWave 	   returns true if wave status is WAVE_VOTE, false otherwise.
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

VOTE_TYPE_WAVE = GM:RegisterVoteType(net.WriteBit, net.ReadBit)
