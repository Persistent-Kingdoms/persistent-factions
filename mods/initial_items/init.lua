local items = {
	"farming:seed_wheat 5",
	"default:pick_stone",
	"default:apple 20",
	"default:sapling 3",
	"craftguide:book",
	"boats:boat",
	"default:papyrus 8",
}

minetest.register_on_newplayer(function(player)
	local inv = player:get_inventory()
	for _, item in ipairs(items) do
		inv:add_item("main", item)
	end
end)
