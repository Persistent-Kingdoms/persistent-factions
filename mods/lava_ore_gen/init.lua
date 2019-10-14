lava_ore_gen = {}
lava_ore_gen.blacklist = {}

local stone_name = minetest.settings:get("lava_ore_gen.stone_name") or "default:stone"
local interval = tonumber(minetest.settings:get("lava_ore_gen.interval")) or 20
local chance = tonumber(minetest.settings:get("lava_ore_gen.chance")) or 3600
local random = minetest.settings:get_bool("lava_ore_gen.random") or false

local function create_hotstone()
	minetest.register_node("lava_ore_gen:stone_hot", {name = "lava_ore_gen:stone_hot"})
end
local function override_hotstone()
	local clonenodeForLava = {}
	for k, v in pairs(minetest.registered_nodes[stone_name]) do clonenodeForLava[k] = v end
	clonenodeForLava.name = "lava_ore_gen:stone_hot"
	clonenodeForLava.description = "Heated Stone"
	clonenodeForLava.groups.not_in_creative_inventory = 1
	clonenodeForLava.tiles = {"default_stone.png^[colorize:red:20"}
	clonenodeForLava.paramtype = "light"
	clonenodeForLava.light_source = 4
	clonenodeForLava.on_timer = function(pos)
		local node = minetest.find_node_near(pos, 1, {"group:lava"})
		if node then
			if not random then
				-- Get ores and rarities.
				local ore_map = {}
				for i, v in next, minetest.registered_ores do
					local name = v.ore
					if not lava_ore_gen.blacklist[name] then
						if string.match(name, ":stone_with_") or string.match(name, ":mineral_") then
							local rarity = v.clust_scarcity - math.random(0, v.clust_scarcity + 1)
							ore_map[i] = {rarity = rarity, name = name}
						end
					end
				end
				-- Do math to pick a ore.
				local ore = {rarity = -1, name = stone_name}
				for i, v in next, ore_map do
					if ore.rarity == -1 or ore.rarity > math.random(0, v.rarity) then
						ore = v
					end
				end
				minetest.set_node(pos, {name = ore.name})
			else
				local ore_map = {}
				for i, v in next, minetest.registered_ores do
					local name = v.ore
					if not lava_ore_gen.blacklist[name] then
						ore_map[#ore_map + 1] = name
					end
				end
				minetest.set_node(pos, {name = ore_map[math.random(1, #ore_map + 1)]})
			end
		else
			minetest.set_node(pos, {name = stone_name})
		end
		return true
	end
	minetest.register_node(":lava_ore_gen:stone_hot", clonenodeForLava)
end
local function override_stone()
	-- make stone floodable --
	minetest.override_item(stone_name, {
		floodable = true,
		on_flood = function(pos, oldnode, newnode)
			local def = minetest.registered_items[newnode.name]
			if (def and def.groups and def.groups.lava and def.groups.lava > 0) then
				minetest.after(0, function(pos)
					minetest.set_node(pos, {name = "lava_ore_gen:stone_hot"})
					minetest.get_node_timer(pos):start(interval + math.random(1, chance + 1))
				end, pos)
			else
				return true
			end
			return false
		end,
	})
end

create_hotstone()
minetest.register_on_mods_loaded(function()
	override_hotstone()
	override_stone()
end)
