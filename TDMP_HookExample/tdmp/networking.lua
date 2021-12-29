--[[-------------------------------------------------------------------------
Simple functions for networking stuff
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamId then return end

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
end

--[[-------------------------------------------------------------------------
Client sends event to the server
---------------------------------------------------------------------------]]
function TDMP_ClientStartEvent(eventName, eventData)
	assert(eventName, "eventName is nil!")

	TDMP_SendEvent(eventName, nil, eventData.Reliable, eventData.Data and (eventData.DontPack and tostring(eventData.Data) or json.encode(eventData.Data)) or "")
end