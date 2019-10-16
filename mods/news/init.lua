news = {}

news.chat_reasons = {}
news.chat_reasons.nodes = {}
news.chat_reasons.groups = {}
news.chat_reasons.set_hp = {
    "mysteriously vanishes"
}
news.chat_reasons.punch = {
    "was sliced' and diced' by",
    "got pwned by",
    "got a-salt-ed by",
}
news.chat_reasons.node_damage = {
    "played with fire",
    "took a bath in lava",
    "ate a chili-pepper",
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

function news.register_deathmsg_tbl(type, name, msgs)
    if not (type or name or msgs) then
        return
    end

    if news.chat_reasons[type] then
        news.chat_reasons[type][name] = msgs
    end
end

minetest.register_on_dieplayer(function(obj, reason)
    if reason.type and news.chat_reasons[reason.type] then
        local killer = ""
        local news_msg = ""
        local reason_msg = ""
        local player = obj:get_player_name()
        local node = minetest.registered_nodes[minetest.get_node(obj:get_pos()).name]
        local num = nil
        print(node.name)

        if reason.type == "node_damage" then
            --print("is node_damage")
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

            news_msg = " BREAKING NEWS: Local man \"" .. player .. "\" " .. reason_msg .. " \"" .. killer .. "\"."
        else
            news_msg = " BREAKING NEWS: Local man \"" .. player .. "\" " .. reason_msg .. "."
        end

        local station = "[BBC News]"
        station = minetest.colorize("#a8659c", station)

        news_msg = minetest.colorize("#7f99b1", news_msg)

        minetest.chat_send_all(station .. news_msg)
    end
end)


minetest.register_chatcommand("news", {
    privs = {
        ban = true
    },
    func = function(station, param)
        local station, news_msg = string.match(param, "^([%d%a_-]+) ([%d%a%s%p%%_-]+)$")
        local bool = string.sub(param, -1, -1)

        if station and news_msg then
            --print(station, news, bool)
                
            station = minetest.colorize("#a8659c", "[" .. string.upper(station) .. " News" .. "]")
            
            if bool and bool == "$" then
                news_msg = string.sub(news, 1, #news_msg-1)
                news_msg = "BREAKING NEWS: " .. news_msg
            end
        
            news_msg = minetest.colorize("#7f99b1", news_msg)

            minetest.chat_send_all(station .. " " .. news_msg)
        else
            local station = "[BBC News] "
            station = minetest.colorize("#a8659c", station)

            local news_msg = "BREAKING NEWS: salt levels rise on PK."
            news_msg = minetest.colorize("#7f99b1", news)

            minetest.chat_send_all(station .. news_msg)
        end
    end
})

news.register_deathmsg_tbl("nodes", "default:lava_source", 
{
    "melted into a ball of fire",
    "couldn't resist the warm glow of lava",
    "dug straight down"
})

news.register_deathmsg_tbl("nodes", 