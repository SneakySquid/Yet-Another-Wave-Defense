-- Small Ant. Can't do much
do
	local lion = {}
	lion.Name = "ant_lion_small"
	lion.DisplayName = "Small Ant"

	lion.Model = Model("models/antlion.mdl")
	lion.MoveSpeed = 140
	lion.Currency = 10
	lion.Skin = 0
	lion.Health = 15					-- Health
	lion.JumpDown = 100				-- Allows the NPC to "jumpdown" from said areas
	lion.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas

	lion.CanTargetPlayers = false		-- Tells that we can target the players
	lion.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	lion.TargetPlayersRange = 0		-- The radius of the target
	lion.TargetCooldown = 15			-- The amount of times we can target the player
	function lion:Init()
		self:SetModelScale(0.5,0)
	end

	function lion:OnStep()
		self:EmitSound( "npc/antlion/foot" .. math.random(1,4) .. ".wav", 75, 200 )
	end
	NPC.Add(lion)
end
-- Golden Ant. Can't do much
do
	local lion = {}
	lion.Name = "ant_lion_gold"
	lion.DisplayName = "Golden Ant"
	lion.Spawnable = false 		-- We don't these to spawn by themselves.

	lion.Model = Model("models/antlion.mdl")
	lion.Color = Color(255,215,0)
	lion.MoveSpeed = 140
	lion.Currency = 150
	lion.Skin = 1
	lion.Health = 15					-- Health
	lion.JumpDown = 100				-- Allows the NPC to "jumpdown" from said areas
	lion.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas

	lion.CanTargetPlayers = false		-- Tells that we can target the players
	lion.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	lion.TargetPlayersRange = 0		-- The radius of the target
	lion.TargetCooldown = 15			-- The amount of times we can target the player
	function lion:Init()
		self:SetModelScale(0.5,0)
	end

	function lion:OnStep()
		if math.random(10) <= 9 then
			self:EmitSound( "npc/antlion/foot" .. math.random(1,4) .. ".wav", 75, 255 )
		else
			self:EmitSound( "physics/metal/metal_box_impact_soft".. math.random(1,2) .. ".wav", 75, 255 )
		end
	end
	NPC.Add(lion)
end
-- Big Ant. This one is more armored and charges players.
do
	local lion = {}
	lion.Name = "ant_lion"
	lion.DisplayName = "Ant Lion"

	lion.Model = Model("models/antlion.mdl")
	lion.MoveSpeed = 160
	lion.Currency = 33
	lion.Skin = 1
	lion.Health = 150				-- Health
	lion.JumpDown = 150				-- Allows the NPC to "jumpdown" from said areas
	lion.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas

	lion.CanTargetPlayers = true		-- Tells that we can target the players
	lion.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	lion.TargetPlayersRange = 600	-- The radius of the target
	lion.TargetCooldown = 30		-- The amount of times we can target the player
	function lion:Init()
		self.NPC_DATA.ANIM_RUN = self.NPC_DATA.ANIM_WALK
	end
	local function TakeDamage( self, target )
		if target:IsPlayer() then
			target:ViewPunch( AngleRand() * 0.1 ) 
		end
		local info = DamageInfo()
			info:SetAttacker( self )
			info:SetInflictor( self )
			info:SetDamage( 7 )
		target:TakeDamageInfo( info )
	end
	function lion:OnStep()
		self:EmitSound( "npc/antlion/foot" .. math.random(1,4) .. ".wav" )
	end
	function lion:OnAttack( target )
		self:EmitSound("npc/antlion/distract1.wav")
		-- Move (faster) to the player
		self:SetSpeedMultTemp( 1.5 )
		self.m_NewTarget = true
		local target_time = CurTime() + 5
		while target_time > CurTime() and IsValid(target) do
			if target:GetPos():Distance(self:GetPos()) < 100 then -- We are close
				local seq = self:LookupSequence( "attack" .. math.random(1,6) )
				self:ResetSequence( seq )
				self:EmitSound("npc/antlion/attack_single" .. math.random(1, 3) .. ".wav")
				TakeDamage(self, target)
				coroutine.wait(self:SequenceDuration( seq ) or 0.2)
			else
				if self.m_NewTarget then
					self:PlaySequenceAndWait( "charge_start")
					self.m_NewTarget = nil
				end
				self:ResetSequence( "charge_run" )
				self:MoveTowards(target:GetPos(), true)
			end
			coroutine.yield()
		end
		-- We gave up
			self:EmitSound("npc/antlion/pain1.wav")
			self:PlaySequenceAndWait("charge_end")
		return false
	end
	function lion:OnAttackEnd( target )
		self:SetSpeedMultTemp( )
	end
	NPC.Add(lion)
end

-- Guardian. Oh no
do
	local lion = {}
	lion.Name = "ant_guardian"
	lion.DisplayName = "Ant Guardian"
	lion.MinimumWave = 5

	lion.Model = Model("models/antlion_guard.mdl")
	lion.MoveSpeed = 160
	lion.Currency = 175
	lion.Skin = 0
	lion.Health = 400				-- Health
	lion.JumpDown = 150				-- Allows the NPC to "jumpdown" from said areas
	lion.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas
	lion.FuzzyAmount = 0.5			-- Amount of "fuzzyness" for the path. Default is 1.

	lion.ANIM_RUN = "walkN"	-- We need this to "walk" towards the Core

	lion.CanTargetPlayers = true		-- Tells that we can target the players
	lion.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	lion.TargetPlayersRange = 600	-- The radius of the target
	lion.TargetCooldown = 10		-- The amount of times we can target the player
	function lion:Init()
		self:SetCanBePushed( false ) -- This one can't be pushed
	end
	local function TakeDamage( self, target )
		if target:IsPlayer() then
			target:ViewPunch( AngleRand() * 0.1 )
			target:SetVelocity( self:GetAngles():Forward() * 140 + Vector(0,0,350))
		end
		local info = DamageInfo()
			info:SetAttacker( self )
			info:SetInflictor( self )
			info:SetDamage( 40 + math.random(10) )
		target:TakeDamageInfo( info )
		
	end
	function lion:OnStep()
		self:EmitSound( "npc/antlion_guard/foot_heavy" .. math.random(1,2) .. ".wav" )
	end
	function lion:OnAttack( target )
		self:EmitSound("npc/antlion_guard/angry" .. math.random(1,3) .. ".wav")
		-- Move (faster) to the player
		self:SetMaxSpeed( 400 )
		self.m_NewTarget = true
		local target_time = CurTime() + 5
		while target_time > CurTime() and IsValid(target) do
			if not self.m_NewTarget and target:GetPos():Distance(self:GetPos()) < 170 then -- We are close
				self:EmitSound("npc/antlion_guard/shove1.wav")
				TakeDamage(self, target)
				self:PlaySequenceAndWait( "charge_crash")
				return
			else
				if self.m_NewTarget then
					self:PlaySequenceAndWait( "charge_startfast")
					self.m_NewTarget = nil
				end
				self:ResetSequence( "charge_loop" )
				self:MoveTowards(target:GetPos(), true)
			end
			coroutine.yield()
		end
		-- We gave up
			self:EmitSound("npc/antlion_guard/angry" .. math.random(1,3) .. ".wav")
			self:PlaySequenceAndWait("charge_stop")
		return false
	end
	function lion:OnAttackEnd( target )
		self:SetMaxSpeed( 160 )
	end
	NPC.Add(lion)
end
