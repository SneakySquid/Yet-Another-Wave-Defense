--[[
    PRNG functions
    PRNG.SetSeed( seed )   Sets the seed. Can be a number or string.

    PRNG.Next()            Returns the next number. Between 1 and 4.294.967.295.
    PRNG.Reset()           Resets the PRNG to the starting value
    PRNG.RandomFloat()     Returns the next number. Between 0 and 1.
    PRNG.Random(min, max)  Returns the next number and acts like math.Random.
]]
CreateConVar("yawd_seed", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE})
local abs = math.abs
PRNG = {}

local a = 1664525
local c = 1013904223
local m = 2 ^ 32 - 1

local seed = 0
local start_seed = 0
-- Sets the PRNG seed.
function PRNG.SetSeed( vSeed )
    if type(vSeed) == "string" then
        local n = 0
        for i = 1,#vSeed do
            n = n + string.byte(string.sub(vSeed, i,i))
        end
        seed = n
    elseif type(vSeed) == "number" then
        seed = vSeed
    end
    start_seed = seed
end

-- Returns the next number. Between 1 and 4.294.967.295
function PRNG.Next()
    seed = (seed * a + c) % m
	return seed
end

-- Resets the PRNG to the starting seed.
function PRNG.Reset()
    seed = start_seed
end

-- Returns the next number. Between 0 and 1.
function PRNG.RandomFloat()
    return PRNG.Next() / m
end

-- Returns the next number and acts like math.Random.
function PRNG.Random(min, max)
    if not min and not max then
		return PRNG.RandomFloat()
	elseif not max then
		return 1 + PRNG.RandomFloat() * min
	else
		return min + PRNG.RandomFloat() * (max - min)
	end
end

local con = GetConVar("yawd_seed")
if con:GetString() == "0" then
    local t = ""
    for i = 1, math.random(10, 20) do
        local u = math.random(1,2) == 2
        local c = string.char(math.random(97, 122))
        t = t .. (u and string.upper(c) or c)
    end
    PRNG.SetSeed( t )
    MsgC("YAWD SEED [Random]: " .. t .. "\n")
else
    PRNG.SetSeed( con:GetString() )
    MsgC("YAWD SEED: " .. con:GetString() .. "\n")
end