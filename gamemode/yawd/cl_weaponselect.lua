local last_class = 0

local current_slot = 1

local slot_count = 0
local slot_cache = {}

local mat_selected = Material("vgui/spawnmenu/hover")

local t = {}
local function SMaterial(str)
	str = string.lower(string.gsub(str, "%s", "_"))
	if t[str] then return t[str] end
	t[str] = Material( str )
	return t[str]
end

local function SwitchWeapon()
	if slot_count == 0 then return end

	local info = slot_cache[current_slot]
	if not info then return end

	if info[2] then
		if info[1]:IsValid() then
			input.SelectWeapon(info[1])
		end
	else
		local wep_build = LocalPlayer():GetWeapon("wep_build")
		if not wep_build:IsValid() then return end

		wep_build:SetBuilding(info[1])
		input.SelectWeapon(wep_build)
	end
end

local function PrecacheSlots()
	local ply = LocalPlayer()
	local class = ply:GetPlayerClass()

	slot_cache = {}
	slot_count = 0

	for i, wep in ipairs(ply:GetWeapons()) do
		if wep:GetClass() ~= "wep_build" then
			slot_count = slot_count + 1
			slot_cache[slot_count] = {wep, true}
		end
	end

	for i, building in ipairs(Building.GetAll()) do
		if Building.CanClassBuild(building, class) then
			slot_count = slot_count + 1
			slot_cache[slot_count] = {building, false}
		end
	end

	if slot_count == 0 then
		current_slot = 0
	elseif current_slot > slot_count then
		current_slot = slot_count
	end

	SwitchWeapon()
end

function GM:WeaponSelect(ply, sw, sh)
	if last_class ~= ply:GetPlayerClass() then
		PrecacheSlots()
		last_class = ply:GetPlayerClass()
	end

	if slot_count == 0 then return end

	local currency = ply:GetCurrency()

	local box_size = 80
	local box_margin = 15
	local box_center = box_size * 0.5

	local x_offset = (slot_count - 1) * box_size * 0.5 + (slot_count - 1) * box_margin * 0.5
	local y_pos = sh * 0.8

	for slot, item in ipairs(slot_cache) do
		local is_wep = item[2] == true
		local is_building = item[2] == false

		local x_pos = sw * 0.5 + math.floor(((slot - 1) * box_size - x_offset - box_center) + ((slot - 1) * box_margin))

		if slot == current_slot then
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(mat_selected)
			surface.DrawTexturedRect(x_pos - 8, y_pos - 8, box_size + 16, box_size + 16)
		end

		if is_wep and item[1]:IsValid() then
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(SMaterial(string.format("materials/entities/%s.png", item[1]:GetClass())))
			surface.DrawTexturedRect(x_pos, y_pos, box_size, box_size)
		elseif is_building then
			local cost = Building.GetData(item[1]).Cost

			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(SMaterial(string.format("yawd/hud/%s.png", item[1])))

			surface.DrawTexturedRect(x_pos, y_pos, box_size, box_size)
			draw.SimpleText(cost, "HUD.WeaponSelect", x_pos + box_center, y_pos + box_size - 5, Color(255, 150, 150, cost <= currency and 255 or 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

		draw.SimpleText(slot, "HUD.WeaponSelect", x_pos + 5, y_pos + 5, color_white)
	end
end

hook.Add("PlayerBindPress", "YAWD.Weapon.Select", function(ply, bind, pressed)
	if not ply:Alive() then return end

	if pressed then
		bind = string.lower(bind)

		if bind == "lastinv" then
			local last_wep = ply:GetPreviousWeapon()

			if last_wep:IsWeapon() then
				input.SelectWeapon(last_wep)
			end

			return true
		elseif bind == "cancelselect" then
			current_slot = 0

			return true
		elseif bind == "invprev" then
			if slot_count ~= 0 then
				current_slot = current_slot - 1

				if current_slot == 0 then
					current_slot = slot_count
				end

				SwitchWeapon()
			end

			return true
		elseif bind == "invnext" then
			if slot_count ~= 0 then
				current_slot = current_slot + 1

				if current_slot > slot_count then
					current_slot = 1
				end

				SwitchWeapon()
			end

			return true
		elseif string.sub(bind, 1, 4) == "slot" then
			local slot = tonumber(string.sub(bind, 5))

			if not slot then return end
			if slot_count == 0 then return true end

			if slot ~= current_slot and slot <= slot_count and slot >= 0 then
				current_slot = slot
				SwitchWeapon()
			end

			return true
		end
	end
end)
