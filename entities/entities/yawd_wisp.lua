
--[[
	A building
]]
AddCSLuaFile()


ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.DisableDuplicator = true

local wisp_speed = 15
local wisp_joints = 6
local wisp_distance = 100

ENT.Model = Model( "models/Gibs/HGIBS.mdl" )
function ENT:Initialize()
	if SERVER then
		SafeRemoveEntity(self)
	end
	self:SetModel( self.Model )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_BBOX )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	local n = wisp_distance * wisp_joints
	self:SetRenderBounds(Vector(0,0,0),Vector(0,0,0),Vector(n,n,n))
	self.trail = {}
end

if SERVER then return end

function ENT:SetPath( path )
	if not path or type(path) == "boolean" then SafeRemoveEntity(self) return false end
	self:SetPos( path.start  + Vector(0,0,40) )
	self.path = path
	self.path_id = #path - 1
	self.active = true
	for i = 1, wisp_joints do
		self.trail[i] = self:GetPos()
	end
end

function ENT:StopPath()
	self.path = nil
	self.active = false
end

function ENT:Think()
	if not self.path then return end
	if not self.active then return end
	local goal = self:GetPos()
	if self.path_id < 1 then
		if self.trail[wisp_joints]:Distance(self:GetPos()) < 5 then
			self:SetPos(self.path.start)
			self:StopPath()
			return
		end
	elseif self.path_id == 1 then
		goal = self.path[1] + Vector(0,0,40)
	else
		goal = self.path[self.path_id]:GetPos() + Vector(0,0,40)
	end
	local dis = self:GetPos():Distance(goal)
	local a = (goal - self:GetPos()):Angle()
	self:SetRenderAngles(a)
	local speed = wisp_speed * FrameTime() * 50
	if dis <= wisp_speed then -- We reached the next point
		self:SetPos(goal)
		self.path_id = self.path_id - 1
	else
		self:SetPos( self:GetPos() + a:Forward() * speed)
	end
	-- Move the trail
	for i = 1, wisp_joints do
		local cur = self.trail[i]
		local goal = self.trail[i - 1] or self:GetPos()
		local dis = goal:Distance(cur)
		--if dis < wisp_distance then continue end
		local dir = (cur - goal):GetNormalized()
		self.trail[i] = goal + dir * math.min(dis - speed / 2, dis, wisp_distance)
	end
end

local color = Color(255,255,255,55)
function ENT:Draw()
	--self:DrawModel()
	if not self.active or not self.trail then return end
	render.SetMaterial(Material("sprites/physbeama"))
	render.StartBeam(11)
	local n = SysTime() * -6 % 1
	local r = math.pi * 1 / wisp_joints
	for i = 0, wisp_joints do
		local p = self.trail[i] or self:GetPos()
		local w = math.sin(r * i)
		color.a = w * 105
		render.AddBeam(p, w * 20, i + n, color )
	end
	render.EndBeam()
end

function ENT:IsActive()
	return self.active
end

-- So clientside entities don't support EmitSound or CreateSound.
local wisps,wisp_t = {},0
local snd
hook.Add("Think", "yawd.wispsnd", function()
	if wisp_t <= CurTime() then
		wisp_t = CurTime() +5
		wisps = ents.FindByClass("yawd_wisp")
	end
	local c_dis,cur = 600
	for k,v in ipairs(wisps) do
		if not IsValid(v) then continue end
		local dis = v:GetPos():Distance(LocalPlayer():GetPos())
		if dis < c_dis then
			cur = v
			c_dis = dis
		end
	end
	if c_dis > 600 then cur = nil end
	local vol = 1 - math.min(1, c_dis / 600)
	if vol <= 0 then cur = nil end
	if not cur and snd then
		snd:Stop()
		snd = nil
	elseif cur then
		if not snd then
			snd = CreateSound( LocalPlayer(), "ambient/atmosphere/cargo_hold2.wav")
			snd:PlayEx(vol, 110)
		end
		snd:ChangeVolume(vol)
	end
end)