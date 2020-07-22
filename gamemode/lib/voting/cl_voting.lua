local vote_info = GM.VoteInfo
local writers = vote_info.Networking.Writers
local readers = vote_info.Networking.Readers

function GM:SendVote(vote)
	if not self.m_VoteStarted then return false end
	if hook.Run("YAWDCanAddVote", LocalPlayer(), vote) == false then return false end

	local writer = writers[self.m_VoteType]

	net.Start("Vote.Update")
		net.WriteUInt(NET_VOTE_ADDED, 3)
		writer(vote)
	net.SendToServer()
end

local function VoteAdded()
	local voter = net.ReadEntity()
	local vote = readers[GAMEMODE.m_VoteType]()
	DebugMessage(string.format("Received vote from %s on %s.", voter:Nick(), vote))

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

	hook.Run("YAWDVoteAdded", voter, vote)
end

local function VoteRemoved()
	local voter = net.ReadEntity()
	local vote = vote_info.Voters[voter]
	if vote == nil then return end

	vote_info.Voters[voter] = nil
	vote_info.VoteCount[vote] = vote_info.VoteCount[vote] - 1

	if vote_info.VoteCount[vote] == 0 then
		vote_info.VoteCount[vote] = nil
	end

	vote_info.TotalVotes = vote_info.TotalVotes - 1
end

local function VoteRequest()
	GAMEMODE:SetVoteType(net.ReadUInt(8))
	GAMEMODE:SetVoteLength(net.ReadFloat())
	GAMEMODE:SetVoteStartTime(net.ReadFloat())
	GAMEMODE:SetVoteStarted(net.ReadBool())

	for i = 1, net.ReadUInt(8) do
		VoteAdded()
	end
end

do
	local function VoteStarted(GM, old, new)
		if new ~= true then return end

		vote_info.Voters = {}
		vote_info.VoteCount = {}
		vote_info.TotalVotes = 0

		hook.Run("YAWDVoteStarted", GM.m_VoteType, GM.m_VoteLength)
	end

	GM:Accessor("VoteStarted", false, VoteStarted)
	GM:Accessor("VoteType", VOTE_TYPE_NONE)
	GM:Accessor("VoteLength", 0)
	GM:Accessor("VoteStartTime", 0)
end

local function UpdateChanges(var, reader, ...)
	local setter = GM["Set" .. var]
	local extras = {...}

	return function()
		local updated = reader(unpack(extras))
		setter(GAMEMODE, updated)

		DebugMessage(string.format("Updating %q to %s.", var, updated))
	end
end

local Updaters = {
	[NET_VOTE_REQUEST] = VoteRequest,
	[NET_VOTE_ADDED] = VoteAdded,
	[NET_VOTE_REMOVED] = VoteRemoved,
	[NET_VOTE_START] = UpdateChanges("VoteStarted", net.ReadBool),
	[NET_VOTE_TYPE] = UpdateChanges("VoteType", net.ReadUInt, 8),
	[NET_VOTE_LENGTH] = UpdateChanges("VoteLength", net.ReadFloat),
	[NET_VOTE_TIME] = UpdateChanges("VoteStartTime", net.ReadFloat),
}

net.Receive("Vote.Update", function()
	local type = net.ReadUInt(3)
	local updater = Updaters[type]

	if updater then
		updater()
	end
end)

hook.Add("YAWDPathFinderNodesLoaded", "Vote.RequestInfo", function()
	net.Start("Vote.Update")
		net.WriteUInt(NET_VOTE_REQUEST, 3)
	net.SendToServer()
end)
