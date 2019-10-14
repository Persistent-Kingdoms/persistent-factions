# lava_ore_gen

This mod makes the lava turn stone into ore over time. When lava comes in contact with stone it turns red hot. After a specific time it turns into ore.

# api

lava_ore_gen.blacklist is a table where you can blacklist node names by listing them in the table.

Example code:

``` lua
lava_ore_gen.blacklist["default:stone_with_iron"] = true
```


# config

The stone node name to override.
``` lua
lava_ore_gen.stone_name = "default:stone"
```

fixed interval of when to change stone to ore.
``` lua
lava_ore_gen.interval = 20
```


random chance of when to change stone to ore.
``` lua
lava_ore_gen.chance = 3600
```

Make ores random instead of being based on how rare they are.
``` lua
lava_ore_gen.random = false
```
