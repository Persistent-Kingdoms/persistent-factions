# Minetest server-sent CSM proof-of-concept

[Source](https://git.minetest.land/luk3yx/sscsm)

Attempts to run server-sent CSMs locally in a sandbox.

## How it works

Any client with the CSM installed will automatically attempt to request SSCSMs
from the server via a mod channel. If the server has this mod installed, it
will reply with a few messages containing the mod name and partially minified
mod code. The CSM will then create a separate environment so SSCSMs cannot mess
with existing CSMs (and so CSMs do not accidentally interfere with SSCSMs), and
execute the SSCSMs inside this environment. *Note that it is trivial for users
to modify this environment.* The server-side mod sends two "built-in" SSCSMs
before and after all other SSCSMs to add extra helper functions (in the `sscsm`
namespace), to execute `register_on_mods_loaded` callbacks and attempt to leave
the mod channel.

## Instructions

To create a SSCSM:

 - Install this mod onto a server.
 - Enable mod channels on the server (add `enable_mod_channels = true` to
     minetest.conf).
 - Create SSCSMs with the API.
 - Install the CSM (in the `csm/` directory) onto clients and enable it.

### Preserving copyright and license notices

The minifier preserves comments starting with "copyright" or "license":
(case-insensitive, excluding leading spaces).

Input:

```lua
-- Copyright: 1
-- License: 2
-- A normal comment.
--COPYRIGHT5

...
```

Output:

```lua
-- Copyright: 1
-- License: 2
--COPYRIGHT5
...
```

## Server-side mod facing API

*This API is subject to change.*

### `sscsm.register(def)`

Registers a server-provided CSM with the following definition table.

 - `name` *(string)*: The name of the server-provided CSM. Please use the
        `modname:sscsmname` convention. Cannot start with a colon or contain
        newlines.
 - `code` *(string)*: The code to be sent to clients.
 - `file` *(string)*: The file to read the code from, read during the
        `register()` call.
 - `depends` *(list)*: A list of SSCSMs that must be loaded before this one.

This definition table must have `name` and either `code` or `file`.

#### Maximum SSCSM size

Because of Minetest network protocol limitations, the amount of data that can
be sent over mod channels is limited, and therefore the maximum SSCSM size is
65300 (to leave room for the player name and future expansion). The name of the
SSCSM also counts towards this total.

Because of this size limitation, SSCSMs are passed through a primitive code
minifier that removes some whitespace and comments, so even if your code is
above this size limit it could still work.

## Server-sent CSM facing API

SSCSMs can access most functions on [client_lua_api.txt](https://github.com/minetest/minetest/blob/master/doc/client_lua_api.txt), as well as a separate `sscsm` namespace:

 - `sscsm.global_exists(name)`: The same as `minetest.global_exists`.
 - `sscsm.register_on_mods_loaded(callback)`: Runs the callback once all SSCSMs
    are loaded.
 - `sscsm.register_chatcommand(...)`: Similar to
    `minetest.register_chatcommand`, however overrides commands starting in `/`
    instead. This can be used to make some commands have instantaneous
    responses. The command handler is only added once `register_chatcommand`
    has been called.
 - `sscsm.unregister_chatcommand(name)`: Unregisters a chatcommand.
 - `sscsm.get_player_control()`: Returns a table similar to the server-side
    `player:get_player_control()`.
 - `sscsm.restriction_flags`: The `csm_restriction_flags` setting set in
    the server's `minetest.conf`.
 - `sscsm.restrictions`: A table based on `csm_restriction_flags`:
    - `chat_messages`: When `true`, SSCSMs can't send chat messages or run
        server chatcommands.
    - `read_itemdefs`: When `true`, SSCSMs can't read item definitions.
    - `read_nodedefs`: When `true`, SSCSMs can't read node definitions.
    - `lookup_nodes_limit`: When `true`, any get_node calls are restricted.
    - `read_playerinfo`: When `true`, `minetest.get_player_names()` will return
        `nil`.

To communicate with the server-side mods, it is possible to open a mod
channel.

### CSM restriction flags example

```lua
minetest.register_chatcommand('m', {
    description = 'Alias for /msg',
    func = function(param)
        if sscsm.restrictions.chat_messages then
            return false, 'Sorry, csm_restriction_flags prevents chat messages'
                .. ' from being sent.'
        end
        minetest.run_server_chatcommand('msg', param)
    end,
})
```

*Note that modifying `sscsm.restrictions` or `sscsm.restriction_flags` will
not add or remove restrictions and is not recommended.*

## Security considerations

Do not trust any input sent to the server via SSCSMs (and do not store
sensitive data in SSCSM code), as malicious users can and will inspect code and
modify the output from SSCSMs.

I repeat, **do not trust the client** and/or SSCSMs with any sensitive
information and do not trust any output from the client and/or SSCSMs. Make
sure to rerun any privilege checks on the server.

### Other recommendations

Although it is possible to kick clients that do not support SSCSMs, this has
not been implemented. Some users may not want to allow servers to automatically
download and run code locally for security reasons. Please try and make sure
clients without SSCSMs do not suffer from major functionality loss.
