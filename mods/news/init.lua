news = {}

news.chat_reasons = {}
news.chat_reasons.nodes = {}
news.chat_reasons.groups = {}
news.chat_reasons.set_hp = {
    "mysteriously vanishes",
    "gave up on life",
    "evaporated into nothingness",
}
news.chat_reasons.punch = {
    "was sliced' and diced' by",
    "got pwned by",
    "got a-salt-ed by",
}
news.chat_reasons.fall = {
    "hit the ground to hard",
    "fell into the abyss",
    "walked off a cliff",
}
news.chat_reasons.drown = {
    "fell asleep in the tub",
    "blew one to many bubbles",
    "tried to drink the ocean",
}

minetest.register_privilege("news_report", {give_to_admin = true})

function news.register_deathmsg_tbl(type, name, msgs)
    if not (type or name or msgs) then
        return
    end

    if news.chat_reasons[type] then
        news.chat_reasons[type][name] = msgs
    end
end

minetest.register_on_dieplayer(function(obj, reason)
    if reason.type then
        local killer = ""
        local news_msg = ""
        local reason_msg = ""
        local player = obj:get_player_name()
        local node = minetest.registered_nodes[reason.node]
        local num = nil

        if reason.type == "node_damage" and node then
            if node and news.chat_reasons.nodes[node.name] and #news.chat_reasons.nodes[node.name] > 0 then
                num = math.random(1, #news.chat_reasons.nodes[node.name])
                reason_msg = news.chat_reasons.nodes[node.name][num]
            elseif node and node.groups then
                for _, groupname in pairs(node.groups) do
                    if news.chat_reasons.groups[groupname] and #news.chat_reasons.groups[groupname] > 0 then
                        num = math.random(1, #news.chat_reasons.groups[groupname])
                        reason_msg = news.chat_reasons.groups[groupname][num]
                        break
                    end
                end
            end
        elseif news.chat_reasons[reason.type] and #news.chat_reasons[reason.type] > 0 then
            num = math.random(1, #news.chat_reasons[reason.type])
            reason_msg = news.chat_reasons[reason.type][num]
        end

        if reason.object then
            if reason.object:is_player() then
                killer = reason.object:get_player_name()
            else
                killer = reason.object:get_luaentity().name
            end

            news_msg = " BREAKING NEWS: Local player \"" .. player .. "\" " .. reason_msg .. " \"" .. killer .. "\"."
        elseif reason_msg ~= "" then
            news_msg = " BREAKING NEWS: Local player \"" .. player .. "\" " .. reason_msg .. "."
        end

        if reason_msg ~= "" then
            local station = "[BBC News]"
            station = minetest.colorize("#a8659c", station)

            news_msg = minetest.colorize("#7f99b1", news_msg)

            minetest.chat_send_all(station .. news_msg)
        end
    end
end)


minetest.register_chatcommand("news", {
    privs = {
        news_report = true
    },
    func = function(station, param)
        local station, news_msg = string.match(param, "^([%d%a_-]+) ([%d%a%s%p%%_-]+)$")
        local bool = string.sub(param, -1, -1)

        if station and news_msg then
                
            station = minetest.colorize("#a8659c", "[" .. string.upper(station) .. " News" .. "]")
            
            if bool and bool == "$" then
                news_msg = "BREAKING NEWS: " .. string.sub(news_msg, 1, #news_msg - 1)
            end
        
            news_msg = minetest.colorize("#7f99b1", news_msg)

            minetest.chat_send_all(station .. " " .. news_msg)
        else
            local station = "[BBC News] "
            station = minetest.colorize("#a8659c", station)

            local news_msg = "BREAKING NEWS: Salt levels rising."
            news_msg = minetest.colorize("#7f99b1", news_msg)

            minetest.chat_send_all(station .. news_msg)
        end
    end
})

local lava_death_msgs = {
    "melted into a ball of fire",
    "couldn't resist the warm glow of lava",
    "dug straight down",
}
news.register_deathmsg_tbl("nodes", "default:lava_source", lava_death_msgs)
news.register_deathmsg_tbl("nodes", "default:lava_flowing", lava_death_msgs)