local ENTITY = FindMetaTable("Entity")

if SERVER then
	util.AddNetworkString("Debuff.Update")
end

if CLIENT then
	net.Receive("Debuff.Update", function()
		local enum = net.ReadUInt(32)
		local target = net.ReadEntity()
		local applied = net.ReadBool()
		if not IsValid(target) then return end
		if applied then
			target:AddDebuff(enum)
		else
			target:RemoveDebuff(enum)
		end
	end)
end

function ENTITY:GetDebuffLookup()
	self.Debuffs = self.Debuffs or {}
	return self.Debuffs
end

function ENTITY:HasDebuff(debuff)
	return bit.band(self:GetDebuffs(), debuff) == debuff
end

function ENTITY:AddDebuff(enum)
	if self:HasDebuff(enum) then return false end
	self:SetDebuffs(bit.bor(self:GetDebuffs(), enum))

	local debuff = Debuff.Create(enum)
	if not debuff then return false end

	debuff:SetTarget(self)
	debuff:SetApplied(true)

	debuff:Initialize()
	debuff:OnApplied(self)

	self.Debuffs = self.Debuffs or {
		Lookup = {},
		Current = {},
	}

	local i = table.insert(self.Debuffs.Current, debuff)
	self.Debuffs.Lookup[enum] = i

	if SERVER then
		net.Start("Debuff.Update")
			net.WriteUInt(enum, 32)
			net.WriteEntity(self)
			net.WriteBool(true)
		net.Broadcast()
	end

	return debuff
end

function ENTITY:RemoveDebuff(enum)
	if not self:HasDebuff(enum) then return false end
	self:SetDebuffs(bit.band(self:GetDebuffs(), bit.bnot(enum)))

	self.Debuffs = self.Debuffs or {
		Lookup = {},
		Current = {},
	}

	local debuff = table.remove(self.Debuffs.Current, self.Debuffs.Lookup[enum])
	self.Debuffs.Lookup[enum] = nil

	if not debuff then return end

	debuff:SetApplied(false)
	debuff:OnRemoved(self)

	hook.Remove("Think", debuff)
	if CLIENT then hook.Remove("PostDrawEffects", debuff) end

	if SERVER then
		net.Start("Debuff.Update")
			net.WriteUInt(enum, 32)
			net.WriteEntity(self)
			net.WriteBool(false)
		net.Broadcast()
	end

	return true
end

local DEBUFF = {}
DEBUFF.__index = DEBUFF

AccessorFunc(DEBUFF, "m_Debuff", "Debuff")
AccessorFunc(DEBUFF, "m_Target", "Target")
AccessorFunc(DEBUFF, "m_Applied", "Applied")
AccessorFunc(DEBUFF, "m_Attacker", "Attacker")

function DEBUFF:IsValid()
	return self.m_Applied and self.m_Target:IsValid()
end

function DEBUFF:Initialize()
end

function DEBUFF:Think()
end

function DEBUFF:DrawEffect()
end

function DEBUFF:OnApplied(target)
end

function DEBUFF:OnRemoved(target)
end

Debuff = {}
Debuff.Registered = {}

function Debuff.New()
	return setmetatable({}, DEBUFF)
end

local DebuffLookup = {}
function Debuff.Register(debuff)
	local i = table.insert(Debuff.Registered, debuff)
	local enum = bit.lshift(1, i - 1)

	DebuffLookup[enum] = i
	debuff:SetDebuff(enum)

	return enum
end

function Debuff.Get(enum)
	local i = DebuffLookup[enum]
	if not i then return false end

	return Debuff.Registered[i]
end

function Debuff.Create(enum)
	local debuff = Debuff.Get(enum)
	if not debuff then return false end

	debuff = setmetatable({}, {__index = debuff})

	hook.Add("Think", debuff, debuff.Think)

	if CLIENT then
		hook.Add("PostDrawEffects", debuff, debuff.DrawEffect)
	end

	return debuff
end

HandleFolder("framework/debuffs")
