if SERVER then util.AddNetworkString("Element.ShockBeam") end

local ELEMENT = Element.New()

function ELEMENT:Initialize()
	self:SetDamageType(DMG_SHOCK)

	self:SetWeakAgainst(ELEMENT_GRASS, ELEMENT_ROCK, ELEMENT_SHOCK)
	self:SetStrongAgainst(ELEMENT_AIR, ELEMENT_WATER)
	self:SetImmuneAgainst(0)
end

function ELEMENT:OnInteractWith(target, other, dmg_info)
	if not target:HasDebuff(DEBUFF_SOAKED) then return end

	local nearby_ents = ents.FindInSphere(dmg_info:GetDamagePosition(), 60)
	local found_ents, found_count = {}, 0

	for i, ent in ipairs(nearby_ents) do
		if ent:GetClass() == "yawd_npc_base" and ent:HasDebuff(DEBUFF_SOAKED) then
			local shock_dmg = DamageInfo()
			local center = ent:GetPos() + ent:OBBCenter()

			shock_dmg:SetDamageType(DMG_SHOCK)
			shock_dmg:SetDamage(35)

			shock_dmg:SetAttacker(dmg_info:GetAttacker())
			shock_dmg:SetInflictor(ent)

			shock_dmg:SetDamagePosition(center)

			ent:TakeDamageInfo(shock_dmg)

			found_count = found_count + 1
			found_ents[found_count] = {ent, center}
		end
	end

	if found_count ~= 0 then
		net.Start("Element.ShockBeam")
			net.WriteEntity(target)
			net.WriteUInt(found_count, 8)

			for i, info in ipairs(found_ents) do
				net.WriteEntity(ent)
			end
		net.Broadcast()
	end
end

if CLIENT then
	local beams = {}
	local spark_col = Color(191, 0, 255, 255, 150)
	local lightningMaterial = Material("sprites/lgtning")

	net.Receive("Element.ShockBeam", function()
		local start_ent = net.ReadEntity()

		for i = 1, net.ReadUInt(8) do
			local end_ent = net.ReadEntity()
			table.insert(beams, {start_ent, end_ent, CurTime()})
		end
	end)

	hook.Add("PreDrawTranslucentRenderables", "Element.DrawShockBeams", function(a, b)
		if a or b or #beams == 0 then return end

		render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
			render.SetMaterial(lightningMaterial)

			for i = #beams, 1, -1 do
				local info = beams[i]

				local start_ent = info[1]
				if not start_ent:IsValid() then
					table.remove(beams, i)
					return
				end

				local end_ent = info[2]
				if not end_ent:IsValid() then
					table.remove(beams, i)
					return
				end

				local life_start = info[3]
				local uv = math.random()

				local start_pos = start_ent:GetPos() + start_ent:OBBCenter()
				local end_pos = end_ent:GetPos() + end_ent:OBBCenter()

				local diff = end_pos - start_pos
				local mag = diff:Length()
				local dir = diff:GetNormalized()

				render.StartBeam(5)
					render.AddBeam(start_pos, 20, uv * 1, spark_col)
					render.AddBeam(start_pos + dir * (mag * 0.25), 20, uv * 2, spark_col)
					render.AddBeam(start_pos + dir * (mag * 0.50), 20, uv * 3, spark_col)
					render.AddBeam(start_pos + dir * (mag * 0.75), 20, uv * 4, spark_col)
					render.AddBeam(end_pos, 20, uv * 5, spark_col)
				render.EndBeam()

				if CurTime() > life_start + 0.25 then
					table.remove(beams, i)
				end
			end
		render.OverrideBlend(false)
	end)
end

ELEMENT_SHOCK = Element.Register(ELEMENT)
