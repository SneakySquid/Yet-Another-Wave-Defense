util.AddNetworkString("Vote.Update")

local vote_info = GM.VoteInfo
local writers = vote_info.Networking.Writers
local readers = vote_info.Networking.Readers

function GM:AddVote(voter, vote)
	if not self.m_VoteStarted then return false end
	if hook.Run("YAWDCanAddVote", voter, vote) == false then return false end

	DebugMessage(string.format("Adding vote for %s from %s.", vote, voter:Nick()))

	local previous_vote = vote_info.Voters[voter]

	if previous_vote ~= nil then
		vote_info.VoteCount[previous_vote] = vote_info.VoteCount[previous_vote] - 1

		if vote_info.VoteCount[previous_vote] == 0 then
			vote_info.VoteCount[previous_vote] = nil
		end
	else
		vote_info.TotalVotes = vote_info.TotalVotes + 1
	end

	vote_info.Voters[voter] = vote
	vote_info.VoteCount[vote] = (vote_info.VoteCount[vote] or 0) + 1

	net.Start("Vote.Update")
		net.WriteUInt(NET_VOTE_ADDED, 3)

		net.WriteEntity(voter)
		writers[self.m_VoteType](vote)
	net.Broadcast()

	hook.Run("YAWDVoteAdded", voter, vote)

	return true
end

function GM:RemoveVote(ply)
	if not self.m_VoteStarted then return end

	local vote = vote_info.Voters[ply]
	if vote == nil then return end

	vote_info.Voters[ply] = nil
	vote_info.VoteCount[vote] = vote_info.VoteCount[vote] - 1

	if vote_info.VoteCount[vote] == 0 then
		vote_info.VoteCount[vote] = nil
	end

	vote_info.TotalVotes = vote_info.TotalVotes - 1

	net.Start("Vote.Update")
		net.WriteUInt(NET_VOTE_REMOVED, 3)
		net.WriteEntity(ply)
	net.Broadcast()
end

function GM:StartVote(vote_type)
	if self.m_VoteStarted then return false end
	if hook.Run("YAWDCanStartVote", vote_type, vote_length) == false then return false end

	vote_info.Voters = {}
	vote_info.VoteCount = {}
	vote_info.TotalVotes = 0

	self:SetVoteType(vote_type)
--	self:SetVoteLength(vote_length)
--	self:SetVoteStartTime(CurTime())
	self:SetVoteStarted(true) -- update last so that we have the values set cl

	hook.Run("YAWDVoteStarted", vote_type, vote_length)

	return true
end

function GM:EndVote()
	if not self.m_VoteStarted then return false end
	if hook.Run("YAWDCanEndVote") == false then return false end

	local highest_vote = 0
	local winner_count = 0

	for _, votes in pairs(vote_info.VoteCount) do
		if votes > highest_vote then
			highest_vote = votes
			winner_count = 1
		elseif votes == highest_vote then
			winner_count = winner_count + 1
		end
	end

	local winners = {}
	local winner_pos = winner_count

	for vote, votes in pairs(vote_info.VoteCount) do
		if votes == highest_vote then
			winners[winner_pos] = vote
			winner_pos = winner_pos - 1

			if winner_pos == 0 then break end
		end
	end

	self:SetVoteStarted(false)
	self:SetVoteType(VOTE_TYPE_NONE)

	hook.Run("YAWDVoteFinished", self.m_VoteType, winners, highest_vote, winner_count)

	vote_info.Voters = {}
	vote_info.VoteCount = {}
	vote_info.TotalVotes = 0

	return winners, highest_vote, winner_count
end

do
	local function UpdateChanges(type, writer, ...)
		local extras = {...}

		return function(GM, old, new)
			net.Start("Vote.Update")
				net.WriteUInt(type, 3)
				writer(new, unpack(extras))
			net.Broadcast()
		end
	end

	GM:Accessor("VoteStarted", false, UpdateChanges(NET_VOTE_START, net.WriteBool))
	GM:Accessor("VoteType", VOTE_TYPE_NONE, UpdateChanges(NET_VOTE_TYPE, net.WriteUInt, 8))
	GM:Accessor("VoteLength", 0, UpdateChanges(NET_VOTE_LENGTH, net.WriteFloat))
	GM:Accessor("VoteStartTime", 0, UpdateChanges(NET_VOTE_TIME, net.WriteFloat))
end

net.Receive("Vote.Update", function(_, ply)
	local type = net.ReadUInt(3)

	if type == NET_VOTE_REQUEST then
		DebugMessage(string.format("%s requested vote info.", ply:Nick()))

		net.Start("Vote.Update")
			net.WriteUInt(NET_VOTE_REQUEST, 3)

			net.WriteUInt(GAMEMODE.m_VoteType, 8)
			DebugMessage(string.format("Sending vote type (%i).", GAMEMODE.m_VoteType))
			net.WriteFloat(GAMEMODE.m_VoteLength)
			DebugMessage(string.format("Sending vote length (%.2f).", GAMEMODE.m_VoteLength))
			net.WriteFloat(GAMEMODE.m_VoteStartTime)
			DebugMessage(string.format("Sending vote start time (%.2f).", GAMEMODE.m_VoteStartTime))
			net.WriteBool(GAMEMODE.m_VoteStarted)
			DebugMessage(string.format("Sending vote started (%s).", GAMEMODE.m_VoteStarted))

			net.WriteUInt(vote_info.TotalVotes, 8)

			if GAMEMODE.m_VoteStarted and vote_info.TotalVotes ~= 0 then
				for voter, vote in pairs(vote_info.Voters) do
					net.WriteEntity(voter)
					writers[GAMEMODE.m_VoteType](vote)

					DebugMessage(string.format("Sending vote info (%s, %s).", voter:Nick(), vote))
				end
			end
		net.Send(ply)
	elseif type == NET_VOTE_ADDED then
		local vote = readers[GAMEMODE.m_VoteType]()
		GAMEMODE:AddVote(ply, vote)
	end
end)
