do
	surface.CreateFont("HUD.WaveStatus", {
		font = "Tahoma",
		size = 32,
		weight = 1500,
	})

	surface.CreateFont("HUD.Status", {
		font = "Arial",
		size = 32,
	})
end

local HUD = {
	StatusStrings = {
		[WAVE_WAITING] = "Waiting",
		[WAVE_ACTIVE] = "Active",
		[WAVE_POST] = "Finished",
	},

	Colours = {
		["Main"] = Color(35, 35, 35, 200),
		["Health"] = Color(136, 181, 55),
		["Overheal"] = Color(68, 152, 208),
		["Ammo"] = Color(193, 111, 46),
		["Damage"] = Color(255, 75, 75),
	},

	HiddenElements = {
		["CHudHealth"] = true,
		["CHudAmmo"] = true,
		["CHudSecondaryAmmo"] = true,
		["CHudBattery"] = true
	},
}

local grad_r = Material("vgui/gradient-r")
local grad_l = Material("vgui/gradient-l")

local health_lerp = LerpCalc(0.5, 0.25, true)
local overheal_lerp = LerpCalc(0.5, 0.25, true)

local function CanDraw(element)
	return hook.Run("HUDShouldDraw", element) ~= false
end

local function TextBackground(text, font, x, y, text_col, background_col, gradient_w, padding_l, padding_t, padding_r, padding_b, align_x, align_y)
	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)

	if align_x == TEXT_ALIGN_CENTER then
		x = x - tw * 0.5
	elseif align_x == TEXT_ALIGN_RIGHT then
		x = x - tw
	end

	if align_y == TEXT_ALIGN_CENTER then
		y = y - th * 0.5
	elseif align_y == TEXT_ALIGN_BOTTOM then
		y = y - th
	end

	local w = tw + padding_l + padding_r
	local h = th + padding_t + padding_b

	surface.SetDrawColor(background_col)
	surface.DrawRect(x - padding_l, y - padding_t, w, h)

	if gradient_w > 0 then
		surface.SetMaterial(grad_l)
		surface.DrawTexturedRect(x - padding_l + w, y - padding_t, gradient_w, h)

		surface.SetMaterial(grad_r)
		surface.DrawTexturedRect(x - padding_l - gradient_w, y - padding_t, gradient_w, h)
	end

	surface.SetTextPos(math.floor(x), math.floor(y))
	surface.SetTextColor(text_col)
	surface.DrawText(text)
end

HUD.Status = {
	PlayerInfo = function(ply, sw, sh)
	end,

	PlayerHealth = function(ply, sw, sh)
		local hp = math.max(0, ply:Health())
		local max_hp = ply:GetMaxHealth()

		local bw, bh = sw * 0.25, 32
		local bx, by = 10, sh - bh - 10

		surface.SetDrawColor(HUD.Colours.Main)
		surface.DrawRect(bx, by, bw, bh)

		local p = math.min(1, hp / max_hp)
		local lp = health_lerp(hp, max_hp)

		surface.SetDrawColor(HUD.Colours.Damage)
		surface.DrawRect(bx, by, bw * lp, bh)

		surface.SetDrawColor(HUD.Colours.Health)
		surface.DrawRect(bx, by, bw * p, bh)

		if (hp > max_hp) then
			local overheal = math.max(0, hp - max_hp)
			local max_overheal = ply:GetMaxOverheal()

			local op = math.min(1, overheal / max_overheal)
			local olp = overheal_lerp(overheal, max_overheal)

			surface.SetDrawColor(HUD.Colours.Damage)
			surface.DrawRect(bx, by, bw * olp, bh)

			surface.SetDrawColor(HUD.Colours.Overheal)
			surface.DrawRect(bx, by, bw * op, bh)
		end

		draw.SimpleText(string.format("Health: %i", hp), "HUD.Status", bx + 5, by + bh * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end,

	PlayerAmmo = function(ply, sw, sh)
		local wep = ply:GetActiveWeapon()

		if IsValid(wep) then
			local ammo = math.max(0, wep:Clip1())
			local max_ammo = wep:GetMaxClip1()
			local total_ammo = ply:GetAmmoCount(wep:GetPrimaryAmmoType())

			local bw, bh = sw * 0.25, 32
			local bx, by = sw - 10 - bw, sh - bh - 10

			surface.SetDrawColor(HUD.Colours.Main)
			surface.DrawRect(bx, by, bw, bh)

			-- If we used the same lerp function for every weapon we'd get
			-- a useless bar when switching from a full clip to a used clip.
			wep.m_LerpCalc = wep.m_LerpCalc or LerpCalc(0.5, 0.25, true)

			local p = math.min(1, ammo / max_ammo)
			local lp = wep.m_LerpCalc(ammo, max_ammo)

			local w = bw * lp
			local offset = math.ceil(bw - w)

			surface.SetDrawColor(HUD.Colours.Damage)
			surface.DrawRect(offset + bx, by, w, bh)

			w = bw * p
			offset = math.ceil(bw - w)

			surface.SetDrawColor(HUD.Colours.Ammo)
			surface.DrawRect(offset + bx, by, w, bh)

			draw.SimpleText(string.format("Ammo: %.2i / %.2i", ammo, total_ammo), "HUD.Status", bx + bw - 5, by + bh * 0.5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end,

	GoalHealth = function(ply, sw, sh)
		local goal = GAMEMODE:GetEndGoal()
		-- do stuff
	end,
}

HUD.Wave = {
	Status = function(ply, sw, sh)
	end,

	BossHealth = function(ply, sw, sh)
	end,
}

function GM:HUDPaint()
	local ply = LocalPlayer()
	local sw, sh = ScrW(), ScrH()

	if CanDraw("HUD.Wave") then
		if CanDraw("HUD.Wave.Status") then
			HUD.Wave.Status(ply, sw, sh)
		end

		if CanDraw("HUD.Wave.BossHealth") then
			HUD.Wave.BossHealth(ply, sw, sh)
		end
	end

	if CanDraw("HUD.Status") then
		if ply:Team() ~= TEAM_SPECTATOR then
			if CanDraw("HUD.Status.PlayerInfo") then
				HUD.Status.PlayerInfo(ply, sw, sh)
			end

			if CanDraw("HUD.Status.PlayerHealth") then
				HUD.Status.PlayerHealth(ply, sw, sh)
			end

			if CanDraw("HUD.Status.PlayerAmmo") then
				HUD.Status.PlayerAmmo(ply, sw, sh)
			end
		end

--		if CanDraw("HUD.Status.GoalHealth") then
--			HUD.Status.GoalHealth(ply, sw, sh)
--		end
	end
end

function GM:HUDShouldDraw(element)
	return not HUD.HiddenElements[element]
end
