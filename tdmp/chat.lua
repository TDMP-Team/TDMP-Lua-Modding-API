#include "hooks.lua"

function TDMP_AddChatMessage(...)
	local args = {...}
	for i, v in ipairs(args) do
		local t = type(v)
		if t == "table" then
			if v.steamid then -- making player table smaller
				v = {steamid = v.steamid, id = v.id}
			
			elseif not v.steamid and not v[1] then -- checking that not trying to send unknown table
				error("tried to send table in TDMP_AddChatMessage!")

				return
			end
		elseif t == "function" then
			error("tried to send function in TDMP_AddChatMessage!")
		end
	end

	Hook_Run("TDMP_ChatAddMessage", args)
end

function TDMP_SendChatMessage(message)
	TDMP_ClientStartEvent("TDMP_SendChatMessage", {
        Reliable = true,

        Data = {msg = message}
    })
end