if not TDMP_LocalSteamID then return end
#include "json.lua"
#include "hooks.lua"
#include "player.lua"

TDMP = TDMP or {}

TDMP.Input = {
	mouse1 = 0,
	lmb = 0,
	mouse2 = 1,
	rmb = 1,
	w = 2,
	a = 3,
	s = 4,
	d = 5,
	jump = 6,
	space = 6,
	crouch = 7,
	ctrl = 7,
	e = 8,
	interact = 8
}

TDMP.InputToString = {
	[0] = "lmb",
	[1] = "rmb",
	[2] = "w",
	[3] = "a",
	[4] = "s",
	[5] = "d",
	[6] = "space",
	[7] = "ctrl",
	[8] = "interact",
}

--[[-------------------------------------------------------------------------
steamId [string]: Who's arms to control?
target [table]: target for an arm. Do not fill if you want to reset to default values.
Structure:
{
	pos = world position of target,
	bias = LOCAL position of elbow's location. Optional
}

time [number]: for how long it should use this target? 0 for permanent
---------------------------------------------------------------------------]]
function TDMP_SetLeftArmTarget(steamId, target)
	Hook_Run("SetPlayerArmsTarget", {
		steamid = steamId,

		leftArm = target,
	})
end

function TDMP_SetRightArmTarget(steamId, target)
	Hook_Run("SetPlayerArmsTarget", {
		steamid = steamId,

		rightArm = target,
	})
end

function TDMP_OverrideToolTransform(steamId, tr)
	Hook_Run("SetPlayerToolTransform", {
		steamid = steamId,

		tr = tr,
	})
end

function TDMP_AddToolModel(toolUniqueId, data)
	Hook_AddListener(toolUniqueId .. "_CreateWorldModel", toolUniqueId, function(data)
		data = json.decode(data)
		local ents = Spawn(data[1], data[2])

		return json.encode(ents)
	end)

	Hook_Run("AddToolModel", {data = data, tool = toolUniqueId})
end

-- https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
local function IntersectSphere(rayOrigin, rayDir, spherePos, sphereRad)
	local oc = VecSub(rayOrigin, spherePos)
	local b = VecDot(oc, rayDir)
	local c = VecDot(oc, oc) - sphereRad*sphereRad
	local h = b*b - c

	if h < 0 then return false end

	h = math.sqrt(h)

	return true, -b-h, -b+h
end

local cacheMin = Vec(-.35, 0, -.35)
--[[-------------------------------------------------------------------------
Raycasts players and returning hit player, hit position and distance
---------------------------------------------------------------------------]]
function TDMP_RaycastPlayer(startPos, direction, raycastLocal, length, ignoreIds)
	length = length or math.huge
	local hit, dist = QueryRaycast(startPos, direction, length)

	if not hit then
		local plys = TDMP_GetPlayers()
		for i, pl in ipairs(plys) do
			if raycastLocal or not TDMP_IsMe(pl.id) and (not ignoreIds or not ignoreIds[pl.steamId]) then
				local pos = TDMP_GetPlayerTransform(pl.id).pos
				local driving = pl.veh and pl.veh > 0

				pos[2] = driving and pos[2] - .9 or pos[2]

				local min, max = cacheMin, Vec(.35, (TDMP_IsPlayerInputDown(pl.id, 7) or driving) and 1.1 or 1.8, .35)

				local sphereBottom = VecAdd(pos, Vec(0,.35,0))
				local sphereCenter = VecAdd(pos, Vec(0,max[2]/2,0))
				local sphereTop = VecAdd(pos, Vec(0,max[2]-.35,0))
				local sIntersect, sMin, sM = IntersectSphere(startPos, direction, sphereBottom, .35)
				local sIntersect2, sMin2, sM2 = IntersectSphere(startPos, direction, sphereCenter, .35)
				local sIntersect3, sMin3, sM3 = IntersectSphere(startPos, direction, sphereTop, .35)

				local int1, int2, int3 = sIntersect and math.abs(sMin), sIntersect2 and math.abs(sMin2), sIntersect3 and math.abs(sMin3)
				local pDist = int1 or int2 or int3
				if (pDist and pDist <= length) then
					return pl, int1 and sphereTop or int2 and sphereCenter or sphereBottom, pDist, int1 and "Head" or int2 and "Body" or "Legs"
				end
			end
		end
	end

	return false
end

--[[-------------------------------------------------------------------------
Returns shape which player interacts with. Mostly used for syncing buttons
and triggers on the maps
---------------------------------------------------------------------------]]
function TDMP_AnyPlayerInteractWithShape(useDown)
	local plys = TDMP_GetPlayers()
	for i, v in ipairs(plys) do
		local ply = Player(v.steamId)

		if useDown then
			if ply:IsInputDown("interact") then
				return ply:GetInteractShape()
			end
		else
			if ply:IsInputPressed("interact") then
				return ply:GetInteractShape()
			end
		end
	end

	return -1
end

-- https://github.com/iskolbin/lhsx/blob/master/hsx.lua
function hsv2rgb(h, s, v)
	local C = v * s
	local m = v - C
	local r, g, b = m, m, m
	if h == h then
		local h_ = (h % 1.0) * 6
		local X = C * (1 - math.abs(h_ % 2 - 1))
		C, X = C + m, X + m
		if     h_ < 1 then r, g, b = C, X, m
		elseif h_ < 2 then r, g, b = X, C, m
		elseif h_ < 3 then r, g, b = m, C, X
		elseif h_ < 4 then r, g, b = m, X, C
		elseif h_ < 5 then r, g, b = X, m, C
		else               r, g, b = C, m, X
		end
	end
	
	return r, g, b
end