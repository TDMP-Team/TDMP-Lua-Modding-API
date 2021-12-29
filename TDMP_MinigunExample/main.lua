--[[-------------------------------------------------------------------------
Example of adding networking to an existing gun. It's official Teardown
mod which adds minigun:
https://steamcommunity.com/sharedfiles/filedetails/?id=2399638849
---------------------------------------------------------------------------]]
#include "tdmp/networking.lua"
#include "tdmp/player.lua"
#include "tdmp/ballistics.lua" -- Read below about including that file

soundLoop = {}

-- Since our mod is for workshop as well, we need to add checker for any TDMP function exists. DON'T USE FUNCTIONS FROM "tdmp" FOLDER!
if TDMP_LocalSteamId then

	-- We're caching our steamId because it would give a little bit of optimisation. A tiny. But optimisation
	LocalSteamID = TDMP_LocalSteamId()

	local UseTDMPshooting = false -- We have two ways of shooting, which is described below

	-- so how it works: If we're playing in multiplayer, this function exists, and we can then calmly register our custom event
	-- Callback funcion always receives string as a single argument. If there is no data passed to event, then string would be empty ""
	TDMP_RegisterEvent("MinigunShoot", function(jsonData)
		-- we have two ways of making it work, with a default Teardown's Shoot function, or with TDMP's custom ballistic
		-- "Shoot" function may be not accurate and it's also doesn't have any hooks, but I'll still leave it as an example
		-- In case if we want to use TDMP's ballistics, we need to include "tdmp/ballistics.lua" file

		local data = json.decode(jsonData)

		-- So if we want to use "Shoot" function then:
		if not UseTDMPshooting then 
			Shoot(data[1], data[2])
		else -- otherwise
			Ballistics:Shoot{
				Type = Ballistics.Type.Bullet,

				Owner = LocalSteamID,
				Pos = data[1],
				Dir = data[2],
				Vel = VecScale(data[2], 250),
				Soft = .4,
				Medium = .4,
				Hard = .4,
				Damage = .50,
				NoHole = false,

				HitPlayerAndContinue = true,
				Life = 0
			}
		end

		--Light, particles and sound
		local lp = TransformToParentPoint(data[3], Vec(0.25, -0.25, -2.0))
		PointLight(lp, 1, 0.7, 0.5, 3)
		PlaySound(shootSnd[math.random(0,#shootSnd)])

		-- We're using PlayLoop in this weapon, and it requires to be called each tick. So that's how we'll trick it
		soundLoop[data[4]] = true

		-- And here we'll broadcast that shot to all clients
		if not TDMP_IsServer() then return end

		TDMP_ServerStartEvent("MinigunShoot", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = true, -- we already have json string which would be sent, so we can use it again.
			Data = jsonData
		})
	end)

	-- we need this for stooping sound loop only
	TDMP_RegisterEvent("MinigunStopShooting", function(shooterId)
		soundLoop[shooterId] = nil
	end)
end

--Minigun custom tool example
function init()
	--Register tool and enable it
	RegisterTool("minigun", "Minigun", "MOD/vox/minigun.vox")
	SetBool("game.tool.minigun.enabled", true)

	angle = 0
	angVel = 0
	coolDown = 0
	smoke = 0
	
	spinSnd = LoadLoop("MOD/snd/spin.ogg")
	shootSnd = {}
	for i=0, 7 do
		shootSnd[i] = LoadSound("tools/gun"..i..".ogg")
	end
	
	oldPipePos = Vec()
	particleTimer = 0
end

--Return a random vector of desired length
function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end

function rnd(mi, ma)
	return math.random(1000)/1000*(ma-mi) + mi
end

local stopped = true
function tick(dt)
	--The minigun shares ammo with gun
	SetInt("game.tool.minigun.ammo", GetInt("game.tool.gun.ammo"))

	for id, _ in pairs(soundLoop) do
		PlayLoop(spinSnd, Player(id):GetCamera().pos)
	end

	--Check if minigun is selected
	if GetString("game.player.tool") == "minigun" then
		local ct = GetCameraTransform()

		--Check if firing
		if GetBool("game.player.canusetool") and InputDown("usetool") and GetInt("game.tool.gun.ammo") > 0 then
			angVel = math.min(1000, angVel + dt*2000)	
			if angVel == 1000 then
				if coolDown < 0 then
					stopped = false
					local p = TransformToParentPoint(ct, Vec(0.25, -0.25, -1.1))
					local d = VecAdd(TransformToParentVec(ct, Vec(0,0,-1)), rndVec(0.02))

					-- Here we're still checking for TDMP functions, cuz this mod is for workshop and we're not sure that all people are using TDMP 24/7 in Teardown
					if TDMP_LocalSteamId then
						-- Can be also as {origin = p, dir = d, ct = ct}, but it's better to economy string size since it's limited to 1024 chars
						TDMP_ClientStartEvent("MinigunShoot", {
							Reliable = true,

							Data = {p, d, ct, LocalSteamID}
						})
					else
						Shoot(p, d)

						local lp = TransformToParentPoint(ct, Vec(0.25, -0.25, -2.0))
						PointLight(lp, 1, 0.7, 0.5, 3)
						PlaySound(shootSnd[math.random(0,#shootSnd)])
					end

					smoke = math.min(1.0, smoke + 0.1)
					coolDown = 0.07
					SetInt("game.tool.gun.ammo", GetInt("game.tool.gun.ammo")-1)
				end
			end

			if not TDMP_LocalSteamId then
				PlayLoop(spinSnd)
			end
		else
			if not stopped then
				stopped = true

				if TDMP_LocalSteamId then
					TDMP_ClientStartEvent("MinigunStopShooting", {
						Reliable = true,

						DontPack = true, -- We're sending just ID so we dont need to json.encode here
						Data = LocalSteamID
					})
				end
			end

			angVel = math.max(0, angVel - dt*1000)
		end
	
		--Emit smoke from the pipe, but not when firing
		local p = TransformToParentPoint(ct, Vec(0.25, -0.4, -1.6))
		if not InputDown("lmb") then
			if smoke > 0 then
				if particleTimer < 0.0 then
					particleTimer = dt + (1.0-smoke)*0.05
					local vel = VecScale(VecSub(p, oldPipePos), 0.5/ dt)
					vel = VecAdd(vel, Vec(0, rnd(0, 2), 0))
					ParticleType("smoke")
					ParticleRadius(0.08, 0.15)
					ParticleAlpha(smoke*0.4, 0)
					ParticleDrag(1.0)
					SpawnParticle(p, VecAdd(vel, rndVec(0.1)), 2.0)
				end
			end
		end
		particleTimer = particleTimer - dt
		oldPipePos = p
	
		coolDown = coolDown - dt
		angle = angle + angVel*dt
		
		--Move tool a bit to the right and recoil
		local t = Transform()
		local recoil = math.max(0, coolDown)
		t.pos = Vec(0.3, 0, recoil)
		SetToolTransform(t)

		--Animate barrel around the attachment point
		local b = GetToolBody()
		local voxSize = 0.05
		local attach = Transform(Vec(0.5*voxSize, -8.5*voxSize, 0))
		if body ~= b then
			body = b
			-- Barrel is the second shape in vox file. Remember original position in attachment frame
			local shapes = GetBodyShapes(b)
			barrel = shapes[2] 
			barrelTransform = TransformToLocalTransform(attach, GetShapeLocalTransform(barrel))	
		end
		attach.rot = QuatEuler(0, 0, angle)
		t = TransformToParentTransform(attach, barrelTransform)
		SetShapeLocalTransform(barrel, t)
	end
	smoke = math.max(0.0, smoke - dt/3)
end


