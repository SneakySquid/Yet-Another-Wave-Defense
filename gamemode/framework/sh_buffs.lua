local ENTITY = FindMetaTable("Entity")

if SERVER then
	util.AddNetworkString("Buff.Update")
end

if CLIENT then
	net.Receive("Buff.Update", function()
		local enum = net.ReadUInt(32)
		local target = net.ReadEntity()
		local applied = net.ReadBool()

		if applied then
			target:AddBuff(enum)
		else
			target:RemoveBuff(enum)
		end
	end)
end

function ENTITY:GetBuffLookup()
	self.Buffs = self.Buffs or {}
	return self.Buffs
end

function ENTITY:HasBuff(buff)
	return bit.band(self:GetBuffs(), buff) == buff
end

function ENTITY:AddBuff(enum)
	if self:HasBuff(enum) then return false end
	self:SetBuffs(bit.bor(self:GetBuffs(), enum))

	local buff = Buff.Create(enum)
	if not buff then return false end

	buff:SetTarget(self)
	buff:SetApplied(true)

	buff:Initialize()
	buff:OnApplied(self)

	self.Buffs = self.Buffs or {
		Lookup = {},
		Current = {},
	}

	local i = table.insert(self.Buffs.Current, buff)
	self.Buffs.Lookup[enum] = i

	if SERVER then
		net.Start("Buff.Update")
			net.WriteUInt(enum, 32)
			net.WriteEntity(self)
			net.WriteBool(true)
		net.Broadcast()
	end

	return true
end

function ENTITY:RemoveBuff(enum)
	if not self:HasBuff(enum) then return false end
	self:SetBuffs(bit.band(self:GetBuffs(), bit.bnot(enum)))

	local buff = Buff.Create(enum)
	if not buff then return false end

	buff:SetApplied(false)
	buff:OnRemoved(self)

	self.Buffs = self.Buffs or {
		Lookup = {},
		Current = {},
	}

	table.remove(self.Buffs.Current, self.Buffs.Lookup[enum])
	self.Buffs.Lookup[enum] = nil

	if SERVER then
		net.Start("Buff.Update")
			net.WriteUInt(enum, 32)
			net.WriteEntity(self)
			net.WriteBool(false)
		net.Broadcast()
	end

	return true
end

local BUFF = {}
BUFF.__index = BUFF

AccessorFunc(BUFF, "m_Buff", "Buff")
AccessorFunc(BUFF, "m_Target", "Target")
AccessorFunc(BUFF, "m_Applied", "Applied")

function BUFF:IsValid()
	return self.m_Applied and self.m_Target:IsValid()
end

function BUFF:Initialize()
end

function BUFF:Think()
end

function BUFF:DrawEffect()
end

function BUFF:OnApplied(target)
end

function BUFF:OnRemoved(target)
end

Buff = {}
Buff.Registered = {}

function Buff.New()
	return setmetatable({}, BUFF)
end

local BuffLookup = {}
function Buff.Register(buff)
	local i = table.insert(Buff.Registered, buff)
	local enum = bit.lshift(1, i - 1)

	BuffLookup[enum] = i
	buff:SetBuff(enum)

	return enum
end

function Buff.Get(enum)
	local i = BuffLookup[enum]
	if not i then return false end

	return Buff.Registered[i]
end

function Buff.Create(enum)
	local buff = Buff.Get(enum)
	if not buff then return false end

	buff = setmetatable({}, {__index = buff})

	hook.Add("Think", buff, buff.Think)
	hook.Add("PostDrawEffects", buff, buff.DrawEffect)

	return buff
end

HandleFolder("framework/buffs")
