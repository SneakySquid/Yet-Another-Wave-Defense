
local zombie = {}
zombie.Name = "zombie"
zombie.DisplayName = "Zombie"

zombie.Model = Model("models/Zombie/Classic.mdl")
zombie.MoveSpeed = 60
zombie.Currency = 12
zombie.Skin = {0, 1}

zombie.Health = 75					-- Health
zombie.JumpDown = 10				-- Allows the NPC to "jumpdown" from said areas
zombie.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas

zombie.CanTargetPlayers = true		-- Tells that we can target the players
zombie.TargetIgnoreWalls = false	-- Ignore walls when targeting players
zombie.TargetPlayersRange = 300	-- The radius of the target
zombie.TargetCooldown = 15			-- The amount of times we can target the player

local function TakeDamage( self, target )
	if target:IsPlayer() then
		target:ViewPunch( AngleRand() * 0.3 ) 
	end
	local info = DamageInfo()
		info:SetAttacker( self )
		info:SetInflictor( self )
		info:SetDamage( 15 )
	target:TakeDamageInfo( info )
end

function zombie:OnAttack( target )
	self:EmitSound("npc/zombie/zombie_alert" .. math.random(1, 3) .. ".wav")
	-- Move closer to the player
	local target_time = CurTime() + 5
	while target_time > CurTime() and IsValid(target) and not self:GetRagdolled() do
		self:MoveTowards(target:GetPos())
		if target:GetPos():Distance(self:GetPos()) < 50 then -- We are close
			self:ResetSequence("attack" .. table.Random({"a", "b", "c", "d", "e", "f"}) )
			self:SetPlaybackRate(1.5)
			coroutine.wait(0.3)
			if self:GetRagdolled() then return end
			if target:GetPos():Distance(self:GetPos()) < 50 then
				self:EmitSound("npc/zombie/claw_strike" .. math.random(1,2) .. ".wav")
				TakeDamage(self, target)
				if math.random(1,3) < 2 then -- double hit
					self:SetPlaybackRate(3)
					coroutine.wait(0.2)
					self:ResetSequence("attack" .. table.Random({"a", "b", "c", "d", "e", "f"}) )
					self:SetPlaybackRate(1.5)
					self:EmitSound("npc/zombie/claw_strike" .. math.random(1,2) .. ".wav")
					TakeDamage(self, target)
				else
					self:SetPlaybackRate(1.5)
				end
				--return true -- Why wait? Keep attacking.
				coroutine.wait(0.7)
				if self:GetRagdolled() then return end
			else
				self:EmitSound("npc/zombie/claw_miss" .. math.random(1, 2) .. ".wav")
				return false
			end
		end
		coroutine.yield()
	end
	-- We gave up
	return false
end
NPC.Add(zombie)

local zombie = {}
zombie.Name = "fast_zombie"
zombie.DisplayName = "Fast Zombie"

zombie.Model = Model("models/Zombie/Fast.mdl")
zombie.MoveSpeed = 220
zombie.Currency = 22
zombie.Skin = {0, 1}

zombie.Health = 65					-- Health
zombie.JumpDown = 50				-- Allows the NPC to "jumpdown" from said areas
zombie.JumpUp = 50					-- Allows the NPC to "jumpup" from said areas

zombie.CanTargetPlayers = true		-- Tells that we can target the players
zombie.TargetIgnoreWalls = false	-- Ignore walls when targeting players
zombie.TargetPlayersRange = 300	-- The radius of the target
zombie.TargetCooldown = 25			-- The amount of times we can target the player

function zombie:Init()
	self:EmitSound("npc/fast_zombie/fz_alert_far1.wav", 90)
end

local function TakeDamage( self, target )
	if target:IsPlayer() then
		target:ViewPunch( AngleRand() * 0.3 ) 
	end
	local info = DamageInfo()
		info:SetAttacker( self )
		info:SetInflictor( self )
		info:SetDamage( 7 )
	target:TakeDamageInfo( info )
end

function zombie:OnAttack( target )
	self:EmitSound("npc/zombie/zombie_alert" .. math.random(1, 3) .. ".wav")
	-- Move closer to the player
	local target_time = CurTime() + 5
	while target_time > CurTime() and IsValid(target) and not self:GetRagdolled() do
		if target:GetPos():Distance(self:GetPos()) < 50 then -- We are close
			self:ResetSequence( "melee" )
			self:EmitSound("npc/zombie/claw_strike" .. math.random(1,2) .. ".wav")
			TakeDamage(self, target)
			coroutine.wait(0.2)
			if self:GetRagdolled() then return end
		else
			self:MoveTowards(target:GetPos())
		end
		coroutine.yield()
	end
	-- We gave up
	self:EmitSound("npc/fast_zombie/wake1.wav")
		if self:GetRagdolled() then return end
		self:PlaySequenceAndWait("br2_roar")
	return false
end
NPC.Add(zombie)
