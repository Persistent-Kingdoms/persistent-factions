local chat_reasons = {}
chat_reasons.set_hp = {
    "mysteriously vanishes"
}
chat_reasons.punch = {
    "was sliced' and diced' by",
    "got pwned by",
    "got a-salt-ed by",
}
chat_reasons.node_damage = {
    "played with fire",
    "took a bath in lava",
    "ate a chili-pepper",
}
chat_reasons.fall = {
    "hit the ground to hard",
    "fell into the abyss",
    "walked off a cliff",
}
chat_reasons.drown = {
    "fell asleep in the tub",
    "blew one to many bubbles",
    "tried to drink the ocean",
}

minetest.register_on_dieplayer(function(obj, reason)
    if reason.type and chat_reasons[reason.type] then
        local killer = ""
        local news = ""
        if reason.object then
            killer = reason.object:get_player_name()
            news = " BREAKING NEWS: Local man \"" .. obj:get_player_name() .. "\" " .. chat_reasons[reason.type][math.random(1, #chat_reasons[reason.type])] .. "\"" .. killer .. "\"."
        else
            news = " BREAKING NEWS: Local man \"" .. obj:get_player_name() .. "\" " .. chat_reasons[reason.type][math.random(1, #chat_reasons[reason.type])] .. "."
        end
        print(news)

        local station = "[BBC News]"
        station = minetest.colorize("#a8659c", station)

        news = minetest.colorize("#7f99b1", news)

        minetest.chat_send_all(station .. news)
    end
end)


minetest.register_chatcommand("news", {
    privs = {
        ban = true
    },
    func = function(station, param)
        local station, news = string.match(param, "^([%d%a_-]+) ([%d%a%s%p%%_-]+)$")
        local bool = string.sub(param, -1, -1)

        if station and news then
            --print(station, news, bool)
                
            station = minetest.colorize("#a8659c", "[" .. string.upper(station) .. " News" .. "]")
            
            if bool and bool == "$" then
                news = string.sub(news, 1, #news-1)
                news = "BREAKING NEWS: " .. news
            end
        
            news = minetest.colorize("#7f99b1", news)

            minetest.chat_send_all(station .. " " .. news)
        else
            local station = "[BBC News] "
            station = minetest.colorize("#a8659c", station)

            local news = "BREAKING NEWS: salt levels rise on PK."
            news = minetest.colorize("#7f99b1", news)

            minetest.chat_send_all(station .. news)
        end
    end
})