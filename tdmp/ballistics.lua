--[[-------------------------------------------------------------------------
This file provides simplified ballistics api
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamID then return end
#include "json.lua"

Ballistics = {}
Ballistics.Type = {
	Bullet = 0,
	Rocket = 1,
	Laser = 2,
	Buckshot = 3,
	Melee = 4,
}

--[[-------------------------------------------------------------------------
Arguments:
	data: Table of projectile's settings which contains

	Type = Type of the projectile
	Owner = Who's shooting
	Pos = Position where shoot from
	Dir = Direction where shoot at (Normalised vector)
	Vel = Velocity of the projectile (Vector)

	If "Type" of the projectile is "Bullet", then:
		Soft = Hole radius for soft materials
		Medium = Hole radius for medium materials. May not be bigger than "soft". Default zero.
		Hard = Hole radius for hard materials. May not be bigger than "hard". Default zero.
	In other case it's "Rocket", and required filds are:
		Explosion = Explosion size from 0.5 to 4.0

	Damage = damage to player (0-1). Default zero
	NoHole = if true, then do not create a hole
	Life = how many penetrations(walls) can be?

	Gravity(optional) = Gravity of the projectile (-1 for example would drag projectile to the ground)
	HitPlayerAndContinue(optional) = if projectile must hit player(and damage him) and continue "flying" till physical obstacle, then set this to true
	-- Usually it used for default tools or for weapons which penetration is cool enough 
---------------------------------------------------------------------------]]
function Ballistics:Shoot(data)
	data.Damage = data.Damage or 0
	data.Soft = data.Soft or 0
	data.Medium = data.Medium or 0
	data.Hard = data.Hard or 0
	data.Gravity = data.Gravity or 0
	data.Life = data.Life or 0
	data.ShootPos = data.Pos

	Hook_Run("Shoot", data)
end

function Ballistics:RejectPlayerEntities()
	for i, shape in ipairs(FindShapes("player", true)) do
		QueryRejectShape(shape)
	end

	for i, shape in ipairs(FindShapes("playerTool", true)) do
		QueryRejectShape(shape)
	end
end