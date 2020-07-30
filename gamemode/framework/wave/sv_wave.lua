util.AddNetworkString("Wave.RequestInfo")
util.AddNetworkString("Wave.UpdateNumber")
util.AddNetworkString("Wave.UpdateStatus")

GM:Accessor("WaveNumber", 0, function(self, old, new)
	net.Start("Wave.UpdateNumber")
		net.WriteUInt(new, 32)
	net.Broadcast()
end)

GM:Accessor("WaveStatus", WAVE_WAITING, function(self, old, new)
	net.Start("Wave.UpdateStatus")
		net.WriteUInt(new, 2)
	net.Broadcast()
end)

function GM:StartWave()
	if self:HasWaveStarted() then return false end
	if hook.Run("YAWDWaveStarted") == false then return false end
	self:SetWaveNumber( self:GetWaveNumber() + 1 )
	self:SetWaveStatus(WAVE_ACTIVE)

	return true
end

function GM:EndWave()
	if not self:HasWaveStarted() then return false end
	if hook.Run("YAWDWaveFinished") == false then return false end

	self:SetWaveStatus(WAVE_POST)

	return true
end

net.Receive("Wave.RequestInfo", function(_, ply)
	local wave = GAMEMODE:GetWaveNumber()
	local status = GAMEMODE:GetWaveStatus()

	net.Start("Wave.RequestInfo")
		net.WriteUInt(wave, 32)
		net.WriteUInt(status, 2)
	net.Send(ply)
end)

-- Check if the map has a building core, else we have to vote on a location.
hook.Add("YAWDPostEntity", "Wave.CheckMap", function()
	local core = ents.FindByClass("yawd_building_core")
	if #core > 0 then
		GAMEMODE.Building_Core = core[1] -- Just in case
		GAMEMODE:SetWaveStatus(WAVE_WAITING)
	end
end)
