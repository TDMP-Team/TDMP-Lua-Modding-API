--[[-------------------------------------------------------------------------
Hooks allows you to "talk" with other lua statements(mods).
Hooks aren't synced, so they're running only on your local machine
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamId then return end

#include "json.lua"

function Hook_Run(hookName, hookData)
	TDMP_RunGlobalHook(hookName, hookData and json.encode(hookData) or "")
end

function Hook_AddListener(hook, hookName, callback)
	TDMP_AddGlobalHookListener(hook, hookName, callback)
end