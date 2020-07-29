
local combine = {}
combine.Name = "combine_soldier"
combine.DisplayName = "Combine"

combine.Model = Model("models/combine_soldier.mdl")
combine.MoveSpeed = 140
combine.Currency = 25
combine.Skin = {0, 1}

combine.Health = 75					-- Health
combine.JumpDown = 10				-- Allows the NPC to "jumpdown" from said areas
combine.JumpUp = 0					-- Allows the NPC to "jumpup" from said areas

combine.CanTargetPlayers = true		-- Tells that we can target the players
combine.TargetIgnoreWalls = false	-- Ignore walls when targeting players
combine.TargetPlayersRange = 700	-- The radius of the target
combine.TargetCooldown = 15			-- The amount of times we can target the player
function combine:Init()
	self:GiveWeapon("weapon_smg1")
end
function combine:OnAttack( target )
	self:EmitSound("npc/metropolice/vo/pickupthecan" .. math.random(1,3) .. ".wav")
	self:PlaySequenceAndWait("combatidle1_smg1")
	if not IsValid(target) then return end
	for i = 1, 10 do
		if not IsValid(target) then return end
		self:ShootWeapon( target )
		self:EmitSound("weapons/smg1/npc_smg1_fire1.wav")
		if self:GetRagdolled() then return end
		coroutine.wait(0.1)
	end
end
NPC.Add(combine)
