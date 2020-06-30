
-- Variables that are used on both client and server

SWEP.Instructions	= "Place your vote."

SWEP.Spawnable			= true
SWEP.AdminOnly			= false

SWEP.ViewModel			= "models/weapons/c_pistol.mdl"
SWEP.WorldModel			= "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.PrintName			= "Vote"
SWEP.Slot				= 1
SWEP.SlotPos			= 1
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= false

--[[---------------------------------------------------------
	Reload does nothing
-----------------------------------------------------------]]
function SWEP:Reload()
end
--[[---------------------------------------------------------
	PrimaryAttack
-----------------------------------------------------------]]
function SWEP:PrimaryAttack()

end
--[[---------------------------------------------------------
	Reload does nothing
-----------------------------------------------------------]]
function SWEP:Think()
end

if CLIENT then
	local nearest_render = 60 -- The amount of nodes to render near the player
	--[[---------------------------------------------------------
		Render valid nodes (Or the closest if anyone if nearby)
	-----------------------------------------------------------]]
	local t = {}
	local function update_nearby()
		t = {}
		local lp = LocalPlayer():GetPos()
		for _,node in ipairs(PathFinder.GetMapNodes()) do
			if node:GetType() ~= NODE_TYPE_GROUND then continue end
			local np = node:GetPos()
			local dis = np:DistToSqr(lp)
			table.insert(t, {node, np:DistToSqr(lp),np})
		end
		table.sort( t, function(a, b) return a[2] < b[2] end )
	end
	local t_cur = 0
	local m = Material("effects/energyball")
	local m2 = Material("effects/energysplash")
	local m3 = Material("effects/splashwake1")
	function SWEP:DrawHUD()
		-- Render message in center
		draw.DrawText("Place your base location", "DermaLarge", ScrW() / 2, ScrH() / 4, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER)
		-- Only update the nearest node-list each half second.
		if t_cur <= CurTime() then
			t_cur = CurTime() + 0.5
			update_nearby()
		end
		-- Find the node the player is aiming at
		local tr = LocalPlayer():GetEyeTrace()
		local aim_p = tr.Hit and tr.HitPos or LocalPlayer():GetPos()
		local d,aim_node
		for i = 1,nearest_render do
			if not t[i] then break end
			local p = t[i][3]
			local dis = p:DistToSqr(aim_p)
			if not d or d > dis then
				d = dis
				aim_node = t[i][1]
			end
		end
		-- Render
		cam.Start3D()
			for i = 1,nearest_render do
				if not t[i] then break end
				local node = t[i][1]
				local pos = t[i][3]
				render.SetMaterial(m2)
				if aim_node and aim_node == node then
					render.DrawBeam( pos, pos + Vector(0,0,90), 60, 0.8, math.random(0,1) * 0.1, Color( 255, 255, 0 ) )
					render.SetMaterial(m3)
					render.DrawQuadEasy(pos, Vector(0,0,1), 90, 90, Color(0,255,0),CurTime() * 20 % 360)
					render.DrawQuadEasy(pos, Vector(0,0,1), 120, 120, Color(0,255,0),CurTime() * -15 % 360)
				else
					render.DrawBeam( pos, pos + Vector(0,0,30), 30, 0.8, math.random(0,1) * 0.1, Color( 255, 155, 255 ) )
				end
			end
		cam.End3D()
	end
end