--[[-------------------------------------------------------------------------
Simple functions for networking stuff
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamID then return end

#include "json.lua"

TDMP = TDMP or {}
TDMP.Enums = {
	Receiver = {
		All = 1, -- Everyone including server
		ClientsOnly = 2, -- Everyone excluding server
	}
}

--[[-------------------------------------------------------------------------
Event structure:

(SERVER ONLY)
Receiver = Who'd receive event?
	"all" - broadcast event to all clients
	"steamid" - send event only to client with this steamid
	{"table", "of", "steamids"} - send event to each client in this table

(SHARED)
Reliable[bool] - If set to false/nil/not filled, the message is not guaranteed to reach its destination or reach in sending order.
Keep it as true in very important data (such as shots, chat, etc), and keep it false/nil/not filled with not important data (such as physics)

(optional)Data - table of custom data to be sent

(optional)DontPack[bool] - if set to true, Data field wont be packed in json, instead, it would be turned into a string.
Useful for network performance, if you need to send only bool, number or something what doesn't really need to be packed into a table
---------------------------------------------------------------------------]]

--[[-------------------------------------------------------------------------
Server sends/broadcasts event to client(s)
---------------------------------------------------------------------------]]
function TDMP_ServerStartEvent(eventName, eventData)
	assert(eventName, "eventName is nil!")
	assert(eventData.Receiver, "receiver is nil! (" .. eventName .. ")")

	local data = eventData.Data and (eventData.DontPack and tostring(eventData.Data) or json.encode(eventData.Data)) or ""

	local t = type(eventData.Receiver)
	if t == "number" then
		TDMP_BroadcastEvent(eventName, eventData.Reliable, eventData.Receiver == TDMP.Enums.Receiver.All, data)
	elseif t == "string" then
		TDMP_SendEvent(eventName, eventData.Receiver, eventData.Reliable, data)
	elseif t == "table" then
		for i, steamId in ipairs(eventData.Receiver) do
			TDMP_SendEvent(eventName, steamId, eventData.Reliable, data)
		end
	else
		error("Unknown type in TDMP_ServerStartEvent(".. eventName .. "): " .. t)
	end

	return data
end

--[[-------------------------------------------------------------------------
Client sends event to the server
---------------------------------------------------------------------------]]
function TDMP_ClientStartEvent(eventName, eventData)
	assert(eventName, "eventName is nil!")

	local data = eventData.Data and (eventData.DontPack and tostring(eventData.Data) or json.encode(eventData.Data)) or ""
	TDMP_SendEvent(eventName, nil, eventData.Reliable, data)

	return data
end

--[[-------------------------------------------------------------------------
Spawns an entity for all clients. SERVER ONLY
---------------------------------------------------------------------------]]
function TDMP_Spawn(hookName, xml, transform, allowStatic, jointExisting)
	if not TDMP_IsServer() then return end

	if #xml > 1024 then DebugPrint("XML is too big! (" .. #xml .. "/1024)") TDMP_Print("XML is too big! (" .. #xml .. "/1024)") return end

	local data = {xml, transform or Transform(), allowStatic or false, jointExisting or false, {}, hookName}

	local ents = Spawn(xml, transform, allowStatic, jointExisting)
	local netIds = {}
	for i, ent in ipairs(ents) do
		if not HasTag(ent, "tdmpIgnore") then
			local type = GetEntityType(ent)
			if type == "body" then
				local iStr = tostring(i)
				netIds[iStr] = TDMP_RegisterNetworkBody(ent)
			elseif type == "vehicle" then
				local iStr = tostring(i)
				netIds[iStr] = TDMP_RegisterNetworkVehicle(ent)
			elseif type == "shape" then
				local iStr = tostring(i)
				netIds[iStr] = TDMP_RegisterNetworkShape(ent)
			end
		end
	end

	data[5] = netIds

	TDMP_ServerStartEvent("SpawnGlobal", {
		Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
		Reliable = true,

		DontPack = false,
		Data = data
	})

	return ents
end

function TDMP_ReceiveSpawn(data)
	data = json.decode(data)

	local ents = Spawn(data[1], data[2], data[3], data[4])
	local netIds = data[5] or {}
	for i, ent in ipairs(ents) do
		local type = GetEntityType(ent)
		if type == "body" then
			local iStr = tostring(i)
			netIds[iStr] = TDMP_RegisterNetworkBody(ent, netIds[iStr])
		elseif type == "vehicle" then
			local iStr = tostring(i)
			netIds[iStr] = TDMP_RegisterNetworkVehicle(ent, netIds[iStr])
		elseif type == "shape" then
			local iStr = tostring(i)
			netIds[iStr] = TDMP_RegisterNetworkShape(ent, netIds[iStr])
		end
	end
end

-- local lastShapeNetworkId = 0
-- shapeIdToNetworkId = {}
-- networkIdToShape = {}
-- function TDMP_RegisterNetworkShape(shape, netId)
-- 	if not netId then
-- 		netId = lastShapeNetworkId

-- 		lastShapeNetworkId = lastShapeNetworkId + 1
-- 	end

-- 	shapeIdToNetworkId[shape] = netId
-- 	networkIdToShape[netId] = shape

-- 	return netId
-- end

-- function TDMP_GetShapeNetworkId(shape)
-- 	return shapeIdToNetworkId[shape]
-- end

-- function TDMP_GetShapeByNetworkId(networkId)
-- 	return networkIdToShape[networkId]
-- end