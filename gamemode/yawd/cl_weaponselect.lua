
do
	surface.CreateFont("HUD.WeaponSelect", {
		font = "Tahoma",
		size = 18,
		weight = 1500,
		outline = true,
		antialias = true,
		additive = false,
	})
	surface.CreateFont("HUD.WeaponSelectCant", {
		font = "Tahoma",
		size = 18,
		weight = 1500,
		outline = true,
		antialias = true,
		additive = false,
	})
end

hook.Add("HUDShouldDraw", "YAWD_WEPSelect", function( name )
	if name == "CHudWeaponSelection" then return false end
end)

local function SwitchWeapon( wepName )
	local active = LocalPlayer():GetActiveWeapon()
	if active and IsValid(active) and active:GetClass() == wepName then return end
	local wep = LocalPlayer():GetWeapon( wepName )
	if not wep or not IsValid(wep) then return end
	input.SelectWeapon( wep )
end
local buildings = {}
local weps = {}
local wep_slots = {}
local function UpdateSlot()
	wep_slots = {}
	for k,v in ipairs(weps) do
		if v[1] == "wep_build" then continue end
		table.insert(wep_slots, v)
	end
	for k,v in ipairs(buildings) do
		table.insert(wep_slots, v)
	end
end
-- Updates the weapons and sorts them in a list. PlayerClassChanged doesn't have weapons
local sc = {}
local function UpdateWeapons()
	weps = {}
	sc = {}
	for _,wep in ipairs(LocalPlayer():GetWeapons()) do
		local p = wep:GetSlotPos() * 10 + wep:GetSlot()
		if string.find(wep:GetClass(), "fist") then
			p = -1
		end
		table.insert(weps, {wep:GetClass(),p, true})
	end
	table.sort(weps, function(a, b) return a[2]< b[2] end)
	for id,k in ipairs(weps) do
		local wep = weps[id][1]
		table.insert(sc, wep )
		weps[id][2] = (weapons.GetStored(wep) or {}).Cost or 100
	end
	UpdateSlot()
end
-- Yeee there are no hooks to call when the loadout changes
timer.Create("yawd_loadoutscanner", 1, 0, function()
	if not IsValid(LocalPlayer()) then return end
	local wep_list = LocalPlayer():GetWeapons()
	if #sc ~= #wep_list then
		UpdateWeapons()
	else
		for _,wep in ipairs( wep_list ) do
			if not table.HasValue(sc, wep:GetClass()) then
				UpdateWeapons()
				break
			end
		end
	end
end)
local lastClass = -1
local function UpdateBuildings()
	if not LocalPlayer().GetPlayerClass then return end
	local class = LocalPlayer():GetPlayerClass()
	if lastClass == class then return end
	lastClass = class
	buildings = {}
	for _,BuildingName in ipairs(Building.GetAll()) do
		if not Building.CanClassBuild(BuildingName, class) then continue end
		table.insert(buildings, {BuildingName, Building.GetData( BuildingName ).Cost})
	end
	table.sort(buildings,function(a,b) return a[2] < b[2] end)
	UpdateSlot()
end
local selected = 1
timer.Create("yawd_loadout", 0.2, 0, function()
	-- Update buildings in case we switch class
	UpdateBuildings()
	if not wep_slots[selected] then selected = 1 return end -- In case something goes wrong
	local wep = wep_slots[selected][1]
	local wep_class
	if wep_slots[selected][3] then
		wep_class = wep
	else
		wep_class = "wep_build"
		local wep_build = LocalPlayer():GetWeapon( "wep_build" )
		if wep_build and IsValid(wep_build) then
			wep_build:SetBuilding( wep )
		end
	end
	if not wep_class then return end
	SwitchWeapon( wep_class )
end)
local box_size = 80
local box_space = 15
local hover = Material("vgui/spawnmenu/hover")
local hover_size = 8

local t = {}
local function SMaterial(str)
	if t[str] then return t[str] end
	t[str] = Material( str )
	return t[str]
end

hook.Add("HUDPaint", "YAWD_WeaponSelection", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if #ply:GetWeapons() <= 0 then return end
	local wide = (#wep_slots + 1) * (box_size + box_space)
	local wep_build = ply:GetWeapon( "wep_build" )
	local Has_Wep_Build = wep_build and IsValid(wep_build)
	surface.SetDrawColor(255,255,255)
	local coin = ply:GetCurrency()
	for k,v in ipairs(wep_slots) do
		local x = k * (box_size + box_space) + ScrW() / 2 - wide / 2
		local y = ScrH() * 0.8
		local obj = v[1]
		local CanAffort = coin >= v[2]
		local IsWeapon =  v[3]
		if k == selected then
			surface.SetDrawColor(Color(255,255,255))
			surface.SetMaterial(hover)
			surface.DrawTexturedRect(x - hover_size, y - hover_size,box_size + hover_size * 2,box_size + hover_size * 2)
		end
		if IsWeapon then
			surface.SetDrawColor(255, 255, 255, CanAffort and 255 or 155)
			surface.SetMaterial(SMaterial("materials/entities/"..obj..".png"))
			surface.DrawTexturedRect(x, y,box_size,box_size)
			if v[2] > 0 then
				if CanAffort then
					surface.SetDrawColor(255, 255, 255, 255)
					surface.DrawTexturedRect(x, y,box_size,box_size)
					draw.DrawText(v[2], "HUD.WeaponSelect", x + box_size / 2, y + box_size - 18, Color( 255, 255, 255, 255 ) , TEXT_ALIGN_CENTER)
				else
					surface.SetDrawColor(155, 155, 155, 205)
					surface.DrawTexturedRect(x, y,box_size,box_size)
					draw.DrawText(v[2], "HUD.WeaponSelectCant", x + box_size / 2, y + box_size - 18, Color( 155, 155, 155, 255 ), TEXT_ALIGN_CENTER)
				end
			end
		elseif Has_Wep_Build then
			local bd = Building.GetData( obj )
			local mat
			if bd and bd.Icon then
				mat = bd.Icon
			else
				mat = SMaterial("yawd/hud/"..obj..".png")
			end
			surface.SetMaterial(mat)
			if CanAffort then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(x, y,box_size,box_size)
				draw.DrawText(v[2], "HUD.WeaponSelect", x + box_size / 2, y + box_size - 18, Color( 255, 255, 255, 255 ) , TEXT_ALIGN_CENTER)
			else
				surface.SetDrawColor(155, 155, 155, 205)
				surface.DrawTexturedRect(x, y,box_size,box_size)
				draw.DrawText(v[2], "HUD.WeaponSelectCant", x + box_size / 2, y + box_size - 18, Color( 155, 155, 155, 255 ), TEXT_ALIGN_CENTER)
			end
		end
		local hKey = k
		if k == 10 then
			k = 0
		elseif k > 10 then
			k = ""
		end
		draw.DrawText(k, "HUD.WeaponSelect", x, y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT)
	end
end)

local nextTurn = 0
hook.Add("CreateMove", "YAWD_WeaponSelection", function(cmd)
	for i = 0, 9 do
		local key = KEY_0 + i
		if input.WasKeyReleased( key ) then
			selected = i > 0 and (key - 1) or 10
			nextTurn = CurTime() + .05
		end
	end
	local mvh = cmd:GetMouseWheel()
	if mvh == 0 then return end
	if nextTurn >= CurTime() then return end
	nextTurn = CurTime() + .05
	selected = selected - mvh
	if selected <= 0 then
		selected = #wep_slots
	elseif selected > #wep_slots then
		selected = 1
	end
end)