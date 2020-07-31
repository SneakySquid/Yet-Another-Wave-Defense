util.AddNetworkString("Wave.RequestInfo")
util.AddNetworkString("Wave.UpdateNumber")
util.AddNetworkString("Wave.UpdateStatus")
util.AddNetworkString("Wave.UpdateWaveStart")

GM:Accessor("WaveNumber", 0, function(self, old, new)
	net.Start("Wave.UpdateNumber")
		net.WriteUInt(new, 32)
	net.Broadcast()
end)

GM:Accessor("NextWaveStart", 0, function(self, old, new)
	net.Start("Wave.UpdateWaveStart")
		net.WriteFloat(new)
	net.Broadcast()
end)

GM:Accessor("WaveStatus", WAVE_WAITING, function(self, old, new)
	net.Start("Wave.UpdateStatus")
		net.WriteUInt(new, 2)
	net.Broadcast()
end)

local vote_info = GM.VoteInfo
local vote_timer = util.Timer()
local yawd_votecountdown = GetConVar("yawd_votecountdown")

local function WaveStartCountdown()
	if vote_info.TotalVotes == 0 then
		if vote_timer:Started() then
			vote_timer:Reset()

			GAMEMODE:SetVoteLength(0)
			GAMEMODE:SetVoteStartTime(0)

			DebugMessage("No wave votes, wave countdown reset.")
		end

		return
	elseif vote_info.TotalVotes == player.GetCount() then
		vote_timer:Reset()

		GAMEMODE:EndVote()
		GAMEMODE:StartWave()

		return
	end

	if not vote_timer:Started() then
		local vote_length = yawd_votecountdown:GetFloat()

		GAMEMODE:SetVoteLength(vote_length)
		GAMEMODE:SetVoteStartTime(CurTime())

		DebugMessage("Beginning wave vote countdown.")

		vote_timer:Start(vote_length)
	end

	if vote_timer:Elapsed() then
		vote_timer:Reset()

		GAMEMODE:EndVote()
		GAMEMODE:StartWave()
	end
end

local function HandleCountdown()
	if GAMEMODE.m_VoteStarted and GAMEMODE.m_VoteType == VOTE_TYPE_WAVE then
		WaveStartCountdown()
	elseif GAMEMODE.m_WaveStatus == WAVE_POST then
		if CurTime() >= GAMEMODE.m_NextWaveStart then
			GAMEMODE:StartWave()
		end
	end
end
hook.Add("Think", "Wave.HandleCountdown", HandleCountdown)

hook.Add("ShowSpare2", "Wave.AddVote", function(ply)
	GAMEMODE:AddVote(ply, 0)
end)

hook.Add("YAWDCorePlaced", "Wave.StartCountdown", function()
	GAMEMODE:StartVote(VOTE_TYPE_WAVE)
end)

function GM:StartWave()
	if self:HasWaveStarted() then return false end
	if hook.Run("YAWDWaveStarted") == false then return false end

	self:SetWaveNumber(self:GetWaveNumber() + 1)
	self:SetWaveStatus(WAVE_ACTIVE)

	return true
end

function GM:EndWave()
	if not self:HasWaveStarted() then return false end
	if hook.Run("YAWDWaveFinished") == false then return false end

	if self.m_WaveNumber % 5 == 0 then
		self:StartVote(VOTE_TYPE_WAVE)
		self:SetWaveStatus(WAVE_WAITING)
	else
		self:SetWaveStatus(WAVE_POST)
		self:SetNextWaveStart(CurTime() + 10)
	end

	return true
end

net.Receive("Wave.RequestInfo", function(_, ply)
	local wave = GAMEMODE:GetWaveNumber()
	local status = GAMEMODE:GetWaveStatus()
	local wave_start = GAMEMODE:GetNextWaveStart()

	net.Start("Wave.RequestInfo")
		net.WriteUInt(wave, 32)
		net.WriteUInt(status, 2)
		net.WriteFloat(wave_start)
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
