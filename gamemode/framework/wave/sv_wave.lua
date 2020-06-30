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

net.Receive("Wave.RequestInfo", function(_, ply)
	local wave = GAMEMODE:GetWaveNumber()
	local status = GAMEMODE:GetWaveStatus()

	if (status ~= WAVE_WAITING) then
		net.Start("Wave.RequestInfo")
			net.WriteUInt(wave, 32)
			net.WriteUInt(status, 2)
		net.Send(ply)
	end
end)
