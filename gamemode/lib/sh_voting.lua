GM.VoteInfo = {}
GM.VoteInfo.Voters = {}
GM.VoteInfo.VoteCount = {}
GM.VoteInfo.Networking = {
	Writers = {},
	Readers = {},
}

GM.VoteInfo.TotalVotes = 0

VOTE_TYPE_NONE = 0

NET_VOTE_REQUEST = 0
NET_VOTE_ADDED = 1
NET_VOTE_REMOVED = 2
NET_VOTE_START = 3
NET_VOTE_TYPE = 4
NET_VOTE_LENGTH = 5
NET_VOTE_TIME = 6

local VoteTypes = {
	[0] = VOTE_TYPE_NONE,
}

function GM:RegisterVoteType(writer, reader)
	local stuff = self.VoteInfo.Networking
	local index = #VoteTypes + 1

	VoteTypes[index] = true
	stuff.Writers[index] = writer
	stuff.Readers[index] = reader

	return index
end

if SERVER then
	AddCSLuaFile("voting/cl_voting.lua")
	include("voting/sv_voting.lua")
else
	include("voting/cl_voting.lua")
end
