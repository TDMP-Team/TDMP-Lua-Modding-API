--[[-------------------------------------------------------------------------
This is an example of how hooks are working in TDMP

Hooks allows you to run functions from different mods, which is basicly
used by TDMP balistics
---------------------------------------------------------------------------]]

-- Let's imagine that we'll publish this mod to steam workshop. So to avoid spamming errors and dumb comments that "yo bro your mod sucks cuz its not workin", we'll check is
-- TDMP launched at all
if not TDMP_LocalSteamId then DebugPrint("TDMP Isn't launched!") return end

#include "tdmp/json.lua"
#include "tdmp/hooks.lua"
#include "tdmp/player.lua"

--[[-------------------------------------------------------------------------
We're going to make a mod which adds a suppresion effect when a bullet 
flyes by our head (screen would blur a bit)
---------------------------------------------------------------------------]]

local suppressDist = 1000
SuppresionAmount = 0
LocalSteamID = TDMP_LocalSteamId()

local function Distance(a, b)
	local sub = VecSub(a, b)
	return sub[1]^2 + sub[2]^2 + sub[3]^2
end

--[[-------------------------------------------------------------------------
Here we're adding new Hook listener. First argument is event's name,
second one is our *unique* hook name. You can override any hook
with same unique name

"TDMP_BulletFlyBy" is a default hook which calls each time when
a bullet flyes by local player's head. It passes a table where:

1st Element: bullet's startPos(aka bullet's current position).
2nd Element: bullet's endPos (position where bullet would be if it won't hit anything).
3th Element: where bullet was originally shot from.
4th Element: bullet's owner (if any).
5th Element: Any bullet's custom data. It can be a string, table or whatever codder would add
---------------------------------------------------------------------------]]

local localPlayer
Hook_AddListener("TDMP_BulletFlyBy", "ExampleScript", function(jsonData)
	DebugPrint("FlyBy")
	if not localPlayer then
		localPlayer = Player(LocalSteamID) -- yay, caching!
	end

	local projectileData = json.decode(jsonData)

	if Distance(projectileData[3], localPlayer:GetPos()) >= suppressDist then
		SetValue("SuppresionAmount", SuppresionAmount + .03, "linear", .5)

		if SuppresionAmount >= .5 then
			-- Here we're calling our custom hook which anyone can listen to, using Hook_AddListener.
			Hook_Run("HeavySuppresion", {
				BulletOwner = projectileData[4],
				ShootingFrom = projectileData[3]
			})
		end
	end
end)

local oldSup = 0
function draw()
	if SuppresionAmount > 0 then
		UiBlur(math.min(.5, SuppresionAmount))

		if oldSup == SuppresionAmount then
			SetValue("SuppresionAmount", 0, "linear", 3)
		end

		oldSup = SuppresionAmount
	end
end

function tick()
	TDMP_Hook_Queue() -- We're listening for any hooks so we must call this each tick
end