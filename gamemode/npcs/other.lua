do
	local zombie = {}
	zombie.Name = "dog"
	zombie.DisplayName = "Zombie"

	zombie.Model = Model("models/dog.mdl")
	zombie.MoveSpeed = 65
	zombie.Currency = 12
	zombie.Skin = {0, 1}

	zombie.Health = 525					-- Health
	zombie.JumpDown = 10				-- Allows the NPC to "jumpdown" from said areas
	zombie.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas

	zombie.CanTargetPlayers = true		-- Tells that we can target the players
	zombie.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	zombie.TargetPlayersRange = 300	-- The radius of the target
	zombie.TargetCooldown = 15			-- The amount of times we can target the player

	zombie.ANIM_RUN = 22 -- walk_all

	local function TakeDamage( self, target )
		if target:IsPlayer() then
			target:ViewPunch( AngleRand() * 0.3 ) 
		end
		local info = DamageInfo()
			info:SetAttacker( self )
			info:SetInflictor( self )
			info:SetDamage( 90 )
		target:TakeDamageInfo( info )
		if target:IsPlayer() then
			target:ViewPunch( AngleRand() * 0.2 )
			target:SetVelocity( self:GetAngles():Forward() * 480 + Vector(0,0,350))
		end
		local a = math.random(1,3)
		if a == 1 then
			self:EmitSound("npc/dog/dog_disappointed.wav")
			self:PlaySequenceAndWait("disappointed")
		elseif a == 2 then
			self:PlaySequenceAndWait("klab_exit")
		else
			self:EmitSound("npc/dog/dog_laugh1.wav")
			self:PlaySequenceAndWait("excitedup")
		end
	end

	function zombie:OnAttack( target )
		self:EmitSound("npc/dog/dog_playfull3.wav" .. math.random(3, 5) .. ".wav")
		-- Move closer to the player
		local target_time = CurTime() + 5
		while target_time > CurTime() and IsValid(target) and not self:GetRagdolled() do
			self:MoveTowards(target:GetPos())
			if target:GetPos():Distance(self:GetPos()) < 50 then -- We are close
				self:ResetSequence("throw")
				coroutine.wait(0.4)
				if self:GetRagdolled() then return end
				if target:GetPos():Distance(self:GetPos()) < 70 then
					TakeDamage(self, target)
				end
			end
			coroutine.yield()
		end
		-- We gave up
		return false
	end
	NPC.Add(zombie)
end

do
	
local gman = {}
	gman.Name = "gman"
	gman.DisplayName = "Gman"

	gman.Model = Model("models/gman_high.mdl")
	gman.MoveSpeed = 220
	gman.Currency = 80
	gman.MinimumWave = 4
	gman.Spawnable = false

	gman.Health = 130					-- Health
	gman.JumpDown =50				-- Allows the NPC to "jumpdown" from said areas
	gman.JumpUp = 50					-- Allows the NPC to "jumpup" from said areas

	gman.CanTargetPlayers = true		-- Tells that we can target the players
	gman.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	gman.TargetPlayersRange = 300	-- The radius of the target
	gman.TargetCooldown = 25			-- The amount of times we can target the player

	gman.ANIM_RUN = 17 -- sprint_all

	function gman:Init()
		self:EmitSound("npc/crow/alert" .. math.random(1,3) ..".wav", 170)
	end

	local function AttackPlayer( self, target )
		self:PlaySequenceAndWait( "meleeattack01" )
		if self:GetRagdolled() then return end
		if target:IsPlayer() then
			target:ViewPunch( AngleRand() * 0.3 ) 
		end
		local info = DamageInfo()
			info:SetAttacker( self )
			info:SetInflictor( self )
			info:SetDamage( 40 )
		target:TakeDamageInfo( info )
	end

	local function TeleportPlayer( self, target )
		self:EmitSound("vo/gman_misc/gman_04.wav")
		self:PlaySequenceAndWait("tiefidget")
		self:StopSound("vo/gman_misc/gman_04.wav")
		if self:GetRagdolled() then return end
		-- Find any ground nodes
			local d,c = -1
			for k, v in ipairs( PathFinder.GetNodes(NODE_TYPE_GROUND) ) do
				local dis = target:GetPos():Distance(v:GetPos())
				if d < 0 or dis < d and dis > 1000 then
					d = dis
					c = v
				end
			end
		if not c then return end -- Couldn't find any nodes
		target:SetPos(c:GetPos() + Vector(0,0,5))
		target:EmitSound("ambient/levels/labs/electric_explosion1.wav")
	end

	function gman:OnAttack( target )
		self:EmitSound("vo/gman_misc/gman_riseshine.wav")
		-- Move closer to the player
		local target_time = CurTime() + 3
		while target_time > CurTime() and IsValid(target) and not self:GetRagdolled() do
			if target:GetPos():Distance(self:GetPos()) < 70 then -- We are close
				AttackPlayer(self,target)
				if self:GetRagdolled() then return end
			else
				self:MoveTowards(target:GetPos())
			end
			coroutine.yield()
		end
		if target:Health() < 1 then return end -- We killed him
		-- We gave up
		TeleportPlayer(self, target)
		return false
	end
	NPC.Add(gman)
end