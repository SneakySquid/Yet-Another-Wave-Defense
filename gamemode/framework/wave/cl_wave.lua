local function WaveHandler(GM, old, new)
	if new == WAVE_ACTIVE then
		hook.Run("YAWDWaveStarted")
	elseif new == WAVE_POST then
		hook.Run("YAWDWaveFinished")
	end
end

GM:Accessor("WaveNumber", 0)
GM:Accessor("WaveStatus", WAVE_WAITING, WaveHandler)

net.Receive("Wave.UpdateNumber", function()
	GAMEMODE:SetWaveNumber(net.ReadUInt(32))
end)

net.Receive("Wave.UpdateStatus", function()
	GAMEMODE:SetWaveStatus(net.ReadUInt(2))
end)

net.Receive("Wave.RequestInfo", function()
	GAMEMODE:SetWaveNumber(net.ReadUInt(32))
	GAMEMODE:SetWaveStatus(net.ReadUInt(2))

	hook.Run("YAWDWaveInfoReceived")
end)

hook.Add("YAWDPostEntity", "Wave.RequestInfo", function()
	net.Start("Wave.RequestInfo")
	net.SendToServer()
end)
