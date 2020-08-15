
surface.CreateFont( "YAWD_Buttons", {
	font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 170,
	weight = 1500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})


surface.CreateFont("HUD.Hints", {
	font = "Tahoma",
	size = 32,
	weight = 1500,
	outline = true
})

local mat, mat_ov = (Material( "yawd/hud/icon_sheet.png" )), (Material( "yawd/hud/icon_sheet_overlay.png" ))

local k_w, k_h = 500,500
local mat_w, mat_h = 1606, 1980
local KEYS= {
	[MOUSE_RIGHT] = {0,0,538, 542},
	[MOUSE_LEFT] = 	{538,0,538, 542},
	[MOUSE_WHEEL_UP] = {1076, 0,529,573},
	[MOUSE_WHEEL_DOWN] = {1076, 747,529,573},
	[KEY_UP] = 		{0,mat_h - k_h * 2,	k_w,k_h},
	[KEY_DOWN] = 	{k_w,mat_h-k_h * 2,	k_w,k_h},
	[KEY_LEFT] = 	{0,mat_h - k_h,		k_w,k_h},
	[KEY_RIGHT] = 	{k_w,mat_h - k_h,		k_w,k_h},
	[KEY_LSHIFT] = 	{0, 539, 1091, 440},
	[1] = 			{k_w * 2,mat_h - k_h,		k_w,k_h},
}
KEYS[KEY_RSHIFT] = KEYS[KEY_LSHIFT]
KEYS[KEY_SPACE] = KEYS[KEY_LSHIFT]


local function GetClip( IN_KEY )
	return unpack(KEYS[IN_KEY] or KEYS[1])
end

local t = {MOUSE_RIGHT, MOUSE_LEFT, MOUSE_WHEEL_DOWN, MOUSE_WHEEL_UP}
local function RenderKey( x,y,w, h, IN_KEY )
	local col, text = surface.GetDrawColor()
	local su,sv,wu,wv = GetClip( IN_KEY )
	local eu = (su + wu) / mat_w
	local ev = (sv + wv) / mat_h
	su = su / mat_w
	sv = sv / mat_h
	if IN_KEY and table.HasValue(t, IN_KEY) then
		surface.SetMaterial(mat_ov)
		surface.DrawTexturedRectUV(x, y, w, h, su, sv, eu, ev)
	end
	surface.SetDrawColor( color_white )
	surface.SetMaterial(mat)
	surface.DrawTexturedRectUV(x, y, w, h, su, sv, eu, ev)
	surface.SetDrawColor( col )
end

function GM:RenderKey( x, y, h, IN_KEY, Rotate )
	if h <= 0 then return 0, 0 end
	local mat = Matrix()
	local scale = h / 256
	local wide = IN_KEY == KEY_SPACE or IN_KEY == KEY_LSHIFT or IN_KEY == KEY_RSHIFT
	mat:Translate(Vector( x, y ))
	if Rotate then
		mat:Translate(Vector(h / 2, h / 2))
		mat:Rotate(Angle(0,Rotate,0))
		mat:Translate(-Vector( h / 2, h / 2))
	end
	mat:Scale( Vector(scale,scale,1) )
	local w = wide and 768 or 256
	local text
	if type(IN_KEY) == "string" then
		text = IN_KEY
	elseif not (IN_KEY >= MOUSE_FIRST and IN_KEY <= MOUSE_LAST) then
		text = string.upper(input.GetKeyName(IN_KEY))
	end
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )
	cam.PushModelMatrix(mat) 
		RenderKey( 0, 0, w, 256, IN_KEY)
		if text then
			surface.SetFont("YAWD_Buttons")
			local tw,th = surface.GetTextSize(text)
			surface.SetTextPos( w / 2 - tw/2, 128 - th/2 )
			surface.SetTextColor(color_black)
			surface.DrawText( text )
		end
	cam.PopModelMatrix()
	render.PopFilterMag()
	render.PopFilterMin()
	return wide and h * 3 or h,h
end

local offset = 4
function GM:RenderKeyBetween( x, y, font, bCenter, ... )
	surface.SetFont(font)
	local _,th = surface.GetTextSize("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	local box_size = th * 1.3
	local args = { ... }
	-- Calculate the width
	local total_w = #args * offset
	for k,v in ipairs( args ) do
		if type(v) == "string" then
			total_w = total_w + surface.GetTextSize( v )
		else
			total_w = total_w + box_size
		end
	end
	-- Start rendering
	local c_x = 0
	if bCenter then
		c_x = -total_w / 2
	end
	for k,v in ipairs( args ) do
		local w = 0
		if type(v) == "string" then
			surface.SetTextColor(color_white)
			surface.SetFont(font)
			w = w + surface.GetTextSize( v )
			surface.SetTextPos(x + c_x, y)
			surface.DrawText(v)
		else
			local rw, rh = self:RenderKey( x + c_x, y + th - box_size, box_size, v )
			w = w + rw
			
		end
		c_x = c_x + w + offset
	end
	return total_w, box_size
end

local hint_y = 0
local pl_color = color_white
local con = GetConVar("cl_playercolor")
if con then
	local vec = Vector( con:GetString() ) * 255
	local hue = ColorToHSL(Color(vec.x,vec.y,vec.z))
	pl_color = HSLToColor(hue , 1, 0.5)
	PrintTable(pl_color)
end
local box_size = 30
local offset = 4
function GM:RenderKeyHint( ... )
	surface.SetFont("HUD.Hints")
	local x, y = ScrW() * 0.5, ScrH() * 0.56 - hint_y
	surface.SetDrawColor(pl_color)
	local args = { ... }
	-- Calculate the width
	local total_w = #args * offset
	local h = 0
	for k,v in ipairs( args ) do
		if type(v) == "string" then
			local w,h3 = surface.GetTextSize( v )
			total_w = total_w + w
			h = math.max(h)
		else
			total_w = total_w + box_size
		end
	end
	-- Start rendering
	local c_x = -total_w / 2
	for k,v in ipairs( args ) do
		local w = 0
		if type(v) == "string" then
			surface.SetTextColor(color_white)
			surface.SetFont("HUD.Hints")
			w = w + surface.GetTextSize( v )
			surface.SetTextPos(x + c_x, y)
			surface.DrawText(v)
		else
			w = w + box_size
			self:RenderKey( x + c_x, y + h  , box_size, v )
		end
		c_x = c_x + w + offset
	end
	hint_y = hint_y + box_size + offset
end
	
hook.Add("PostDrawHUD", "YAWD_HintReset", function()
	hint_y = 0
end)