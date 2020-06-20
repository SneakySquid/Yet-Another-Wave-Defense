
surface.CreateFont( "yawd_hudoutline", {
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

hook.Add("HUDPaint", "yawd.hud", function()
    local wave = GAMEMODE.GetWaveNumber()
    local wave_started = GAMEMODE.HasWaveStarted()

    -- Draw wave number
    surface.SetTextColor(255,255,255)
    surface.SetFont("yawd_hudoutline")
    local txt = "Wave: " .. wave
    local tw,th = surface.GetTextSize(txt)
    surface.SetTextPos(ScrW() - tw / 2 - 100, 20)
    surface.DrawText(txt)
end)