
local NPCs = {}
NPC = {}
-- Locate animation
local cache = {}
-- Tries to find an animation
local function FindAnim(t, animName, anim_ignore)
	for _,t in ipairs(t) do
		local k,v = t[1],t[2]
		if string.match(v:lower(), animName) and (not anim_ignore or anim_ignore ~= k) then
			return k
		end
	end
end
-- Returns an animationlist.
local function LookUpAnimation(ent)
	local mdl = ent:GetModel()
	if cache[mdl] then return cache[mdl] end
	local t = {}
	for k,v in ipairs(ent:GetSequenceList()) do
		table.insert(t, {k,v})
	end
	table.sort(t, function(a,b) return #a[2] < #b[2] end)
	cache[mdl] = {}
	cache[mdl]["ANIM_IDLE"] = 	FindAnim(t, "idle")
	cache[mdl]["ANIM_RELOAD"] = FindAnim(t, "reload")
	local walkaim = 			FindAnim(t, "walk[._]-aim")
	cache[mdl]["ANIM_WALK_AIM"] = walkaim
	cache[mdl]["ANIM_WALK"] = 	FindAnim(t, "walk[._]-all", walkaim) or FindAnim(t, "walk", walkaim)
	local runaim = 				FindAnim(t, "run[._]-aim")
	cache[mdl]["ANIM_RUN_AIM"] = runaim
	cache[mdl]["ANIM_RUN"] = 	FindAnim(t, "run[._]-all", runaim) or FindAnim(t, "run", runaim)
	cache[mdl]["ANIM_LAND"] = 	FindAnim(t, "jump_holding_land", runaim) or FindAnim(t, "land", runaim)
	return cache[mdl]
end
-- These variables can also be a table or function.
local collapse = {"DisplayName", "Model", "Health", "Skin"}
function NPC.ApplyFunctions(e, sName)
	e.NPC_DATA = NPCs[sName]
	-- Collapse variables
	for _,v in ipairs(collapse) do
		local sTy = type(e.NPC_DATA[v])
		if sTy == "function" then
			e.NPC_DATA[v] = e.NPC_DATA[v]( e )
		elseif sTy == "table" then
			e.NPC_DATA[v] = table.Random( e.NPC_DATA[v] )
		end
	end
	-- Located missing animations
	local t = LookUpAnimation( e )
	for k,v in pairs( t ) do
		e.NPC_DATA[k] = e.NPC_DATA[k] or v
	end
	e:SetMaxSpeed(e.MoveSpeed or 25)
end
-- Creats an NPC at given location. tOverwrite allows you to overwrite variables.
function NPC.Create(sName, vPos,tOverwrite)
	if not sName then ErrorNoHalt("Empty NPC-type.") return end
	if not NPCs[sName] then ErrorNoHalt("Invalid NPC-type [" .. sName .. "].") return end
	local e = ents.Create("yawd_npc_base")
	e:SetNPCType(sName)
	-- Set DATA
	e.NPC_DATA = table.Copy(NPCs[sName])
	if tOverwrite then
		for k,v in ipairs( tOverwrite ) do
			e.NPC_DATA[k] = v
		end
	end
	e:SetPos(vPos)

	-- Collapse variables
	for _,v in ipairs(collapse) do
		local sTy = type(e.NPC_DATA[v])
		if sTy == "function" then
			e.NPC_DATA[v] = e.NPC_DATA[v]( e )
		elseif sTy == "table" then
			e.NPC_DATA[v] = table.Random( e.NPC_DATA[v] )
		end
	end

	-- Set model
	e:SetModel( e.NPC_DATA.Model or Model("models/Zombie/Classic.mdl") )
	e:SetSkin( e.NPC_DATA.Skin or 0 )
	-- Spawn
	e:Spawn()
	-- Located missing animations
	local t = LookUpAnimation( e )
	for k,v in pairs( t ) do
		e.NPC_DATA[k] = e.NPC_DATA[k] or v
	end

	-- Call Init
	if e.NPC_DATA.Init then
		e.NPC_DATA.Init(e)
	end
	e:SetMaxSpeed(e.NPC_DATA.MoveSpeed or 25)
	
	return e
end
-- Adds a new type of NPC.
function NPC.Add(tData)
	if not tData then ErrorNoHalt("Empty NPC file") return end
	if not tData.Name then ErrorNoHalt("Invalid NPC data") return end
	NPCs[tData.Name] = tData
end
-- Returns the NPC data.
function NPC.GetData(sName)
	return NPCs[sName]
end
-- Reward players
function NPC.RewardCurrency( num )
	local t = player.GetAll()
	num = math.ceil( num / #t )
	for k,v in ipairs(t) do
		v:AddCurrency( num )
	end
end
-- Load the NPCs
local files,folders = file.Find( GM.FolderName .. "/gamemode/npcs/*.lua" ,"LUA")
for k,v in ipairs(files) do
	local fil = GM.FolderName .. "/gamemode/npcs/" .. v
	AddCSLuaFile(fil)
	include(fil)
end