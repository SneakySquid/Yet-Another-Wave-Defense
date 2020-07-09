-- Votes for location of core

--[[ Vote hooks
	SH  yawd_vote_newvote       ply		node	Called when a player vote / change their vote
	CL  yawd_vote_fullupdate					Called when the client get the full data
]]
if SERVER then
	util.AddNetworkString("yawd_voteobj")
end

local con = GetConVar("yawd_votecountdown")
local objective_countdown
if game.SinglePlayer() then
	objective_countdown = 5
else
	objective_countdown = con and con:GetInt() or 60 -- The countdown to the first wave, after a player voted on a position.
end

local NET_ASKFORDATA = 0
local NET_VOTEONNODE = 1
local NET_VOTEADDED = 2
local NET_VOTETIMER = 3

local vote = {}
local vote_countdowntimer = 0 	-- The curtime for the first vote

if SERVER then
	local nospam = {}
	local asked = {}
	-- Vote finished
	local function VoteDone()
		// Count the votes
		local c_vote_tab,c_higest = {}, 0
		for _,node in pairs(vote) do
			c_vote_tab[node] = (c_vote_tab[node] or 0) + 1
			c_higest = math.max( c_higest, c_vote_tab[node])
		end
		local t_choose, pos = {}
		if c_higest < 1 then // No vote. Select a random node
			// Add *all nodes to the array
			for _,node in ipairs(PathFinder.GetMapNodes()) do
				if node:GetType() ~= NODE_TYPE_GROUND then continue end
				if not Building.CanPlaceCore( node ) then continue end
				table.insert(t_choose, node)
			end
		else
			// Add those nodes with the higest points to the array
			for node,point in pairs(c_vote_tab) do
				if point ~= c_higest then continue end
				table.insert(t_choose, node)
			end
		end
		local node = table.Random(t_choose)
		local _,pos,ang = Building.CanPlaceOnFloor("Core", node:GetPos(), 0, false)
		Building.CreateBuilding( "Core", nil, pos or node:GetPos(), ang or Angle(0,0,0) )
	end
	hook.Add("Wave.VoteFinished", "YAWD.FinishVote", VoteDone)
	-- Start voting
	local function VoteStart()
		vote_countdowntimer = 0
		timer.Create("yawd_vote_timer", 0.5, 0, function()
			if not GAMEMODE:IsVoteWave() then // Something went wrong
				timer.Remove("yawd_vote_timer")
				return
			end
			if vote_countdowntimer == 0 then return end // Wait for someone to vote
			local votebonus = (table.Count(vote) - 1) * 15
			local endtime = math.ceil(vote_countdowntimer + objective_countdown - votebonus - CurTime())
			if endtime > 0 then return end // Wait
			timer.Remove("yawd_vote_timer")
			GAMEMODE:EndCoreVote()
		end)
	end
	hook.Add("Wave.VoteStart", "YAWD.StartVote", VoteStart)
	-- When a player voted or changed their vote on a valid node
	local function VoteNode(ply, node) 
		print(ply,"voted on",node)
		vote[ply] = node
		net.Start("yawd_voteobj")
			net.WriteUInt(NET_VOTEADDED, 4)
			net.WriteEntity(ply)
			net.WriteUInt(node:GetID(), 32)
		net.Broadcast()
		hook.Run("yawd_vote_newvote", ply, node)
		-- If nto started, start the countdown
		if vote_countdowntimer == 0 then
			vote_countdowntimer = CurTime()
			net.Start("yawd_voteobj")
				net.WriteUInt(NET_VOTETIMER, 4)
				net.WriteUInt(vote_countdowntimer, 32)
			net.Broadcast()
		end
	end
	-- Network
	net.Receive("yawd_voteobj", function(len,ply)
		if not GAMEMODE:IsVoteWave() then return end
		local msg = net.ReadUInt(4)
		if msg == NET_ASKFORDATA then
			if asked[ply] then return false end -- Already asked for data
			asked[ply] = true
			net.Start("YAWD_voteobj")
				net.WriteUInt(NET_ASKFORDATA, 4)
				net.WriteUInt(vote_countdowntimer, 32)
				net.WriteTable(vote)
			net.Send(ply)
		elseif msg == NET_VOTEONNODE then -- Ply set their vote
			if nospam[ply] and nospam[ply] > CurTime() then return end -- No spam
			nospam[ply] = CurTime() + 0.5
			-- Check to see if node is valid
			local node_id = net.ReadUInt(32)
			local node = PathFinder.GetNode( node_id )
			if not node then return end
			if not Building.CanPlaceCore( node ) then return end
			VoteNode(ply, node)
		end
	end)
else
	-- Ask the server. It won't reply if we don't vote.
	hook.Add("YAWDPostEntity", "yawd.mapvote", function()
		net.Start("yawd_voteobj")
			net.WriteUInt(NET_ASKFORDATA, 4)
		net.SendToServer()
	end)
	-- Network
	net.Receive("yawd_voteobj", function(len)
		local msg = net.ReadUInt(4)
		if msg == NET_ASKFORDATA then
			vote_countdowntimer = net.ReadUInt(32)
			vote = net.ReadTable()
			hook.Run("yawd_vote_fullupdate")
		elseif msg == NET_VOTEADDED then
			local ply = net.ReadEntity()
			local node_id = net.ReadUInt(32)
			local node = PathFinder.GetNode( node_id )
			vote[ply] = node
			hook.Run("yawd_vote_newvote", ply, node)
		elseif msg == NET_VOTETIMER then
			vote_countdowntimer = net.ReadUInt(32)
		elseif msg == NET_VOTEEND then
			hook.Run("yawd_vote_end")
		end
	end)
	-- Play a sound and effects
	hook.Add("yawd_vote_newvote", "NewVoteSound", function(ply, node)
		local pos = node:GetPos()
		local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		sound.Play( "ambient/energy/zap" .. math.random(1,9) .. ".wav", pos )
		util.Effect( "HelicopterMegaBomb", effectdata )
	end)
	-- Sorts and stacks the voted nodes
	local vote_sort = {}
	local function sortvotes()
		vote_sort = {}
		for ply,node in pairs( vote ) do
			if not vote_sort[node] then vote_sort[node] = {} end
			table.insert(vote_sort[node], ply)
		end
	end
	hook.Add("yawd_vote_newvote", "SortVote", sortvotes)
	hook.Add("yawd_vote_fullupdate", "SortVote", sortvotes)

	-- GUI avatars
	if YAWD_GUI_VOTE then -- In case of reload
		for k, v in pairs(YAWD_GUI_VOTE) do
			v:Remove()
		end
	end
	YAWD_GUI_VOTE = {}
	local function GetAvatar(ply)
		-- Check if the player got a gui
		if not YAWD_GUI_VOTE[ply] then
			local p = vgui.Create("AvatarImage")
			YAWD_GUI_VOTE[ply] = p
			p:SetSize(64,64)
			p:SetPos(- 64,0)
			p:SetPlayer( ply )
			return p
		end
		return YAWD_GUI_VOTE[ply]
	end
	-- Clear the avatars on VoteFinished
	hook.Add("Wave.VoteFinished", "RemoveVoteGUI", function()
		for k, v in pairs(YAWD_GUI_VOTE) do
			v:Remove()
		end
		YAWD_GUI_VOTE = {}
	end)

	local render_dis = 5000000
	local tNearBy = {}
	-- Updates the list of nearby nodes
	local function update_nearby()
		tNearBy = {}
		local lp = LocalPlayer():GetPos()
		for _,node in ipairs(PathFinder.GetMapNodes()) do
			if node:GetType() ~= NODE_TYPE_GROUND then continue end
			if not Building.CanPlaceCore( node ) then continue end
			--if not Building.CanPlaceOnFloor(node:GetPos(), EyeAngles().yaw) then continue end
			local np = node:GetPos()
			local dis = np:DistToSqr(lp)
			if dis > render_dis and not vote_sort[node] then continue end
			table.insert(tNearBy, {node, np:DistToSqr(lp),np})
		end
		table.sort( tNearBy, function(a, b) return a[2] > b[2] end )
	end
	local t_cur = 0
	local m = Material("effects/energyball")
	local m2 = Material("effects/energysplash")
	local m3 = Material("effects/splashwake1")
	local function renderPoint(pos, ang, bSelect)
		cam.IgnoreZ(bSelect)
		render.SetMaterial(m2)
		render.DrawBeam( pos, pos + ang:Up() * (bSelect and 120 or 90), 60, 0.8, math.random(0,1) * 0.1, bSelect and Color(0,255,0) or Color( 0, 0, 255 ) )
		render.SetMaterial(m3)
		local n = bSelect and 220 or 90
		local c = bSelect and Color(0,255,0) or Color(155,155,255)
		render.DrawQuadEasy(pos, ang:Up(), n, n, c,CurTime() * 20 % 360)
		render.DrawQuadEasy(pos, ang:Up(), n * 1.3, n * 1.3, c,CurTime() * -15 % 360)
		cam.IgnoreZ(false)
	end
	-- Render the nodes
	local Trace_Cache = {}
	local SelectedNode = -1 -- VoteOnNode
	hook.Add("PreDrawOpaqueRenderables", "YAWD.Vote3DRender", function()
		if not GAMEMODE:IsVoteWave() then return end
		if not IsValid(LocalPlayer()) then return end
		local lp = EyePos()
		-- Only update the nearest node-list each half second.
		if t_cur <= CurTime() then
			t_cur = CurTime() + 0.5
			update_nearby()
		end
		-- Find the node the player is aiming at
		local tr = LocalPlayer():GetEyeTrace()
		local aim_p = tr.Hit and tr.HitPos or LocalPlayer():GetPos()
		local d
		for i = 1,#tNearBy do
			local p = tNearBy[i][3]
			local dis = p:DistToSqr(aim_p)
			if not d or d > dis then
				d = dis
				SelectedNode = tNearBy[i][1]:GetID()
			end
		end
		for i = 1,#tNearBy do
			local node = tNearBy[i][1]
			local pos = tNearBy[i][3]
			render.SetMaterial(m2)
			local t = Building.CanPlaceCore( node )
			local vec,ang = t[1],t[2]
			if SelectedNode >= 0 and SelectedNode == node:GetID() or vote_sort[node] then
				render.SetMaterial(Material("engine/framesync"))
				local s = Building.GetSize("Core")
				render.DrawBox(vec, ang, s[1], s[2], Color(0, 255,0 ), false)
				renderPoint(vec , ang, true)
			else
				local dis = math.Clamp((render_dis - 10000 - pos:DistToSqr(lp)) / 10000,0,255)
				renderPoint(vec , ang)
			end
		end
	end)
	-- Allow voting
	local nTimer = 0
	local lastVote = -1
	-- Reset the last vote
	hook.Add("Wave.VoteStart", "YAWD.VoteReset", function()
		lastVote = -1
	end)
	local function VoteOnNode( node_id )
		if nTimer > CurTime() then return end
		nTimer = CurTime() + 0.8
		if lastVote == node_id then return end
		lastVote = node_id
		net.Start("yawd_voteobj")
			net.WriteUInt(NET_VOTEONNODE, 4)
			net.WriteUInt(node_id, 32)
		net.SendToServer()
	end
	local LV = false
	hook.Add("CreateMove", "YAWD.VoteOnNode", function( cmd )
		if not GAMEMODE:IsVoteWave() then return end
		local m1 = cmd:KeyDown( IN_ATTACK )
		if m1 == LV then return end
		LV = m1
		if not m1 or SelectedNode < 0 then return end
		VoteOnNode( SelectedNode )
	end)
	-- Render the HUD
	local m4 = Material("gui/lmb.png")
	hook.Add("HUDPaint", "YAWD.Vote2DRender", function()
		if not GAMEMODE:IsVoteWave() then return end
		if not IsValid(LocalPlayer()) then return end
		local lp = LocalPlayer():GetPos()
		-- Update the vote-avatars
		for node,plys in pairs( vote_sort ) do
			local pos = node:GetPos() + Vector(0,0,60)
			local screen_pos = pos:ToScreen()
			local n = #plys
			local dis = pos:Distance(lp)
			local size = math.Round(math.Clamp( (800 - dis) / 10 , 32, 64), 0)
			local size_off = size * 1.25
			for i, ply in ipairs(plys) do
				local avatar = GetAvatar(ply)
				local x_off = (i - 1) * size_off - (size_off * n * 0.5)
				avatar:SetPos(screen_pos.x + x_off,screen_pos.y)
				avatar:SetSize(size,size)
			end
		end
		-- Render the countdown and message
		surface.SetMaterial(m4)
		local w,h = ScrW() / 2, ScrH() / 4
		local text = game.SinglePlayer() and "Choose your Core location" or "Vote on Core location"
		surface.SetFont( "HUD.VoteStatus" )
		local tw,th = surface.GetTextSize(text)
		surface.SetDrawColor(255,255,255)
		surface.DrawTexturedRect(w - tw / 2 - th,h - th / 2, th,th)
		surface.SetTextPos(w - tw / 2, h - th / 2)
		surface.SetTextColor(255,255,255)
		surface.DrawText(text)

		if vote_countdowntimer ~= 0 then
			local votebonus = (table.Count(vote) - 1) * 15
			local endtime = math.ceil(vote_countdowntimer + objective_countdown - votebonus - CurTime())
			if endtime <= 0 then
				endtime = "Spawning .."
			end
			draw.DrawText(endtime, "HUD.VoteStatus", w,h / 4 + th, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER)
		end
	end)

end