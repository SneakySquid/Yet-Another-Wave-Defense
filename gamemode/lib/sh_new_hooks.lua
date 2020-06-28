
-- Reload support
hook.Add("InitPostEntity", "yawd.init", function()
    YAWD_INITPOSTENTITY = true
    hook.Run("YAWDPostEntity")
end)
if YAWD_INITPOSTENTITY then
    timer.Simple(1, function()
        hook.Run("YAWDPostEntity")
    end)
end