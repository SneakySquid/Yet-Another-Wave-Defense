do
	surface.CreateFont("HUD.WaveStatus", {
		font = "Tahoma",
		size = 32,
		weight = 1500,
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
end

local vote_info = GM.VoteInfo

local core_lerp = PercentLerp(0.5, 0.25, true)
local health_lerp = PercentLerp(0.5, 0.25, true)
local overheal_lerp = PercentLerp(0.5, 0.25, true)
local currency_lerp = TargetLerp(0, 0.5)

local left_mouse_indicator = Material("gui/lmb.png")

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
		["CHudWeaponSelection"] = true
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
		draw.SimpleText(string.format("$%i", currency_lerp(ply:GetCurrency())), "HUD.Status", sw / 2, sh * 0.6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
}

HUD.Wave = {
	Status = function(ply, sw, sh)
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
		end

		if CanDraw("HUD.Status.Currency") then
			HUD.Status.Currency(ply, sw, sh)
		end

		if CanDraw("HUD.Status.CoreHealth") then
			HUD.Status.CoreHealth(ply, sw, sh)
		end

		if CanDraw("HUD.Status.BossHealth") then
			HUD.Status.BossHealth(ply, sw, sh)
		end
	end
end

function GM:HUDShouldDraw(element)
	return not HUD.HiddenElements[element]
end
