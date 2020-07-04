function GM:CreateTeams()
	TEAM_DEFENDER = 1
	team.SetUp(TEAM_DEFENDER, "Defenders", Color(173, 216, 230))

	TEAM_ATTACKER = 2
	team.SetUp(TEAM_ATTACKER, "Attackers", Color(234, 60, 83))
end
