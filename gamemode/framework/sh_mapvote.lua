local vote_info = GM.VoteInfo

local function writer(node)
	net.WriteUInt(node:GetID(), 32)
end

local function reader()
	return PathFinder.GetNode(net.ReadUInt(32))
end

VOTE_TYPE_CORE = GM:RegisterVoteType(writer, reader)

local function IsCoreVote()
	return GAMEMODE.m_VoteStarted and GAMEMODE.m_VoteType == VOTE_TYPE_CORE
end

local function IsNodeValid(node)
	return node:GetType() == NODE_TYPE_GROUND and Building.CanPlaceCore(node)
end

local function CheckNodeValid(voter, vote)
	if GAMEMODE.m_VoteType == VOTE_TYPE_CORE then
		return IsNodeValid(vote)
	end
end
hook.Add("YAWDCanAddVote", "MapVote.CheckNodeValid", CheckNodeValid)

if SERVER then
	local yawd_votecountdown = GetConVar("yawd_votecountdown")

	GM:StartVote(VOTE_TYPE_CORE)

	local countdown_started, vote_length = false, 0
	local function HandleCountdown()
		if not IsCoreVote() then return end

		if vote_info.TotalVotes == 0 then
			if countdown_started then
				countdown_started = false

				GAMEMODE:SetVoteLength(0)
				GAMEMODE:SetVoteStartTime(0)

				DebugMessage("No core votes, vote countdown reset.")
			end

			return
		end

		if not countdown_started then
			vote_length = yawd_votecountdown:GetFloat()

			GAMEMODE:SetVoteLength(vote_length)
			GAMEMODE:SetVoteStartTime(CurTime())

			DebugMessage("Beginning core vote countdown.")

			countdown_started = true
		end

		if GAMEMODE.m_VoteStartTime + vote_length <= CurTime() then
			countdown_started = false

			local winners, highest_vote, winner_count = GAMEMODE:EndVote()
			local winner = winners[math.random(winner_count)]

			DebugMessage(string.format("%s is the winner with %i votes!", winner, highest_vote))

			local t = Building.CanPlaceCore(winner)
			if not t then
				GAMEMODE:StartVote(VOTE_TYPE_CORE)
				GAMEMODE:SetVoteLength(0)
				GAMEMODE:SetVoteStartTime(0)

				DebugMessage(string.format("Failed to place Core on %s?", winner))

				return
			end

			local pos, ang = t[1], t[2]
			Building.CreateBuilding("Core", nil, pos, ang)
		end
	end
	hook.Add("Think", "MapVote.HandleCountdown", HandleCountdown)

	return
end

surface.CreateFont("MapVote.VoteCounter", {
	font = "Roboto",
	size = 128,
})

local function VoteAdded(voter, node)
	if not IsCoreVote() then return end

	local effect = EffectData()
	effect:SetOrigin(node:GetPos())

	util.Effect("HelicopterMegaBomb", effect)
end
hook.Add("YAWDVoteAdded", "MapVote.VoteAdded", VoteAdded)

local selected_node
local hovered_node

local function UpdateNodeOrder(origin, max_dist)
	local ground_nodes, node_count = PathFinder.GetNodes(NODE_TYPE_GROUND)
	if node_count == 0 then return ground_nodes, node_count end

	local order, count = {}, 0
	max_dist = max_dist * max_dist

	for i, node in ipairs(ground_nodes) do
		if IsNodeValid(node) then
			local dist = origin:DistToSqr(node:GetPos())
			if not vote_info.VoteCount[node] and dist > max_dist then goto CONTINUE end

			count = count + 1
			order[count] = {node, dist}
		end

		::CONTINUE::
	end

	table.sort(order, function(a, b)
		return a[2] > b[2]
	end)

	return order, count
end

local node_offset = Vector(0, 0, 60)

local colour_selected = Color(0, 255, 0)
local colour_hovered = Color(125, 125, 255)
local colour_ignored = Color(200, 50, 50)

local mat_energysplash = Material("effects/energysplash")
local mat_splashwake = Material("effects/splashwake1")

local last_attack = false
local function SelectNode(cmd)
	if not IsCoreVote() or not hovered_node then return end

	local attack = cmd:KeyDown(IN_ATTACK)

	if selected_node ~= hovered_node and not last_attack and attack then
		selected_node = hovered_node
		GAMEMODE:SendVote(selected_node)
	end

	last_attack = attack
end
hook.Add("CreateMove", "MapVote.SelectNode", SelectNode)

local avatars = {}
local function GetAvatar(ply)
	if not IsValid(ply) then return end

	local id = ply:SteamID()

	if not avatars[id] then
		local a = vgui.Create("AvatarImage")
		a:SetSize(128, 128)
		a:SetPlayer(ply, 128)
		a:SetPaintedManually(true)

		avatars[id] = a
	end

	return avatars[id]
end

local function RenderNode(pos, up, selected, col)
	local end_pos = pos + up * (selected and 120 or 90)
	local size = selected and 220 or 90

	cam.IgnoreZ(selected)
		render.SetMaterial(mat_energysplash)
		render.DrawBeam(pos, end_pos, 60, 0.8, math.random(0, 1) * 0.1, col)

		render.SetMaterial(mat_splashwake)
		render.DrawQuadEasy(pos, up, size, size, col, CurTime() * 20 % 360)
		render.DrawQuadEasy(pos, up, size * 1.3, size * 1.3, col, CurTime() * -15 % 360)
	cam.IgnoreZ(false)
end

local function RenderNodes(_, drawing_skybox)
	if drawing_skybox or not IsCoreVote() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local eyeang = EyeAngles()
	local aimvec = ply:GetAimVector()
	local shootpos = ply:GetShootPos()

	eyeang:RotateAroundAxis(eyeang:Right(), 90)
	eyeang:RotateAroundAxis(eyeang:Up(), -90)

	local best_fov = 0
	local closest_node = nil

	local ordered_nodes = UpdateNodeOrder(shootpos, 2500)

	for _, info in ipairs(ordered_nodes) do
		local node = info[1]
		local votes = vote_info.VoteCount[node]

		local selected = selected_node == node
		local col = colour_ignored

		if selected then
			col = colour_selected
		elseif node == hovered_node then
			col = colour_hovered
		end

		local t = Building.CanPlaceCore(node)
		local pos, ang = t[1], t[2]

		if not votes then
			local tr = util.TraceLine({
				start = shootpos,
				endpos = pos,
				mask = MASK_NPCWORLDSTATIC,
			})

			if (tr.Hit) then goto CONTINUE end
		end

		RenderNode(pos, ang:Up(), selected, col)

		if votes and votes > 0 then
			cam.IgnoreZ(true)
				cam.Start3D2D(pos + node_offset, eyeang, 0.5)
					draw.SimpleText(string.format("%i Vote%s", votes, votes == 1 and "" or "s"), "MapVote.VoteCounter", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

					local found_voters = 0

					for voter, vote in pairs(vote_info.Voters) do
						if vote == node then
							local avatar = GetAvatar(voter)

							if IsValid(avatar) then
								local x_offset = (votes - 1) * 128 * 0.5
								local x_pos = math.floor(found_voters * 128 - x_offset - 64)

								avatar:SetPos(x_pos, 0)
								avatar:PaintManual()
							end

							found_voters = found_voters + 1

							if found_voters == votes then break end
						end
					end
				cam.End3D2D()
			cam.IgnoreZ(false)
		end

		local delta = (pos + node_offset) - shootpos
		local fov = aimvec:Dot(delta) / delta:Length()

		if fov > best_fov then
			closest_node = node
			best_fov = fov
		end

		::CONTINUE::
	end

	if closest_node then
		hovered_node = closest_node
	end
end
hook.Add("PreDrawOpaqueRenderables", "MapVote.RenderNodes", RenderNodes)
