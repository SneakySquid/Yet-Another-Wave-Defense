
local ZOMBIE = {}
ZOMBIE.DisplayName = "Zombie"

ZOMBIE.Model = Model("models/Zombie/Classic.mdl")
-- ZOMBIE.Material = Material("") 
-- ZOMBIE.Skin = 0
-- ZOMBIE.Bodygroup = "0"
-- ZOMBIE.WalkSpeed = 300

ZOMBIE.AttackType = NPC_MELEE
ZOMBIE.AttackSound = {Sound("npc/zombie/zo_attack1.wav", Sound("npc/zombie/zo_attack2.wav"))}
ZOMBIE.HitSound = Sound("npc/zombie/zombie_pound_door.wav")
ZOMBIE.HitPlayerSound = {Sound("npc/zombie/claw_strike1.wav"), Sound("npc/zombie/claw_strike2.wav"), Sound("npc/zombie/claw_strike3.wav")}
ZOMBIE.IdleSound = {}
for i = 1, 14 do
	table.insert(ZOMBIE.IdleSound, Sound("npc/zombie/zombie_voice_idle" .. i .. ".wav"))
end
ZOMBIE.IdleSoundWait = 0


ZOMBIE.CanTargetPlayers = true
ZOMBIE.TargetPlayersRange = 300

ZOMBIE.Health = 75
ZOMBIE.Damage = math.random(50, 75)

ZOMBIE.JumpDown = 10
ZOMBIE.JumpUp = 0

return ZOMBIE