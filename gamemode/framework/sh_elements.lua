local ENTITY = FindMetaTable("Entity")

function ENTITY:SetElement(element)
	self.m_Element = element
end

function ENTITY:GetElement()
	return self.m_Element or ELEMENT_NONE
end

local ELEMENT = {}
ELEMENT.__index = ELEMENT

AccessorFunc(ELEMENT, "m_Element", "Element") -- Set internally, the element enum of the ELEMENT object.
AccessorFunc(ELEMENT, "m_DamageType", "DamageType") -- The type of damage the element does, DMG_GENERIC by default.
AccessorFunc(ELEMENT, "m_WeakAgainst", "WeakAgainst") -- A bitflag/table of elements that the ELEMENT is weak against. (Deals half damage, takes double damage.)
AccessorFunc(ELEMENT, "m_StrongAgainst", "StrongAgainst") -- A bitflag/table of elements that the ELEMENT is strong against. (Deals double damage, takes half damage.)
AccessorFunc(ELEMENT, "m_ImmuneAgainst", "ImmuneAgainst") -- A bitflag/table of elements that the ELEMENT is immune against. (Deals normal damage, takes no damage.)

local function BitflagGetter(args)
	local bitflag = 0

	if not args[2] and isnumber(args[1]) then
		bitflag = args[1]
	elseif #args > 1 then
		bitflag = bit.bor(unpack(args))
	end

	return bitflag
end

function ELEMENT:SetWeakAgainst(...)
	self.m_WeakAgainst = BitflagGetter({...})
end

function ELEMENT:SetStrongAgainst(...)
	self.m_StrongAgainst = BitflagGetter({...})
end

function ELEMENT:SetImmuneAgainst(...)
	self.m_ImmuneAgainst = BitflagGetter({...})
end

function ELEMENT:DamageInfo()
	local dmg_info = DamageInfo()

	dmg_info:SetDamageType(self.m_DamageType)
	dmg_info:SetDamageCustom(self.m_Element)

	return dmg_info
end

function ELEMENT:Initialize()
	self:SetDamageType(DMG_GENERIC)

	self:SetWeakAgainst(0)
	self:SetStrongAgainst(0)
	self:SetImmuneAgainst(0)
end

function ELEMENT:IsWeakAgainst(other)
	return bit.band(self.m_WeakAgainst, other.m_Element) == self.m_Element
end

function ELEMENT:OnInteractWith(target, element, dmg_info)
end

Element = {}
Element.Registered = {}

function Element.New()
	return setmetatable({}, ELEMENT)
end

local ElementLookup = {}
function Element.Register(element)
	local i = table.insert(Element.Registered, element)
	local enum = bit.lshift(1, i - 1)

	ElementLookup[enum] = i
	element:SetElement(enum)

	return enum
end

function Element.Get(enum)
	local i = ElementLookup[enum]
	if not i then return false end

	return Element.Registered[i]
end

function Element.DamageInfo(enum)
	local element = Element.Get(enum)
	if not element then return end

	local dmg_info = DamageInfo()
	dmg_info:SetDamageCustom(element.m_Element)

	return dmg_info
end

do
	ELEMENT_NONE = Element.Register(Element.New())

	HandleFolder("framework/elements")

	for i, element in ipairs(Element.Registered) do
		element:Initialize()
	end

	DebugMessage(string.format("Finished initializing %i elements.", #Element.Registered))
end

function GM:EntityTakeDamage(target, dmg_info)
	local dmg_type = dmg_info:GetDamageCustom()
	if not dmg_type or dmg_type == 0 then return end

	local element = Element.Get(dmg_type)
	if not element then return end

	local targets_element = target:GetElement()

	if bit.band(element.m_ImmuneAgainst, targets_element) == targets_element then
		dmg_info:SetDamage(0)
	else
		if bit.band(element.m_StrongAgainst, targets_element) == targets_element then
			dmg_info:ScaleDamage(2)
		end

		if bit.band(element.m_WeakAgainst, targets_element) == targets_element then
			dmg_info:ScaleDamage(0.5)
		end
	end

	element:OnInteractWith(target, targets_element, dmg_info)
end
