function GM:CreateTeams()
	TEAM_DEFENDER = 1
	team.SetUp(TEAM_DEFENDER, "Defenders", Color(173, 216, 230))

	TEAM_ATTACKER = 2
	team.SetUp(TEAM_ATTACKER, "Attackers", Color(234, 60, 83))
end

if SERVER then
	local con = GetConVar("yawd_start_currency")
	GM:Accessor("TotalCurrency", con and con:GetInt() or 0)
	function GM:YAWDOnCurrencyGiven(amt)
		self.m_TotalCurrency = self.m_TotalCurrency + amt
	end
else
	function GM:PreDrawHalos()
		halo.Add(player.GetAll(), Color(173, 216, 230), nil, nil, nil, nil, true)
	end
end
