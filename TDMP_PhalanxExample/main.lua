--[[-------------------------------------------------------------------------
This is an example of tool with hell high fire rate.

May be a bad example because of it can confuse a bit, so that's why I'll bring
another tool example as well
---------------------------------------------------------------------------]]

#include "tdmp/networking.lua"
#include "tdmp/hooks.lua"
#include "tdmp/player.lua"
#include "tdmp/ballistics.lua"

local shooters = {}
function init()
	loop = LoadLoop("snd/shoot.ogg")
	stop = LoadSound("snd/stop.ogg")
	start = LoadSound("snd/start.ogg")

	TDMP_RegisterEvent("MyMPgun", function(jsonData, steamid)
		local data = json.decode(jsonData)
		steamid = steamid or data[2]

		if data[1] then
			-- we dont need to play start sound twice
			if not shooters[steamid] then
				if not shooters[steamid] then
					PlaySound(start, Player(steamid):GetPos(), 1)
				end

				shooters[steamid] = true
			end
		else
			PlaySound(stop, shooters[steamid], 1)

			shooters[steamid] = nil
		end

		if not TDMP_IsServer() then return end
		data[3] = steamid
			
		TDMP_ServerStartEvent("MyMPgun", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)
end

function GetAimDirection()
	local cam = GetPlayerCameraTransform()
	local forward = TransformToParentPoint(cam, Vec(0, 0, -1))
	local dir = VecSub(forward, cam.pos)

	return VecNormalize(dir), VecLength(dir)
end

LocalSteamID = TDMP_LocalSteamId()
function tick()
	for id, _ in pairs(shooters) do
		local ply = Player(id)
	
		local cam = ply:GetCamera() -- so we don't need to get camera twice, we'll pass it in GetAimDirection

		local shootFrom = cam.pos
		shooters[id] = shootFrom

		local shootDir = ply:GetAimDirection(cam)
		Ballistics:Shoot{
			Type = Ballistics.Type.Bullet,

			Owner = id,
			Pos = shootFrom,
			Dir = shootDir,
			Vel = VecScale(shootDir, 250),
			Soft = .3,
			Medium = .6,
			Hard = .3,
			Damage = .40,
			NoHole = false,

			HitPlayerAndContinue = true,
			Life = 3
		}

		PlayLoop(loop, shootFrom, 1)
	end

	if GetString("game.player.tool") ~= "sledge" then return end

	--[[-------------------------------------------------------------------------
	Such behaviour (Sending message on start shooting and on end shooting) is required for
	such crazy scripting like shooting each tick (what's actually terrible)

	Don't overflow network with spamming, try optimize it. In case if you're
	making automatic rifle, i THINK that you may send your event on each shot,
	it really depends of fire rate.
	---------------------------------------------------------------------------]]
	local t = GetTime()
	if InputReleased("lmb") then
		TDMP_ClientStartEvent("MyMPgun", {
			Reliable = true,

			Data = {false}
		})
	elseif InputPressed("lmb") then
		local dir = GetAimDirection()

		TDMP_ClientStartEvent("MyMPgun", {
			Reliable = true,

			-- Shoot, Shooter, shootPos (for sound)
			Data = {true}
		})
	end
end
