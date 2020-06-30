function GM:Accessor(name, default, callback)
	local varname = "m_" .. name

	self["Get" .. name] = function(self)
		return self[varname]
	end

	self["Set" .. name] = function(self, v)
		if (default ~= nil and v == nil) then
			v = default
		end

		if (self[varname] ~= v) then
			if (isfunction(callback)) then
				v = callback(self, self[varname], v) or v
			end

			self[varname] = v
		end
	end

	self[varname] = default
end
