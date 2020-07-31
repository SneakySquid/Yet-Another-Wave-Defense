do
	surface.CreateFont("HUD.WaveStatus", {
		font = "Tahoma",
		size = 32,
		weight = 1500,
	})

	surface.CreateFont("HUD.WaveDisplay", {
		font = "Tahoma",
		size = 20,
		weight = 1500,
		outline = true
	})

	surface.CreateFont("HUD.WaveDisplayNumber", {
		font = "Tahoma",
		size = 40,
		weight = 1500,
		outline = true
	})

	surface.CreateFont("HUD.VoteStatus", {
		font = "Tahoma",
		size = 32,
		weight = 1500,
	})

	surface.CreateFont("HUD.Building", {
		font = "Tahoma",
		size = 32,
		weight = 1500,
	})

	surface.CreateFont("HUD.Status", {
		font = "Arial",
		size = 32,
	})

	surface.CreateFont("HUD.WeaponSelect", {
		font = "Tahoma",
		size = 18,
		weight = 1500,
		outline = true,
		antialias = true,
		additive = false,
	})

	surface.CreateFont("HUD.TargetID", {
		font = "Arial",
		size = 24,
	})
end

local vote_info = GM.VoteInfo

local core_lerp = PercentLerp(0.5, 0.25, true)
local health_lerp = PercentLerp(0.5, 0.25, true)
local overheal_lerp = PercentLerp(0.5, 0.25, true)
local currency_lerp = TargetLerp(0, 0.5)
local wavedisplay_core_shakestart = 0
local wavedisplay_core_hp = -1
local wavedisplay_core_shakespeed = 0


local left_mouse_indicator = Material("gui/lmb.png")
local wavedisplay_bg = Material("effects/ar2_altfire1")
local wavedisplay_bg2 = Material("effects/splashwake1")
local wavedisplay_bg3 = Material("effects/splashwake3")
local mat_selected = Material("vgui/spawnmenu/hover")

local HUD = {
	StatusStrings = {
		[WAVE_WAITING] = "Waiting",
		[WAVE_ACTIVE] = "Active",
		[WAVE_POST] = "Finished",
	},

	Colours = {
		["Main"] = Color(35, 35, 35, 200),
		["Core"] = Color(121, 0, 185),
		["Health"] = Color(136, 181, 55),
		["Overheal"] = Color(68, 152, 208),
		["Ammo"] = Color(193, 111, 46),
		["Damage"] = Color(255, 75, 75),
	},

	HiddenElements = {
		["CHudHealth"] = true,
		["CHudAmmo"] = true,
		["CHudSecondaryAmmo"] = true,
		["CHudBattery"] = true,
		["CHudWeaponSelection"] = true,
	},
}

local function CanDraw(element)
	return hook.Run("HUDShouldDraw", element) ~= false
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

		if IsValid(wep) and wep.DrawAmmo ~= false then
			local ammo = math.max(0, wep:Clip1())
			local max_ammo = wep:GetMaxClip1()
			local total_ammo = ply:GetAmmoCount(wep:GetPrimaryAmmoType())

			local bw, bh = sw * 0.25, 32
			local bx, by = sw - 10 - bw, sh - bh - 10

			surface.SetDrawColor(HUD.Colours.Main)
			surface.DrawRect(bx, by, bw, bh)

			-- If we used the same lerp function for every weapon we'd get
			-- a useless bar when switching from a full clip to a used clip.
			wep.m_PercentLerp = wep.m_PercentLerp or PercentLerp(0.5, 0.25, true)

			local p = math.min(1, ammo / max_ammo)
			local lp = wep.m_PercentLerp(ammo, max_ammo)

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

	CoreHealth = function(ply, sw, sh)
		local core = GAMEMODE.Building_Core
		if not core:IsValid() then return end

		local hp = math.max(0, core:Health())
		local max_hp = core:GetMaxHealth()

		local bw, bh = sw * 0.25, 32
		local bx, by = sw * 0.5 - bw * 0.5, sh - bh - 10

		surface.SetDrawColor(HUD.Colours.Main)
		surface.DrawRect(bx, by, bw, bh)

		local p = math.min(1, hp / max_hp)
		local lp = core_lerp(hp, max_hp)

		local x_offset = bw - bw * lp
		x_offset = x_offset * 0.5

		surface.SetDrawColor(HUD.Colours.Damage)
		surface.DrawRect(bx + x_offset, by, bw * lp, bh)

		x_offset = bw - bw * p
		x_offset = x_offset * 0.5

		surface.SetDrawColor(HUD.Colours.Core)
		surface.DrawRect(bx + x_offset, by, bw * p, bh)

		draw.SimpleText(string.format("Core: %i", hp), "HUD.Status", bx + bw * 0.5, by + bh * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end,

	BossHealth = function(ply, sw, sh)
	end,

	Currency = function(ply, sw, sh)
		draw.SimpleText(string.format("$%s", string.Comma(math.floor(currency_lerp(ply:GetCurrency())))), "HUD.Status", sw / 2, sh * 0.6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end,

	WaveDisplay = function(ply, sw, sh)
		local num = GAMEMODE:GetWaveNumber()
		local core = GAMEMODE.Building_Core
		local c_col = color_white
		local alive = false
		if core and IsValid(core) then
			local n = core:Health()
			if n > 0 then
				alive = true
				c_col = HSVToColor(n / 5, 1,1)
			end
			if wavedisplay_core_hp ~= n then
				local delta = math.abs(n - wavedisplay_core_hp)
				wavedisplay_core_hp = n
				local p = (wavedisplay_core_shakestart - CurTime()) / 2
				if p > 0 then
					wavedisplay_core_shakespeed = math.max(wavedisplay_core_shakespeed * p, math.Clamp(delta / 100, 1, 4))
				else
					wavedisplay_core_shakespeed = math.Clamp(delta / 100, 1, 4)
				end
				wavedisplay_core_shakestart = CurTime() + 2
			end
		end
		if alive then
			local x,y = sw - 100, 70
			if wavedisplay_core_shakestart > CurTime() then
				local p = (wavedisplay_core_shakestart - CurTime()) ^ 1.8 * math.pi
				x = x + math.sin(p * wavedisplay_core_shakespeed) * wavedisplay_core_shakespeed * p * 0.5
			end
			surface.SetDrawColor( c_col )
			surface.SetMaterial(wavedisplay_bg2)
			surface.DrawTexturedRectRotated(x, y, 100, 100, CurTime() * - 44)
			surface.SetMaterial(wavedisplay_bg3)
			surface.DrawTexturedRectRotated(x, y, 80, 80, CurTime() * 34)

			surface.SetMaterial(wavedisplay_bg)
			surface.SetDrawColor(color_white)
			surface.DrawTexturedRect(x - 50, y - 50, 100, 100)
		end
		draw.DrawText("WAVE", "HUD.WaveDisplay", sw - 100, 30, color_white, TEXT_ALIGN_CENTER)
		draw.DrawText(num, "HUD.WaveDisplayNumber", sw - 100, 50, color_white, TEXT_ALIGN_CENTER)
	end,

	WeaponSelect = function(ply, sw, sh)
		GAMEMODE:WeaponSelect(ply, sw, sh)
	end,

	TargetID = function(lply, sw, sh)
		local aimvec = lply:GetAimVector()
		local shootpos = lply:GetShootPos()

		local trace_line = {}
		local eye_trace = lply:GetEyeTrace()

		for i, ply in ipairs(player.GetAll()) do
			if ply == lply then goto CONTINUE end

			local pos = ply:GetPos() + ply:OBBCenter()

			util.TraceLine({
				start = shootpos,
				endpos = pos,
				filter = lply,
				mask = MASK_SHOT,
				output = trace_line,
			})

			PrintTable(trace_line)
			if trace_line.Entity ~= ply then goto CONTINUE end

			local delta = pos - shootpos
			delta:Normalize()

			local dot = aimvec:Dot(delta)
			dot = math.deg(math.acos(dot))

			if eye_trace.Entity ~= ply and dot >= 10 then goto CONTINUE end

			pos = pos:ToScreen()

			local _, th = draw.SimpleText(ply:Nick(), "HUD.TargetID", pos.x, pos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(language.GetPhrase(GAMEMODE.PlayerClasses[ply:GetPlayerClass()]), "HUD.TargetID", pos.x, pos.y + th, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			if lply:GetPlayerClass() == CLASS_HEALER then
				local hp = ply:Health()
				local max_hp = ply:GetMaxHealth()

				ply.m_HealthLerp = ply.m_HealthLerp or PercentLerp(0.5, 0.25, true)

				local bw, bh = 150, 15
				local bx, by = pos.x, pos.y + th * 2 + 5

				surface.SetDrawColor(35, 35, 35, 200)
				surface.DrawRect(bx - bw * 0.5, by, bw, bh)

				local p = math.Clamp(hp / max_hp, 0, 1)
				local lp = ply.m_HealthLerp(hp, max_hp)

				local x_offset = bw - bw * lp
				x_offset = x_offset * 0.5

				surface.SetDrawColor(255, 75, 75)
				surface.DrawRect(bx - bw * 0.5 + x_offset, by, bw * lp, bh)

				x_offset = bw - bw * p
				x_offset = x_offset * 0.5

				surface.SetDrawColor(136, 181, 55)
				surface.DrawRect(bx - bw * 0.5 + x_offset, by, bw * p, bh)
			end

			::CONTINUE::
		end
	end,
}

HUD.Wave = {
	Status = function(ply, sw, sh)
		if GAMEMODE.m_WaveStatus == WAVE_POST then
			local time_left = math.max(0, GAMEMODE.m_NextWaveStart - CurTime())
			draw.SimpleText(string.format("%s until next wave", string.NiceTime(time_left)), "HUD.VoteStatus", sw * 0.5, sh * 0.25, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end,

	Vote = function(ply, sw, sh)
		if not GAMEMODE.m_VoteStarted then return end

		local vote_length = GAMEMODE.m_VoteLength
		local start_time = GAMEMODE.m_VoteStartTime
		local end_time = start_time + vote_length
		local time_left = end_time - CurTime()

		local tx, ty = sw * 0.5, sh * 0.25

		if GAMEMODE.m_VoteType == VOTE_TYPE_CORE then
			local w, h = draw.SimpleText("Choose your Core location", "HUD.VoteStatus", tx, ty, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(left_mouse_indicator)
				surface.DrawTexturedRect(tx - w * 0.5 - h, ty, h, h)
			render.PopFilterMag()

			ty = ty + h
		elseif GAMEMODE.m_VoteType == VOTE_TYPE_WAVE then
			local bind = input.LookupBinding("gm_showspare2")
			local w, h = draw.SimpleText(string.format("Press %s to start waves", bind), "HUD.VoteStatus", tx, ty, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			ty = ty + h + 8

			local players = player.GetAll()
			local player_count = #players

			local x_offset = (player_count - 1) * 64 * 0.5 + (player_count - 1) * 10 * 0.5

			for i, ply in ipairs(players) do
				local avatar = ply:GetAvatar()

				if IsValid(avatar) then
					local x_pos = sw * 0.5 + math.floor(((i - 1) * 64 - x_offset - 32) + ((i - 1) * 10))

					if vote_info.Voters[ply] then
						surface.SetDrawColor(255, 255, 255)
						surface.SetMaterial(mat_selected)
						surface.DrawTexturedRect(x_pos - 6, ty - 6, 64 + 12, 64 + 12)
					end

					avatar:SetPos(x_pos, ty)
					avatar:SetSize(64, 64)
					avatar:PaintManual()
				end
			end

			ty = ty + 64 + 8
		end

		if time_left >= 0 then
			local _, h = draw.SimpleText(string.format("%s left", string.NiceTime(time_left)), "HUD.VoteStatus", tx, ty, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			ty = ty + h
		end
	end,
}

function GM:HUDPaint()
	local ply = LocalPlayer()
	local sw, sh = ScrW(), ScrH()

	if CanDraw("HUD.Wave") then
		if CanDraw("HUD.Wave.Status") then
			HUD.Wave.Status(ply, sw, sh)
		end

		if CanDraw("HUD.Wave.Vote") then
			HUD.Wave.Vote(ply, sw, sh)
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

			if CanDraw("HUD.Status.WeaponSelect") then
				HUD.Status.WeaponSelect(ply, sw, sh)
			end

			if CanDraw("HUD.Status.Currency") then
				HUD.Status.Currency(ply, sw, sh)
			end
		end

		if CanDraw("HUD.Status.WaveDisplay") then
			HUD.Status.WaveDisplay(ply, sw, sh)
		end

		if CanDraw("HUD.Status.CoreHealth") then
			HUD.Status.CoreHealth(ply, sw, sh)
		end

		if CanDraw("HUD.Status.BossHealth") then
			HUD.Status.BossHealth(ply, sw, sh)
		end

		if CanDraw("HUD.Status.TargetID") then
			HUD.Status.TargetID(ply, sw, sh)
		end
	end
end

function GM:HUDShouldDraw(element)
	return not HUD.HiddenElements[element]
end
