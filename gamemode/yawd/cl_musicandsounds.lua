
local sndList = {}
sndList[1] = {"music/stingers/industrial_suspense1.wav"}
sndList[3] = {"music/stingers/hl1_stinger_song16.mp3", "music/stingers/industrial_suspense2.wav", "music/stingers/hl1_stinger_song7.mp3"}
sndList[10] = {"music/stingers/hl1_stinger_song27.mp3", "music/stingers/hl1_stinger_song16.mp3", "music/stingers/industrial_suspense2.wav", "music/stingers/hl1_stinger_song7.mp3"}

hook.Add("YAWDWaveStarted", "YAWDStartMusic", function()
	-- Locate the soundtable that match for the given wave
	local num = GAMEMODE:GetWaveNumber()
	local c_num = 0
	for k,v in pairs(sndList) do
		if num >= k and c_num < k then
			c_num = k
		end
	end
	surface.PlaySound( table.Random(sndList[c_num]) )
end)