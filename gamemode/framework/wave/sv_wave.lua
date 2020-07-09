util.AddNetworkString("Wave.RequestInfo")
util.AddNetworkString("Wave.UpdateNumber")
util.AddNetworkString("Wave.UpdateStatus")

GM:Accessor("WaveNumber", 0, function(self, old, new)
	net.Start("Wave.UpdateNumber")
		net.WriteUInt(new, 32)
	net.Broadcast()
end)

GM:Accessor("WaveStatus", WAVE_VOTE, function(self, old, new)
	net.Start("Wave.UpdateStatus")
		net.WriteUInt(new, 3)
	net.Broadcast()
end)

function GM:StartWave()
	if self:HasWaveStarted() then return false end
	if not hook.Run("Wave.Started") then return false end

	self:SetWaveStatus(WAVE_ACTIVE)

	return true
end

function GM:EndWave()
	if not self:HasWaveStarted() then return false end
	if not hook.Run("Wave.Finished") then return false end

	self:SetWaveStatus(WAVE_POST)

	return true
end

function GM:StartCoreVote()
	self:SetWaveStatus( WAVE_VOTE )
	hook.Run("Wave.VoteStart")
	print("Start core vote")
end

function GM:EndCoreVote()
	if not self:IsVoteWave() then return false end
	self:SetWaveStatus( WAVE_WAITING )
	hook.Run("Wave.VoteFinished")
	print("Ends core vote")
end

net.Receive("Wave.RequestInfo", function(_, ply)
	local wave = GAMEMODE:GetWaveNumber()
	local status = GAMEMODE:GetWaveStatus()
	net.Start("Wave.RequestInfo")
		net.WriteUInt(wave, 32)
		net.WriteUInt(status, 3)
	net.Send(ply)
end)

-- Check if the map has a building core, else we have to vote on a location.
hook.Add("YAWDPostEntity", "Wave.CheckMap", function()
	local core = ents.FindByClass( "yawd_building_core" )
	if #core > 0 then
		GAMEMODE.Building_Core = core[1] -- Just in case
		GAMEMODE:SetWaveStatus( WAVE_WAITING )
	else
		GAMEMODE:StartCoreVote()
	end
end)