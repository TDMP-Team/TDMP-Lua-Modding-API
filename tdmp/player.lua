--[[-------------------------------------------------------------------------
Simple metatable for people who likes.. metatables? And also not using
TDMP_GetPlayerTransformCameraRotationPositionBlablabla() each time, what
makes code look more clear and easier to read
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamId then return end

Player = Player or {}
Player.__index = Player

function Player:GetTransform()
	return TDMP_GetPlayerTransform(self.id)
end

function Player:GetPos()
	return self:GetTransform().pos
end

function Player:GetRotation()
	return self:GetTransform().rot
end

function Player:IsMe()
	return TDMP_IsMe(self.id)
end

function Player:GetVehicle()
	return self.veh
end

function Player:IsDrivingVehicle()
	return self.veh and self.veh > 0
end

function Player:GetCamera()
	return TDMP_GetPlayerCameraTransform(self.id)
end

-- TODO: Make it possible to know whether or not player is crouching. Would ve very useful for player model
--[[
function Player:IsCrouching()
	return
end

function Player:GetHeight()
	local crouch = self:IsCrouching()
	return crouch and 1.1 or 1.8, crouch
end
]]

function Player:GetAimDirection(cam)
	cam = cam or self:GetCamera()
	local forward = TransformToParentPoint(cam, Vec(0, 0, -1))
	local dir = VecSub(forward, cam.pos)

	return VecNormalize(dir), VecLength(dir)
end

-- TODO:
--[[
function Player:GetToolTransform()
	return self.ToolTransform
end
]]


function Player:SteamID()
	return self.steamId
end

function Player:Nick()
	return self.nick
end

function Player:ID()
	return self.id
end

-- TODO:
--[[
function Player:IsDead()
	return self.health <= 0
end

function Player:Health()
	return self.health
end
]]

local idCache = {}
setmetatable(Player,
	{
		__call = function(self, ply)
			local data = {}

			local t = type(ply)
			if t == "table" then
				data = ply
			elseif t == "string" then
				if not idCache[ply] then
					for i, pl in ipairs(TDMP_GetPlayers()) do
						if pl.steamId == ply then
							idCache[ply] = pl.id
							data = TDMP_GetPlayer(pl.id)

							break
						end
					end
				else
					data = TDMP_GetPlayer(idCache[ply])
				end
			else
				data = TDMP_GetPlayer(ply)
			end

			return setmetatable(data, Player)
		end
	}
)