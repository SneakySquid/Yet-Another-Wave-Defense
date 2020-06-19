--[[
    Functions:
        SV       GM.StartWave()
        SV       GM.EndWave()
        SV       GM.SetWaveNumber( int )
        SH  bool GM.HasWaveStarted()
        SH  int  GM.GetWaveNumber()
    Hooks:
        SH  yawd_wavestart
        SH  yawd_waveend
]]
local wave_started = false
local wave = 0
function GM.HasWaveStarted()
    return wave_started
end
function GM.GetWaveNumber()
    return wave
end
if SERVER then
    util.AddNetworkString("yawd_wave")
    function GM.StartWave()
        if wave_started then return end
        wave_started = true
        wave = wave + 1
        hook.Run("yawd_wavestart")
        net.Start("yawd_wave")
            net.WriteBit(false) -- Not a full update
            net.WriteBit(true) -- InWave
        net.Broadcast()
    end
    function GM.EndWave()
        if not wave_started then return end
        wave_started = false
        hook.Run("yawd_waveend")
        net.Start("yawd_wave")
            net.WriteBit(false) -- Not a full update
            net.WriteBit(false) -- InWave
        net.Broadcast()
    end
    function GM.SetWaveNumber( num )
        wave = num
        net.Start("yawd_wave")
            net.WriteBit(true) -- full update
            net.WriteBit(wave_started) -- InWave
            net.WriteUInt(wave, 32) -- wave
        net.Broadcast()
    end
    -- Tell the client the wave-data
    net.Receive("yawd_wave", function(len,ply)
        net.Start("yawd_wave")
            net.WriteBit(true) -- full update
            net.WriteBit(wave_started) -- InWave
            net.WriteUInt(wave, 32) -- wave
        net.Send(ply)
    end)
else
    -- Ask the server the wave-data
    hook.Add("InitPostEntity", "Init_Yawd_Wave", function()
        net.Start("yawd_wave")
        net.SendToServer()
    end)
    -- Wave net
    net.Receive("yawd_wave", function(len)
        if net.ReadBit() then -- Full update?
            wave_started = net.ReadBit()
            wave = net.ReadUInt(32) -- wave
        else
            wave_started = net.ReadBit()
            if wave_started then
                hook.Run("yawd_wavestart")
            else
                hook.Run("yawd_waveend")
            end
        end 
    end)
end