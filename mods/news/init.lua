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
        end
    end
})