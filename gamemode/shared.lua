
GM.Name 	= "Yet Another Wave Defence"
GM.Version = "0.1"
GM.Author 	= "SneakySquid & Nak"

-- Ensure the convar is created - wasn't created for me clientside on 64-bit Linux
CreateConVar("yawd_debug", 0, FCVAR_ARCHIVE)

-- Include sandbox
local yawd_debug = GetConVar("yawd_debug")
if yawd_debug:GetBool() then
	DeriveGamemode("sandbox")
end

function DebugMessage(msg)
	if not yawd_debug:GetBool() then return end

	local src_info = debug.getinfo(2, "lS")
	print(string.format("[YAWD] %s - (%s:%i)", msg, src_info.short_src, src_info.currentline))
end

-- Include/Run the lua-file
function HandleFile(str)
	local path = str
	if string.find(str,"/") then
		path = string.GetFileFromFilename(str)
	end
	DebugMessage(str)
	local _type = string.sub(path,0,3)
	if SERVER then
		if _type == "cl_" or _type == "sh_" then
			AddCSLuaFile(str)
		end
		if _type ~= "cl_" then
			return include(str)
		end
	elseif _type ~= "sv_" then
		return include(str)
	end
end
-- Handle folders
function HandleLocalFolder(str, bIgnoreSubFolders)
	local files,folders = file.Find(str .. "/*.lua","LUA")
	if not bIgnoreSubFolders then
		for _,fol in ipairs(folders or {}) do
			HandleLocalFolder(str .. "/" .. fol)
		end
	end
	for _,fil in ipairs(files) do
		HandleFile(str .. "/" .. fil)
	end
end
function HandleFolder(str)
	HandleLocalFolder(GM.FolderName .. "/gamemode/" .. str)
end

-- Load order
HandleFolder("lib")
HandleFolder("framework")
hook.Run("YAWDPreLoaded")

HandleFolder("yawd")
hook.Run("YAWDPostLoaded")

MsgC(GM.Name .. " loaded.\n")
