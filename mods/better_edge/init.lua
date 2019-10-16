local limit = 1500

local players = {}

minetest.register_on_joinplayer(function(player)
	players[player:get_player_name()] = player:get_pos()	
end)

minetest.register_on_leaveplayer(function(player)
	if player then
		players[player:get_player_name()] = nil
	end
end)

local timer = 0

local function is_pos_valid(pos)
	local valid = true
                for _,val in pairs(pos) do
                	if val > limit or val < -limit then
                        	valid = false
			end
        	end
	return valid
end

local function get_valid_pos(pos)
	newpos = {}
	for i,val in pairs(pos) do
		if val > limit then
			newpos[i] = limit-1
		else
			newpos[i] = val
		end
		if val < -limit then
			newpos[i] = -limit+1
		end
	end
	return newpos
end

minetest.register_globalstep(function(dtime)
	if dtime then
		timer = timer + dtime
		if timer >= 5 then
			for _, player in pairs(minetest.get_connected_players()) do
				if not players[player:get_player_name()] then
					players[player:get_player_name()] = player:get_pos()
				end
				local pos = player:get_pos()
				if not is_pos_valid(pos) then
					minetest.chat_send_player(player:get_player_name(), "Thou fool, to explore beyond the four corners of the world...")
					if is_pos_valid(players[player:get_player_name()]) then
						player:set_pos(players[player:get_player_name()])			
					else
						player:set_pos(get_valid_pos(player:get_pos()))
					end
				end
				players[player:get_player_name()] = player:get_pos()
			end
			timer = 0
		end
	end
end)
