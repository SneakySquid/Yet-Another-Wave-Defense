surface.CreateFont("HUD.WaveOutlined", {
	font = "Arial",
	size = 22,
	weight = 1500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	shadow = false,
	additive = false,
	outline = true,
})

local Statuses = {
	[WAVE_WAITING] = "Waiting",
	[WAVE_ACTIVE] = "Active",
	[WAVE_POST] = "Finished",
}

function GM:WaveStatus(ply, w, h)
	if not hook.Run("HUDShouldDraw", "HUD.WaveStatus") then return end

	local wave_no = self:GetWaveNumber()
	local wave_stat = Statuses[self:GetWaveStatus()]

	local _, th = draw.SimpleText(string.format("Wave: %i", wave_no), "HUD.WaveOutlined", w - 20, 20, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText(string.format("Status: %s", wave_stat), "HUD.WaveOutlined", w - 20, 20 + th, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

function GM:HUDPaint()
	local ply = LocalPlayer()
	local w, h = ScrW(), ScrH()

	self:WaveStatus(ply, w, h)
end
