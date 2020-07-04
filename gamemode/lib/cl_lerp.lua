function LerpCalc(delay, time, revert)
	local old, new, start = 0, 0, 0

	delay = delay or 0
	time = time or 1

	return function(current, max)
		local ctime = CurTime()

		if revert and current > new then
			new = current
			start = 0
		elseif new ~= current then
			old = Lerp((ctime - start) / time, old, new)
			new = current
			start = ctime + delay
		elseif ctime - start >= time then
			old = current
		end

		local l = Lerp((ctime - start) / time, old, new)
		local p = math.Clamp(l / max, 0, 1)

		return p
	end
end
