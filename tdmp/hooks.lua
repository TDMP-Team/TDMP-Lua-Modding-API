--[[-------------------------------------------------------------------------
Hooks allows you to "talk" with other lua statements(mods).
Hooks aren't synced, so they're running only on your local machine
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamId then return end

#include "json.lua"

function Hook_Run(eventName, data, noPack)
	data = data or ""
	TDMP_RunGlobalHook(eventName, noPack and tostring(data) or data ~= "" and json.encode(data) or "")
end

function Hook_AddListener(eventName, id, callback)
	TDMP_AddGlobalHookListener(eventName, id, callback)
end