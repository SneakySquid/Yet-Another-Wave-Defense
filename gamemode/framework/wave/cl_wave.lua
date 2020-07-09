local function WaveHandler(GM, old, new)
	if old == WAVE_VOTE and old ~= new then
		hook.Run("Wave.VoteFinished")
	end
	if new == WAVE_ACTIVE then
		hook.Run("Wave.Started")
	elseif new == WAVE_POST then
		hook.Run("Wave.Finished")
	elseif new == WAVE_VOTE then
		hook.Run("Wave.VoteStart")
	end
end

GM:Accessor("WaveNumber", 0)
GM:Accessor("WaveStatus", WAVE_WAITING, WaveHandler)

net.Receive("Wave.UpdateNumber", function()
	GAMEMODE:SetWaveNumber(net.ReadUInt(32))
end)

net.Receive("Wave.UpdateStatus", function()
	GAMEMODE:SetWaveStatus(net.ReadUInt(3))
end)

net.Receive("Wave.RequestInfo", function()
	GAMEMODE:SetWaveNumber(net.ReadUInt(32))
	GAMEMODE:SetWaveStatus(net.ReadUInt(3))
end)

-- Check if the map has a building core.
hook.Add("YAWDPostEntity", "Wave.RequestInfo", function()
	net.Start("Wave.RequestInfo")
	net.SendToServer()
end)