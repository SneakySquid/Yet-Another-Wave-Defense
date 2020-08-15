AddCSLuaFile()

ENT.Type = "nextbot"
ENT.Base = "base_nextbot"

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

local MOVE_HEIGHT_EPSILON = 0.0625
local StepHeight = 18

AccessorFunc(ENT, "m_Target", "Target") -- This should be an entity
AccessorFunc(ENT, "m_MaxSpeed", "MaxSpeed") -- max velocity in m/s
AccessorFunc(ENT, "m_Controller", "Controller") -- Controller object, set with ENT:InitController
AccessorFunc(ENT, "m_HULLTYPE", "HULLType") -- Max steering force in m/s
AccessorFunc(ENT, "m_InJump", "InJump") -- Is in jump

-- "Talk" functions. This will ensure only one can be played at a time.
function ENT:SpeakSnd( snd_or_tab, ... )
	if self._sndspeak then
		self:StopSound( self._sndspeak )
	end
	if type(snd_or_tab) == "table" then
		self._sndspeak = table.Random(snd_or_tab)
	else
		self._sndspeak = snd_or_tab
	end
	self._sndspeak_d = SoundDuration( self._sndspeak ) + CurTime() + 1
	self:EmitSound(self._sndspeak, ...)
end
-- Same as ENT:SpeakSnd, but won't run if there is currently another one playing.
function ENT:SpeakSndNoSpam( snd_or_tab, ... )
	if (self._sndspeak_d or 0) > CurTime() then return end
	self:SpeakSnd( snd_or_tab, ... )
end
-- Modifiles the speed (For traps and other effects)
function ENT:SetSpeedMult( mul )
	self.speedMul = mul or 1
	self.loco:SetDesiredSpeed( self:GetMoveSpeed() )
end
-- Temp modifies the speed (For movment script)
function ENT:SetSpeedMultTemp( mul )
	if mul then
		self.speedMulTemp = mul
		self.loco:SetDesiredSpeed( mul )
	else
		self.speedMulTemp = nil
		self.loco:SetDesiredSpeed(self:GetMoveSpeed() )
	end
end
-- Returns the movespeed
function ENT:GetMoveSpeed()
	return (self:GetMaxSpeed() or 25) * (self.speedMulTemp or self.speedMul or 1)
end
-- Makes the nextbot become a ragdoll
local CUR_RAG = 0
local con = GetConVar( "yawd_max_ragdoll" )
function ENT:MakeRagdoll( duration )
	if CUR_RAG >= (con and con:GetInt() or 20) then return end 
	if self:Health() <= 0 then return end
	if self.e_Ragdoll then SafeRemoveEntity( self.e_Ragdoll) end
	local rag = ents.Create("prop_ragdoll")
	if not IsValid(rag) then return false end
	rag.NPC_OWNER = self
	rag:SetPos( self:GetPos() )
	rag:SetModel( self:GetModel() )
	rag:SetSkin( self:GetSkin() )
	for key, value in pairs(self:GetBodyGroups()) do
		rag:SetBodygroup(value.id, self:GetBodygroup(value.id))
	end
	rag:SetAngles(self:GetAngles())
	rag:SetColor(self:GetColor())
	rag:Spawn()
	rag:Activate()
	rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	CUR_RAG = CUR_RAG + 1
	function rag:OnTakeDamage( dmginfo )
		if not IsValid(self.NPC_OWNER) then return end
		self.NPC_OWNER:TakeDamageInfo( dmginfo )
	end
	if self.Weapon then
		self.Weapon:SetNoDraw(true)
	end
	self:SetRagdolled( true )
	self.e_Ragdoll = rag
	self.i_RagdollTime = CurTime() + (duration or 2)
	-- Overwrite jumping
	self.m_ForceMoving = nil
	self.m_ForceMovingt = nil
	self.m_ForceMovingd = nil
	-- Reset AI
	self:ResetBehavior()
	return rag
end
-- Makes the nextbot unragdoll
function ENT:UnRagdoll()
	-- Remove ragdoll
	CUR_RAG = math.max(0, CUR_RAG - 1)
	if self.e_Ragdoll and IsValid(self.e_Ragdoll) then
		self:SetPos(self.e_Ragdoll:GetPos() + Vector(0,0,4))
		SafeRemoveEntity( self.e_Ragdoll )
	end
	self.e_Ragdoll = nil
	self:SetRagdolled( false )
	-- Renable weapon
	if self.Weapon then
		self.Weapon:SetNoDraw(false)
	end
	-- Make the controller invalid, so it updates the goal and path.
	local controller = self:GetController()
	if not controller then return end
	controller:MakeInvalid()
	if self.NPC_DATA.ANIM_LAND then
		self:ResetSequence(self.NPC_DATA.ANIM_LAND)
		self:SetCycle( 0.01 )
		self:SetPlaybackRate( 0.01 )
	end
end
-- Makes the nextbot become a ragdoll and fly in a direction
function ENT:Fling( vel )
	if self:Health() <= 0 then return end
	if self.m_CantBePushed then return end
	local rag = self:MakeRagdoll()
	if not rag or not IsValid(rag) then return end
	local num = rag:GetPhysicsObjectCount()-1
	for i=0, num do
		local bone = rag:GetPhysicsObjectNum(i)
		if IsValid(bone) then
			local bp, ba = self:GetBonePosition(rag:TranslatePhysBoneToBone(i))
			if bp and ba then
				bone:SetPos(bp)
				bone:SetAngles(ba)
			end
			bone:SetVelocity(vel)
		end
	end
end
function ENT:SetCanBePushed( bool )
	self.m_CantBePushed = not bool
end
-- Gives the nextbot a weapon
function ENT:GiveWeapon(wep)
	local wep = ents.Create(wep)
	local pos = self:GetAttachment(self:LookupAttachment("anim_attachment_RH")).Pos
	wep:SetOwner(self)
	wep:SetPos(pos)
	wep:Spawn()
	wep:SetSolid(SOLID_NONE)
	wep:SetParent(self)

	wep:Fire("setparentattachment", "anim_attachment_RH")
	wep:AddEffects(EF_BONEMERGE)
	wep.m_YawdBlockPick = true
	self.Weapon = wep
end
hook.Add("PlayerCanPickupWeapon", "yawd_bot", function( ply, wep)
	if wep.m_YawdBlockPick then return false end
end)
-- Makes the nextbot shoot their weapon.
function ENT:ShootWeapon( target, bullet_data )
	if not IsValid(self.Weapon) then return false end
	aimcone = aimcone or 0.1
	local att = self.Weapon:LookupAttachment("muzzle")
	local shootPos
	if att > 0 then
		local t = self.Weapon:GetAttachment(att)
		shootPos = t.Pos
	else
		shootPos = self:GetPos()
	end
	local dir = (target:GetPos() - shootPos + target:OBBCenter()):GetNormalized()
	bullet_data = bullet_data or {}
		bullet_data.Num = Num or 1
		bullet_data.Src = shootPos
		bullet_data.Dir = dir
		bullet_data.Spread = Vector(aimcone , aimcone, 0)
		bullet_data.Tracer = tracer or 1
		bullet_data.Damage = dmg or 3
	self:FireBullets(bullet_data)
	return true
end
-- Returns a trace using the NPC's hull.
function ENT:TraceHull(From, To)
	return util.TraceHull({
		start = From,
		endpos = To,
		mins = self:OBBMins(),
		maxs = self:OBBMaxs(),
		mask = MASK_NPCSOLID_BRUSHONLY,
	})
end
-- Initializes the NPC
function ENT:Initialize()
	self:SetCustomCollisionCheck(true)
	-- leave these ones alone
	self:AddSolidFlags( FSOLID_NOT_STANDABLE )
	if CLIENT then
		NPC.ApplyFunctions(self, self:GetNPCType())
	end
	if SERVER then
		self:SetSolidMask(MASK_NPCSOLID_BRUSHONLY)
		local hp_boost = 1 + math.max(1, GAMEMODE:GetWaveNumber()) * .025
		local hp = (self.NPC_DATA.Health or 25) * hp_boost
		self:SetMaxHealth(hp)
		self:SetHealth(hp)
	--	self:SetModel("models/combine_soldier.mdl")
	--	self:PhysicsInit(SOLID_BBOX)
	--	self:SetSolid(SOLID_BBOX)
	--	self:SetMoveType(MOVETYPE_STEP )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )

	--	self:PhysWake()
		local physobj = self:GetPhysicsObject()
	--	physobj:SetDragCoefficient( 0.1 )
	--	physobj:EnableGravity(true)
	--	physobj:SetMaterial("gmod_ice")
		self.loco:SetStepHeight(50)
	end
	self:SetHULLType(self.NPC_DATA.HullType or PathFinder.FindEntityHULL( self ))
	self:InitController(Building.GetCore(), self.NPC_DATA.JumpDown or 0, self.NPC_DATA.JumpUp or 0)
	if self.NPC_DATA.HuntPlayer then
		self:HuntPlayers()
	end
	if self.NPC_DATA.Material then
		self:SetMaterial(e.NPC_DATA.Material)
	end
end
-- Resets the AI
function ENT:ResetBehavior()
	self:BehaveStart()
	self:SetSpeedMultTemp()
	self:SetSpeedMult( 1 )
	self:SetTarget(nil)
end
-- Creats the controller for the NPC.
function ENT:InitController(target, jump_down, jump_up)
	local controller = Controller.New(target:GetPos(), jump_down, jump_up)
	if controller then
		controller:SetTarget( target )
		local path = controller:RequestEntityPath(self, target:GetPos(), self.NPC_DATA.FuzzyAmount or 1, true)
		if path then
			--DebugMessage(string.format("Generated initial path for %s.", self))
			controller:SetPath(path)
		end
		self:SetController(controller)
		return true
	end
	return false
end
-- Creats and updates a path to said target. Returns a bool if unable to. True if reached, false if unreachable.
function ENT:CreatePathToTarget( target )
	if not target then target = Building.GetCore() end
	local controller = self:GetController()
	if not controller then return false end
	local new_path = controller:RequestEntityPath(self, target:GetPos() + target:OBBCenter(), self.NPC_DATA.FuzzyAmount or 1)
	if new_path then
		controller:SetTarget( target )
	end
	return new_path
end
-- Deletes the NPC and removes the HP from the core.
local function WentIntoCore(self)
	if CLIENT then return end
	local core = Building.GetCore()
	if IsValid(core) then
		local n = math.random(1,3)
		if n > 1 then n = n + 1 end
		core:EmitSound("ambient/machines/teleport" .. n .. ".wav", 120)
		core:TakeCoreDamage( self:GetMaxHealth() )
	end
	self.m_IgnoreMoney = true
	SafeRemoveEntity(self)
end
-- Gets called when the NPC reaches the end. Returns true if it is getting deleted.
function ENT:OnPathEnd()
	local controller = self:GetController()
	if not controller then SafeRemoveEntity(self) return true end -- No controller. Deleting.
	if IsValid(controller:GetTarget()) and controller:GetTarget():GetClass() == "yawd_building_core" then
		-- Reached the core
		WentIntoCore(self)
		return true
	else -- Go to the core
		local path = self:CreatePathToTarget()
		if type(path) == "boolean" then
			if path then -- We are already there.
				WentIntoCore(self)
				return true
			else
				DebugMessage(string.format("Failed to generate new path for %s to core.", self))
				if SERVER then
					self:Remove()
				end
				return true
			end
		end
	end
end
-- Sets the target to the given player, if they're reachable.
function ENT:TryHuntPlayer( ply )
	if not self:CreatePathToTarget( ply ) then
		ply.m_NoHunt = CurTime() + math.random(7, 14)
		return false
	end
	return true
end
-- Tries to hunt the nearest player.
function ENT:HuntPlayers()
	local c,d
	for k,v in ipairs( player.GetAll() ) do
		if not IsValid(v) or v:Health() <= 0 then continue end
		if (v.m_NoHunt or 0) >= CurTime() then continue end
		local dis = v:GetPos():Distance( self:GetPos() )
		if not d or d > dis then
			d = dis
			c = v
		end
	end
	if c then
		return self:TryHuntPlayer(c)
	end
	return false
end
-- Updates the goal for the NPC. If lost or hunting players. Also updates the angle.
function ENT:CalculateGoal( )
	if CLIENT then return end
	local controller = self:GetController()
	if not controller then return false end

	-- Hunt for players
	if self.NPC_DATA.HuntPlayer then
		if controller:CreationAge() > 5 and controller:GetPathAmountLeft() < 0.5 and not self:GetInJump() then
			self:HuntPlayers()
		end
	end

	local goal = controller:GetGoal()
	if not goal then
		local new_path = self:CreatePathToTarget( )
		if new_path and type(new_path) == "boolean" then
			if self:OnPathEnd() then
				return false
			end
		elseif new_path then
			DebugMessage(string.format("Generated new path for %s.", self))
			controller:SetPath(new_path)
			goal = controller:GetGoal()

			if not goal then
				DebugMessage("Failed to set new goal.")
				return false
			end
		else
			DebugMessage(string.format("Failed to generate new path for %s to %s", self, controller:GetTarget()))
			if SERVER then
				self:Remove()
			end
			return false
		end
	end
	if SERVER then
		local desired = (self.m_lastpos or goal) - self:GetPos()
		if IsValid(self:GetTarget()) then
			desired = self:GetTarget():GetPos() - self:GetPos()
		end
		local cur = self:GetAngles()
		local ang = desired:Angle()
		local a = math.Clamp(math.AngleDifference(ang.y, cur.y), -4, 4)
		self:SetAngles(Angle(0,cur.y + a,0))
	end
end
-- Handles the animation
function ENT:HandleAnimation(  )
	if self.b_WasRagdolled and self.NPC_DATA.ANIM_LAND then
		self:ResetSequence(self.NPC_DATA.ANIM_LAND)
		coroutine.wait( self:SequenceDuration(self.NPC_DATA.ANIM_LAND) )
		self.b_WasRagdolled = false
	end
	local speed = self.loco:GetVelocity():Length()
	if speed < 1 then
		self:ResetSequence(self.NPC_DATA.ANIM_IDLE)
	elseif speed < self:GetMaxSpeed() * 0.75 then
		--self:StartActivity( ACT_WALK )
		self:ResetSequence(self.NPC_DATA.ANIM_WALK or self.NPC_DATA.ANIM_WALK_AIM or self.NPC_DATA.ANIM_RUN)
	else
		--self:StartActivity( ACT_RUN )
		self:ResetSequence(self.NPC_DATA.ANIM_RUN or self.NPC_DATA.ANIM_RUN_AIM or self.NPC_DATA.ANIM_WALK)
	end
	if self.NPC_DATA.ANIM_SPEED then
		self:SetPlaybackRate( self.NPC_DATA.ANIM_SPEED )
	end
end
-- Easy trace
local function ET(self, from, to, target)
	local t = util.TraceLine( {
		start = from,
		endpos = to,
		filter = self,
		mask = MASK_BLOCKLOS_AND_NPCS
	} )
	return not t.Hit or (t.Entity and t.Entity == target)
end
-- Searches for players nearby.
local con = GetConVar("ai_ignoreplayers")
local function SearchPlayers(self, distance, vPos)
	if con:GetBool() then return end 
	local c,e
	vPos = vPos or self:GetPos() + self:OBBCenter()
	for k,v in ipairs(player.GetAll()) do
		if math.abs( v:GetPos().z - vPos.z ) > 200 then continue end
		local dis = vPos:Distance( v:GetPos() )
		if (not c or c > dis) and dis < distance then
			if self.NPC_DATA.TargetIgnoreWalls or ET(self, vPos, v:GetPos() + v:OBBCenter(), v) then
				e = v
				c = dis
			end
		end
	end
	return e
end
-- Moves the NPC towards said point.
function ENT:MoveTowards( pos, ignoreAnimation )
	local mov_speed = self:GetMoveSpeed()
	local delta = (pos - self:GetPos())
	local l = Vector(delta.x,delta.y,0):Length()
	local vel = delta:GetNormalized() * mov_speed
	if not ignoreAnimation then self:HandleAnimation(mov_speed) end
	if self.NPC_DATA.OnStep and (self.m_StepDur or 0) < CurTime() then
		self.m_StepDur = CurTime() + (self.NPC_DATA.OnStep(self) or 40 / mov_speed)
	end
	self.m_lastpos = pos
	if l < 60 then return true end
	if not self:IsOnGround() and not self:GetInJump() then return false end
	self.loco:SetVelocity(vel)
	self.loco:Approach(pos, 1)
	return false
end
-- "Floats" the entity towards the point
function ENT:ForceMoveTowards( pos, time, sequence )
	if self:GetRagdolled() then return end
	self.m_ForceMoving = pos
	self.m_ForceMovingt = time + CurTime()
	self.m_ForceMovings = self:GetPos():Distance( pos ) / time
	self.m_ForceMovingg = self.loco:GetGravity()
	self.m_ForceMovinga = sequence
	self.loco:SetGravity(0)
	self.loco:Approach(pos, 1)
	self:SetSpeedMultTemp(self.m_ForceMovings)
	if coroutine.running() ~= nil then
		coroutine.wait( time )
	end
end
-- Jump functions
function ENT:BasicJump( aimpos )
	local t = CurTime() + 1
	self.loco:SetGravity(0)
	-- Most jump potitions are 64 units away from the edge
	local aimpos_2 = aimpos + (  self:GetPos() - Vector(aimpos.x, aimpos.y, self:GetPos().z)):GetNormalized() * 64
	self:SetSpeedMultTemp( 2 )
	self:MoveTowards(aimpos_2, true) -- Start to fly towards the point
	coroutine.wait( aimpos_2:Distance( self:GetPos() ) / self:GetMoveSpeed() * 0.9 )
	-- We should be there, if not try MoveTowards.
	self:SetSpeedMultTemp(1)
	while self:GetPos():DistToSqr(aimpos) > 3600 and t > CurTime() do
		self:MoveTowards(aimpos, true)
		coroutine.yield()
	end
	-- If everything fails, setpos it.
	if t <= CurTime() then
		self:SetPos(aimpos)
		self.loco:SetVelocity(Vector(0,0,0))
	end
	self.loco:SetGravity(1000)
	self:SetSpeedMultTemp()
end
-- NPCs run interval
function ENT:GetRunInterval()
	return self.m_fInterval or 0
end

-- NPC's runbehaviour. We make our own to limit it.
function ENT:RunBehaviour()
	if CLIENT then return end
	local controller = self:GetController()
	if not controller then return false end
	while ( true ) do
		if self:GetRagdolled() then
			self.b_WasRagdolled = true
			if IsValid( self.e_Ragdoll ) then
				self:SetPos( self.e_Ragdoll:GetPos() )
			end
			coroutine.wait( 0.5 )
		elseif self:GetTarget() then
			if not IsValid( self:GetTarget() ) or not self.NPC_DATA.OnAttack then
				self:SetTarget( nil )
			else
				self.NPC_DATA.OnAttack(self, self:GetTarget())
				self.m_TargetCooldown = CurTime() + ( self.NPC_DATA.TargetCooldown or 15 )
				if self.NPC_DATA.OnAttackEnd then
					self.NPC_DATA.OnAttackEnd(self, self:GetTarget())
				end
				self:SetTarget( nil )
				coroutine.wait(0.3)
				controller:MakeInvalid()
			end
		else
			local goal = controller:GetGoal()
			if self.NPC_DATA.CanTargetPlayers and (self.m_TargetCooldown or 0) < CurTime() and (self.i_search or 0) < CurTime() then
				self.i_search = CurTime() + 5
				self:SetTarget( SearchPlayers(self, self.NPC_DATA.TargetPlayersRange or 200) )
			end
			if goal then
				if self:MoveTowards(goal) then
					local finished, jump = controller:NextGoal()
					if jump ~= 0 then
						self:SetInJump( true )
						if jump > 0 then
							self.loco:Jump()
							if self.NPC_DATA.OnJump then
								self.NPC_DATA.OnJump( self, controller:GetGoal() )
							else
								self:BasicJump( controller:GetGoal() )
							end
						elseif jump < 0 and self.NPC_DATA.OnJumpDown then

							self.NPC_DATA.OnJumpDown(self, controller:GetGoal())
						end
					else
						self:SetInJump( false )
					end
					if finished and self:OnPathEnd() then
						return false
					end
				else
					self:SetInJump( false )
				end
			end
		end
		coroutine.yield()
	end
end
-- NPC OnGround
function ENT:OnLeaveGround()
	self.m_OnGround = false
end
function ENT:OnLandOnGround()
	self.m_OnGround = true
end
function ENT:IsOnGround()
	return self.m_OnGround
end

-- Handles Ragdoll and forcemove
function ENT:Think()
	if self:GetRagdolled() then
		self:NextThink(CurTime() + 1)
		return true
	elseif self.m_ForceMoving then
		if (self.m_ForceMovingt or 0) <= CurTime() then
			self:SetPos(self.m_ForceMoving) -- Set the position.
			self.m_ForceMoving = nil
			self.m_ForceMovingt = nil
			self.m_ForceMovingd = nil
			self.loco:SetGravity(self.m_ForceMovingg or 1000)
			self.m_ForceMovingg = nil
			self.m_ForceMovinga = nil
			self:SetSpeedMultTemp()
		else
			local delta = (self.m_ForceMoving - self:GetPos())
			local len = delta:Length()
			-- self.m_ForceMovings 		Distance / time
			if len >= 20 then
				self.loco:SetVelocity( delta:GetNormalized() * math.min(len * 1.5, self.m_ForceMovings) )
				self:NextThink(CurTime())
				self.BaseClass.Think(self)
				if self.m_ForceMovinga then
					self:ResetSequence( self.m_ForceMovinga )
				end
			else
				self.m_ForceMovinga = nil
				self.m_ForceMoving = nil
				self.m_ForceMovingt = nil
				self.m_ForceMovingd = nil
				self.loco:SetGravity(self.m_ForceMovingg or 1000)
				self.m_ForceMovingg = nil
				self:SetSpeedMultTemp()
			end
			local cur = self:GetAngles()
			local ang = delta:Angle()
			local a = math.Clamp(math.AngleDifference(ang.y, cur.y), -4, 4)
			self:SetAngles(Angle(0,cur.y + a,0))
		end
		return
	else
		self:CalculateGoal( )
		--self:SetVelocity(velocity)
		self:NextThink(CurTime())
		self.BaseClass.Think(self)
		return true
	end
end
-- Draws the NPC
function ENT:Draw()
	if self:GetRagdolled() then return end
	if self:Health() <= 0 and self:GetMaxHealth() > 0 then return end
	if self.NPC_DATA.Color then
		render.SetColorModulation(self.NPC_DATA.Color.r / 255,self.NPC_DATA.Color.g / 255,self.NPC_DATA.Color.b / 255)
	end
	self:DrawModel()
	render.SetColorModulation(1,1,1)

	if halo.RenderedEntity() == self then return end

	local pos = self:GetPos()
	local ply = LocalPlayer()
	local delta = pos - ply:GetShootPos()
	delta:Normalize()

	local dot = ply:GetAimVector():Dot(delta)
	dot = math.deg(math.acos(dot))

	if dot >= 20 or pos:DistToSqr(ply:GetPos()) > 1250 * 1250 then return end

	local eyeang = ply:EyeAngles()
	eyeang:RotateAroundAxis(eyeang:Right(), 90)
	eyeang:RotateAroundAxis(eyeang:Up(), -90)

	local data = self.NPC_DATA

	cam.Start3D2D(pos + Vector(0, 0, self:OBBMaxs().z + 5), eyeang, 0.5)
		local bw, bh = 125, 5
		local bx, by = 0, 0

		local hp = self._FIXHP or self:Health()
		local max_hp = self:GetMaxHealth()

		self.m_HealthLerp = self.m_HealthLerp or PercentLerp(0.5, 0.25, true)

		draw.SimpleText(data.DisplayName or "", "HUD.Building", bx, by, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

		surface.SetDrawColor(35, 35, 35, 200)
		surface.DrawRect(bx - bw * 0.5, by, bw, bh)

		local p = math.Clamp(hp / max_hp, 0, 1)
		local lp = self.m_HealthLerp(hp, max_hp)

		local x_offset = bw - bw * lp
		x_offset = x_offset * 0.5

		surface.SetDrawColor(255, 75, 75)
		surface.DrawRect(bx - bw * 0.5 + x_offset, by, bw * lp, bh)

		x_offset = bw - bw * p
		x_offset = x_offset * 0.5

		surface.SetDrawColor(136, 181, 55)
		surface.DrawRect(bx - bw * 0.5 + x_offset, by, bw * p, bh)
	cam.End3D2D()
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Ragdolled" )
	self:NetworkVar( "String", 0, "NPCType" )
	self:NetworkVar("Int", 0, "Buffs")
	self:NetworkVar("Int", 1, "Debuffs")
end

function ENT:OnRemove()
	if self._sndspeak then -- Dead men don't talk
		self:StopSound( self._sndspeak )
	end
	if self:GetRagdolled() then CUR_RAG = math.max(0, CUR_RAG - 1) end
	if self.e_Ragdoll then SafeRemoveEntity( self.e_Ragdoll) end
end

-- Gets called when the NPC dies.
function ENT:OnKilled( dmginfo )
	if self.Weapon then SafeRemoveEntity( self.Weapon) end
	hook.Call( "OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor() )
	self:BecomeRagdoll( dmginfo )
	if self.e_Ragdoll then SafeRemoveEntity( self.e_Ragdoll) end
	if self.m_IgnoreMoney then return end
	if self._sndspeak then
		self:StopSound( self._sndspeak )
	end
	NPC.RewardCurrency( self.NPC_DATA.Currency or 3 )
end
-- Our own BehaveUpdate
function ENT:BehaveUpdate( fInterval )
	if ( !self.BehaveThread ) then return end
	-- Delete dead NPCs
	if ( coroutine.status( self.BehaveThread ) == "dead" ) then
		self.BehaveThread = nil
		DebugMessage(string.format("%s ENT:RunBehaviour() has finished executing", self))
		NPC.RewardCurrency( self.NPC_DATA.Currency or 3 ) -- We where at fault here. Reward the players.
		SafeRemoveEntity( self )
		return
	end
	-- Don't run AI if ragdolled or health is 0 or if we're flying towards a point
	if not self:GetRagdolled() and self:Health() > 0 and not self.m_ForceMoving then
		if self.b_WasRagdolled then
			self.b_WasRagdolled = false
		end
		self.m_fInterval = fInterval
		local ok, message = coroutine.resume( self.BehaveThread )
		if ( ok == false ) then
			self.BehaveThread = nil
			ErrorNoHalt( self, " Error: ", message, "\n" )
		end
	elseif self:GetRagdolled() then
		if SERVER and not IsValid(self.e_Ragdoll) then -- Ragdoll got removed
			self:UnRagdoll()
		elseif SERVER and ( (self.i_RagdollTime or 0) < CurTime() or (self.e_Ragdoll or self):GetVelocity():Length() < 10 ) then -- Ragdoll timeout
			self:UnRagdoll()
		else
			self.b_WasRagdolled = true
		end
	end
end
-- Draw halo and fix healthbar in singleplayer
if CLIENT then
    hook.Add("PreDrawHalos", "NPC.DrawHalo", function()
		local ent = {}
		for k,v in ipairs( ents.FindByClass("yawd_npc_base") ) do
			if not IsValid(v) or v.b_WasRagdolled or ( v._FIXHP or v:Health() ) <= 0 then continue end
			table.insert(ent, v)
		end
        halo.Add(ent, team.GetColor(TEAM_ATTACKER), nil, nil, nil, nil, false)
    end)
	if game.SinglePlayer() then
		net.Receive("YAWD.SinglePlayerHPFix", function()
			local ent = net.ReadEntity()
			local hp = net.ReadInt(32)
			if not ent or not IsValid(ent) then return end
			ent._FIXHP = hp
		end)
	end
elseif SERVER and game.SinglePlayer() then
	util.AddNetworkString("YAWD.SinglePlayerHPFix")
	hook.Add("PostEntityTakeDamage", "YAWD.SinglePlayerHPFix", function(ent, dmg, took)
		if not ent or not IsValid(ent) then return end
		net.Start("YAWD.SinglePlayerHPFix")
			net.WriteEntity(ent)
			net.WriteInt(ent:Health(), 32)
		net.Broadcast()
	end)
end

-- Don't collide with each other
hook.Add("ShouldCollide","yawd_npc_collide",function(a,b)
	local ac = a:GetClass()
	local bc = b:GetClass()
	local b1 = ac == "yawd_npc_base" or ac == "prop_ragdoll"
	local b2 = bc == "yawd_npc_base" or bc == "prop_ragdoll"
	if b1 and b2 then
		return false
	end
end)