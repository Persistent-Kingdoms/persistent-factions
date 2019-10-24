local players_position = {}

local timer = tonumber(minetest.settings:get("latency_protection.timer")) or 20
local jitter_max = tonumber(minetest.settings:get("latency_protection.jitter_max")) or 1.5

local function step()
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local info = minetest.get_player_information(name)
		if not players_position[name].protection_violation and info.avg_jitter <= jitter_max then
			players_position[name].pos = player:get_pos()
		else
			players_position[name].protection_violation = false
		end
	end
	minetest.after(timer, step)
end

minetest.register_on_joinplayer(function(player)
	players_position[player:get_player_name()] = {pos = player:get_pos(), protection_violation = false}
end)

minetest.register_on_leaveplayer(function(player)
	players_position[player:get_player_name()] = nil
end)

minetest.after(timer, step)

-- It has to register later for it to work.
minetest.register_on_mods_loaded(function()
	local old_is_protected = minetest.is_protected

	function minetest.is_protected(pos, name)
		local results = old_is_protected(pos, name)
		if results then
			minetest.get_player_by_name(name):set_pos(players_position[name].pos)
			players_position[name].protection_violation = true
		end
		return results
	end
end)
