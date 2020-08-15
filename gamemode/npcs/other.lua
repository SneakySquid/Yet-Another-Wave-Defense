do
	local dog = {}
	dog.Name = "dog"
	dog.DisplayName = "Dog"

	dog.Model = Model("models/dog.mdl")
	dog.MoveSpeed = 65
	dog.Currency = 70
	dog.Skin = {0, 1}
	dog.MinimumWave = 7
	dog.MaxPrWave = 3 			-- This model cost too much.

	dog.Health = 525					-- Health
	dog.JumpDown = 10				-- Allows the NPC to "jumpdown" from said areas
	dog.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas

	dog.CanTargetPlayers = true		-- Tells that we can target the players
	dog.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	dog.TargetPlayersRange = 300	-- The radius of the target
	dog.TargetCooldown = 15			-- The amount of times we can target the player

	dog.ANIM_RUN = 22 -- walk_all

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

	function dog:OnAttack( target )
		self:EmitSound("npc/dog/dog_playfull3.wav" .. math.random(3, 5) .. ".wav")
		-- Move closer to the player
		local target_time = CurTime() + 5
		while target_time > CurTime() and IsValid(target) do
			self:MoveTowards(target:GetPos())
			if target:GetPos():Distance(self:GetPos()) < 50 then -- We are close
				self:ResetSequence("throw")
				coroutine.wait(0.4)
				if target:GetPos():Distance(self:GetPos()) < 70 then
					TakeDamage(self, target)
				end
			end
			coroutine.yield()
		end
		-- We gave up
		return false
	end
	NPC.Add(dog)
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

	gman.Health = 230					-- Health
	gman.JumpDown =50				-- Allows the NPC to "jumpdown" from said areas
	gman.JumpUp = 50					-- Allows the NPC to "jumpup" from said areas

	gman.CanTargetPlayers = true		-- Tells that we can target the players
	gman.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	gman.TargetPlayersRange = 300	-- The radius of the target
	gman.TargetCooldown = 25			-- The amount of times we can target the player

	gman.ANIM_RUN = 17 -- sprint_all
	-- Easter egg for wave 20
	local GGC2020
	if CLIENT then
		GGC2020 = {
			{"Nak", 		"76561198009860285"},
			{"Squid", 		"76561197961746985"},
			{"Lewis", 		"76561198059760564"},
			{"add___123", 	"76561198110055555"},
			{"Bleck", 		"76561198109623483"},
			{"DangerKiddy", "76561198132964487"},
			{"Doc",			"76561198108011282"},
			{"Ferb", 		"76561198035821384"},
			{"HMM'", 		"76561198115172591"},
			{"johnjoemcbob","76561197996461831"},
			{"Madi boi",	"76561198119753316"},
			{"Periapsis", 	"76561198190869035"},
			{"Phatso", 		"76561198002607474"},
			{"R1nlz3r", 	"76561198282400426"},
			{"Sammy boi", 	"76561198053582133"},
			{"VictorienXP", "76561197996826023"},
			{"Tripperful", 	"76561197960465565"}
		}
		for k,v in ipairs(GGC2020) do
			steamworks.RequestPlayerInfo(v[2],function(name)
				GGC2020[k][1] = name or GGC2020[k][1]
			end)
		end
	end
	function gman:Init()
		if CLIENT then
			self:EmitSound("npc/crow/alert" .. math.random(1,3) ..".wav", 170)
			local core = Building.GetCore()
			if GAMEMODE:GetWaveNumber() == 20 and core and IsValid(core) and core:Health() >= 1000 then
				self.NPC_DATA.DisplayName = GGC2020[math.random(1,#GGC2020)][1]
			end
		end
	end

	local function AttackPlayer( self, target )
		self:PlaySequenceAndWait( "meleeattack01" )
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
		self:SpeakSnd("vo/gman_misc/gman_04.wav")
		self:PlaySequenceAndWait("tiefidget")
		self:StopSound("vo/gman_misc/gman_04.wav")
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
		self:SpeakSnd("vo/gman_misc/gman_riseshine.wav")
		-- Move closer to the player
		local target_time = CurTime() + 3
		while target_time > CurTime() and IsValid(target) do
			if target:GetPos():Distance(self:GetPos()) < 70 then -- We are close
				AttackPlayer(self,target)
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

do	
	local hunter = {}
	hunter.Name = "hunter"
	hunter.DisplayName = "Hunter"

	hunter.Model = Model("models/police.mdl")
	hunter.MoveSpeed = 260
	hunter.Currency = 120
	hunter.MinimumWave = 7

	hunter.Health = 250				-- Health
	hunter.JumpDown =450			-- Allows the NPC to "jumpdown" from said areas
	hunter.JumpUp = 225				-- Allows the NPC to "jumpup" from said areas

	hunter.HuntPlayer	= true			-- Tries to hunt the player
	hunter.CanTargetPlayers = true		-- Tells that we can target the players
	hunter.TargetIgnoreWalls = false	-- Ignore walls when targeting players
	hunter.TargetPlayersRange = 600		-- The radius of the target
	hunter.TargetCooldown = 1			-- The amount of times we can target the player

	hunter.ANIM_RUN = 105 -- sprint_all
	hunter.ANIM_SPEED = 2
	hunter.ANIM_JUMP_END = 150 -- jump_holding_land
	hunter.ANIM_JUMP_LOOP = 149 -- jump_holding_glide
	hunter.ANIM_JUMP_START = 148 -- jump_holding_land
	

	local spawnsnd = {"npc/metropolice/vo/searchingforsuspect.wav", "npc/metropolice/vo/standardloyaltycheck.wav"}
	local targetspot = {"npc/metropolice/vo/contactwith243suspect.wav","npc/metropolice/vo/hesrunning.wav", "npc/metropolice/takedown.wav", "npc/metropolice/vo/possible10-103alerttagunits.wav", "npc/metropolice/vo/prepareforjudgement.wav", "npc/metropolice/vo/readytoprosecutefinalwarning.wav"}
	local targetdown = {"npc/metropolice/vo/anyonepickup647e.wav", "npc/metropolice/vo/chuckle.wav", "npc/metropolice/vo/control100percent.wav", "npc/metropolice/vo/clearandcode100.wav"}
	
	local w_t = 0
	local function WarnPlayers()
		if w_t >= CurTime() then return end
		w_t = CurTime() + 8
		for k,v in ipairs( player.GetAll() ) do
			v:EmitSound("ambient/atmosphere/city_skybeam1.wav")
		end
	end
	
	function hunter:Init()
		self:SpeakSnd(spawnsnd, 170)
	end

	local function AttackPlayer( self, target )
		if math.random(1,2) == 1 then
			self:PlaySequenceAndWait( "thrust", 2 )
		else
			self:PlaySequenceAndWait( "swing", 2 )
		end
		if target:GetPos():Distance(self:GetPos()) < 100 then
			if target:IsPlayer() then
				target:ViewPunch( AngleRand() * 0.3 ) 
			end
			local info = DamageInfo()
				info:SetAttacker( self )
				info:SetInflictor( self )
				info:SetDamage( math.random(40, 60) )
			target:TakeDamageInfo( info )
		end
	end

	function hunter:OnJumpDown( aimPos )
		-- debugoverlay.Cross(aimPos, 50,15, Color( 255, 255, 255 ), true)
		self:SetSpeedMultTemp(2) -- Overwrites the speed multiplier
		local t = CurTime() + 3
		
		local dur = self:SetSequence("canal3jump1") -- 2.56
		self:SetCycle(.5)
		local g = CurTime() + dur * .1
		self:SetPlaybackRate(2)
		while self:GetPos():DistToSqr(aimPos) > 4900 and t > CurTime() do
			if g >= CurTime() then
				self:MoveTowards( Vector(aimPos.x,aimPos.y, 0), true )
			else
				self:ResetSequence( "jump_holding_glide" )
				self:MoveTowards( aimPos, true )
			end
			coroutine.yield()
		end
		self:SetSpeedMultTemp() -- Resets the speed multiplier
		local n = math.random(1,2)
		if n > 1 then n = 3 end
		self:EmitSound("player/pl_fallpain".. n .. ".wav")
		self:PlaySequenceAndWait("jump_holding_land")
	end

	local jumpSnd = {"npc/metropolice/vo/ten97suspectisgoa.wav", "npc/metropolice/vo/readytoprosecutefinalwarning.wav", "npc/metropolice/vo/rodgerthat.wav", "npc/metropolice/vo/sweepingforsuspect.wav"}
	function hunter:OnJump( aimpos )
		local t = CurTime() + 1
		-- Most jump potitions are 64 units away from the edge
		local aimpos_2 = aimpos + (  self:GetPos() - Vector(aimpos.x, aimpos.y, self:GetPos().z)):GetNormalized() * 64
		self:SpeakSndNoSpam(jumpSnd)
		self:ForceMoveTowards( aimpos_2, self:GetPos():Distance( aimpos_2 ) / 700, 	hunter.ANIM_JUMP_START )
		
	--	self:SetSpeedMultTemp( 2 )
	--	self:MoveTowards(aimpos_2, true) -- Start to fly towards the point
	--	coroutine.wait( aimpos_2:Distance( self:GetPos() ) / self:GetMoveSpeed() * 0.9 )
		-- We should be there, if not try MoveTowards.
	--	self:SetSpeedMultTemp(1)
	--	while self:GetPos():DistToSqr(aimpos) > 3600 and t > CurTime() do
	--		self:MoveTowards(aimpos, true)
	--		coroutine.yield()
	--	end
		-- If everything fails, setpos it.
	--	if t <= CurTime() then
	--		self:SetPos(aimpos)
	--		self.loco:SetVelocity(Vector(0,0,0))
	--	end
		local n = math.random(1,2)
		if n > 1 then n = 3 end
		self:EmitSound("player/pl_fallpain".. n .. ".wav")
		self:PlaySequenceAndWait("jump_holding_land")

	end

	function hunter:OnAttack( target )
		-- Move closer to the player
		self:SpeakSnd( targetspot )
		
		local target_time = CurTime() + 10
		while target_time > CurTime() and IsValid(target) do
			if target:GetPos():Distance(self:GetPos()) < 70 then -- We are close
				self:SpeakSndNoSpam( targetspot )
				AttackPlayer(self,target)
			else
				self:MoveTowards(target:GetPos())
			end
			coroutine.yield()
		end
		if target:Health() < 1 then
			self:SpeakSnd(targetdown)
			self:PlaySequenceAndWait("plazathreat2", 3)
		end
		
		return false
	end
	NPC.Add(hunter)
end
