--
-- Minetest advmarkers mod
--
-- © 2019 by luk3yx
--

advmarkers = {
    dated_death_markers = false
}

-- Get the mod storage
local storage = minetest.get_mod_storage()
local hud = {}
advmarkers.last_coords = {}

-- Convert positions to/from strings
local function pos_to_string(pos)
    if type(pos) == 'table' then
        pos = minetest.pos_to_string(vector.round(pos))
    end
    if type(pos) == 'string' then
        return pos
    end
end

local function string_to_pos(pos)
    if type(pos) == 'string' then
        pos = minetest.string_to_pos(pos)
    end
    if type(pos) == 'table' then
        return vector.round(pos)
    end
end

-- Get player name or object
local get_player_by_name    = minetest.get_player_by_name
local get_connected_players = minetest.get_connected_players
if minetest.get_modpath('cloaking') then
    get_player_by_name      = cloaking.get_player_by_name
    get_connected_players   = cloaking.get_connected_players
end

local function get_player(player, t)
    local name
    if type(player) == 'string' then
        name = player
        if t ~= 0 then
            player = get_player_by_name(name)
        end
    else
        name = player:get_player_name()
    end
    if t == 0 then
        return name
    elseif t == 1 then
        return player
    end
    return name, player
end

-- Set the HUD position
function advmarkers.set_hud_pos(player, pos, title)
    local name, player = get_player(player)
    pos = string_to_pos(pos)
    if not player or not pos then return end
    if not title then
        title = pos.x .. ', ' .. pos.y .. ', ' .. pos.z
    end
    if hud[player] then
        player:hud_change(hud[player], 'name',      title)
        player:hud_change(hud[player], 'world_pos', pos)
    else
        hud[player] = player:hud_add({
            hud_elem_type = 'waypoint',
            name          = title,
            text          = 'm',
            number        = 0xbf360c,
            world_pos     = pos
        })
    end
    minetest.chat_send_player(name, 'Waypoint set to ' .. title)
    return true
end

-- Get and save player storage
local function get_storage(name)
    name = get_player(name, 0)
    return minetest.deserialize(storage:get_string(name)) or {}
end

local function save_storage(name, data)
    name = get_player(name, 0)
    if type(data) == 'table' then
        data = minetest.serialize(data)
    end
    if type(data) ~= 'string' then return end
    if #data > 0 then
        storage:set_string(name, data)
    else
        storage:set_string(name, '')
    end
    return true
end

-- Add a waypoint
function advmarkers.set_waypoint(player, pos, name)
    pos = pos_to_string(pos)
    if not pos then return end
    local data = get_storage(player)
    data['marker-' .. tostring(name)] = pos
    return save_storage(player, data)
end
advmarkers.set_marker = advmarkers.set_waypoint

-- Delete a waypoint
function advmarkers.delete_waypoint(player, name)
    local data = get_storage(player)
    data['marker-' .. tostring(name)] = nil
    return save_storage(player, data)
end
advmarkers.delete_marker = advmarkers.delete_waypoint

-- Get a waypoint
function advmarkers.get_waypoint(player, name)
    local data = get_storage(player)
    return string_to_pos(data['marker-' .. tostring(name)])
end
advmarkers.get_marker = advmarkers.get_waypoint

-- Rename a waypoint and re-interpret the position.
function advmarkers.rename_waypoint(player, oldname, newname)
    player = get_player(player, 0)
    oldname, newname = tostring(oldname), tostring(newname)
    local pos = advmarkers.get_waypoint(player, oldname)
    if not pos or not advmarkers.set_waypoint(player, pos, newname) then
        return
    end
    if oldname ~= newname then
        advmarkers.delete_waypoint(player, oldname)
    end
    return true
end
advmarkers.rename_marker = advmarkers.rename_waypoint

-- Get waypoint names
function advmarkers.get_waypoint_names(name, sorted)
    local data = get_storage(name)
    local res = {}
    for name, pos in pairs(data) do
        if name:sub(1, 7) == 'marker-' then
            table.insert(res, name:sub(8))
        end
    end
    if sorted or sorted == nil then table.sort(res) end
    return res
end
advmarkers.get_marker_names = advmarkers.get_waypoint_names

-- Display a waypoint
function advmarkers.display_waypoint(player, name)
    return advmarkers.set_hud_pos(player, advmarkers.get_waypoint(player, name),
        name)
end
advmarkers.display_marker = advmarkers.display_waypoint

-- Export waypoints
function advmarkers.export(player, raw)
    local s = get_storage(player)
    if raw == 'M' then
        s = minetest.compress(minetest.serialize(s))
        s = 'M' .. minetest.encode_base64(s)
    elseif not raw then
        s = minetest.compress(minetest.write_json(s))
        s = 'J' .. minetest.encode_base64(s)
    end
    return s
end

-- Import waypoints - Note that this won't import strings made by older
--  versions of the CSM.
function advmarkers.import(player, s)
    if type(s) ~= 'table' then
        if s:sub(1, 1) ~= 'J' then return end
        s = minetest.decode_base64(s:sub(2))
        local success, msg = pcall(minetest.decompress, s)
        if not success then return end
        s = minetest.parse_json(msg)
    end

    -- Iterate over waypoints to preserve existing ones and check for errors.
    if type(s) == 'table' then
        local data = get_storage(player)
        for name, pos in pairs(s) do
            if type(name) == 'string' and type(pos) == 'string' and
              name:sub(1, 7) == 'marker-' and minetest.string_to_pos(pos) and
              data[name] ~= pos then
                -- Prevent collisions
                local c = 0
                while data[name] and c < 50 do
                    name = name .. '_'
                    c = c + 1
                end

                -- Sanity check
                if c < 50 then
                    data[name] = pos
                end
            end
        end
        return save_storage(player, data)
    end
end

-- Get the waypoints formspec
local formspec_list = {}
local selected_name = {}
function advmarkers.display_formspec(player)
    player = get_player(player, 0)
    if not get_player_by_name(player) then return end
    local formspec = 'size[5.25,8]' ..
                     'label[0,0;Waypoint list]' ..
                     'button_exit[0,7.5;1.3125,0.5;display;Display]' ..
                     'button[1.3125,7.5;1.3125,0.5;teleport;Teleport]' ..
                     'button[2.625,7.5;1.3125,0.5;rename;Rename]' ..
                     'button[3.9375,7.5;1.3125,0.5;delete;Delete]' ..
                     'textlist[0,0.75;5,6;marker;'

    -- Iterate over all the waypoints
    local selected = 1
    formspec_list[player] = advmarkers.get_waypoint_names(player)

    for id, name in ipairs(formspec_list[player]) do
        if id > 1 then formspec = formspec .. ',' end
        if not selected_name[player] then selected_name[player] = name end
        if name == selected_name[player] then selected = id end
        formspec = formspec .. '##' .. minetest.formspec_escape(name)
    end

    -- Close the text list and display the selected waypoint position
    formspec = formspec .. ';' .. tostring(selected) .. ']'
    if selected_name[player] then
        local pos = advmarkers.get_waypoint(player, selected_name[player])
        if pos then
            pos = minetest.formspec_escape(tostring(pos.x) .. ', ' ..
            tostring(pos.y) .. ', ' .. tostring(pos.z))
            pos = 'Waypoint position: ' .. pos
            formspec = formspec .. 'label[0,6.75;' .. pos .. ']'
        end
    else
        -- Draw over the buttons
        formspec = formspec .. 'button_exit[0,7.5;5.25,0.5;quit;Close dialog]' ..
            'label[0,6.75;No waypoints. Add one with "/add_wp".]'
    end

    -- Display the formspec
    return minetest.show_formspec(player, 'advmarkers-ssm', formspec)
end

-- Get waypoint position
function advmarkers.get_chatcommand_pos(player, pos)
    local pname = get_player(player, 0)

    -- Validate the position
    if pos == 'h' or pos == 'here' then
        pos = get_player(player, 1):get_pos()
    elseif pos == 't' or pos == 'there' then
        if not advmarkers.last_coords[pname] then
            return false, 'No-one has used ".coords" and you have not died!'
        end
        pos = advmarkers.last_coords[pname]
    else
        pos = string_to_pos(pos)
        if not pos then
            return false, 'Invalid position!'
        end
    end
    return pos
end

local function register_chatcommand_alias(old, ...)
    local def = assert(minetest.registered_chatcommands[old])
    def.name = nil
    for i = 1, select('#', ...) do
        minetest.register_chatcommand(select(i, ...), table.copy(def))
    end
end

-- Open the waypoints GUI
local csm_key = string.char(1) .. 'ADVMARKERS_SSCSM' .. string.char(1)
minetest.register_chatcommand('mrkr', {
    params      = '',
    description = 'Open the advmarkers GUI',
    func = function(pname, param)
        if param:sub(1, #csm_key) == csm_key then
            -- SSCSM communication
            param = param:sub(#csm_key + 1)
            local cmd = param:sub(1, 1)

            if cmd == 'D' then
                -- D: Delete
                advmarkers.delete_waypoint(pname, param:sub(2))
            elseif cmd == 'S' then
                -- S: Set
                local s, e = param:find(' ')
                if s and e then
                    local pos = string_to_pos(param:sub(2, s - 1))
                    if pos then
                        advmarkers.set_waypoint(pname, pos, param:sub(e + 1))
                    end
                end
            elseif cmd == '0' then
                -- 0: Display
                if not advmarkers.display_waypoint(pname, param:sub(2)) then
                    minetest.chat_send_player(pname,
                        'Error displaying waypoint!')
                end
            end

            minetest.chat_send_player(pname, csm_key
                .. advmarkers.export(pname))
        elseif param == '' then
            advmarkers.display_formspec(pname)
        else
            local pos, err = advmarkers.get_chatcommand_pos(pname, param)
            if not pos then
                return false, err
            end
            if not advmarkers.set_hud_pos(pname, pos) then
                return false, 'Error setting the waypoint!'
            end
        end
    end
})

register_chatcommand_alias('mrkr', 'wp', 'wps', 'waypoint', 'waypoints')

-- Add a waypoint
minetest.register_chatcommand('add_mrkr', {
    params      = '<pos / "here" / "there"> <name>',
    description = 'Adds a waypoint.',
    func = function(pname, param)
        -- Get the parameters
        local s, e = param:find(' ')
        if not s or not e then
            return false, 'Invalid syntax! See /help add_mrkr for more info.'
        end
        local pos  = param:sub(1, s - 1)
        local name = param:sub(e + 1)

        -- Get the position
        local pos, err = advmarkers.get_chatcommand_pos(pname, pos)
        if not pos then
            return false, err
        end

        -- Validate the name
        if not name or #name < 1 then
            return false, 'Invalid name!'
        end

        -- Set the waypoint
        return advmarkers.set_waypoint(pname, pos, name), 'Done!'
    end
})

register_chatcommand_alias('add_mrkr', 'add_wp', 'add_waypoint')

-- Set the HUD
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pname, player = get_player(player)
    if formname == 'advmarkers-ignore' then
        return true
    elseif formname ~= 'advmarkers-ssm' then
        return
    end
    local name = false
    if fields.marker then
        local event = minetest.explode_textlist_event(fields.marker)
        if event.index then
            name = formspec_list[pname][event.index]
        end
    else
        name = selected_name[pname]
    end

    if name then
        if fields.display then
            if not advmarkers.display_waypoint(player, name) then
                minetest.chat_send_player(pname, 'Error displaying waypoint!')
            end
        elseif fields.rename then
            minetest.show_formspec(pname, 'advmarkers-ssm', 'size[6,3]' ..
                'label[0.35,0.2;Rename waypoint]' ..
                'field[0.3,1.3;6,1;new_name;New name;' ..
                minetest.formspec_escape(name) .. ']' ..
                'button[0,2;3,1;cancel;Cancel]' ..
                'button[3,2;3,1;rename_confirm;Rename]')
        elseif fields.rename_confirm then
            if fields.new_name and #fields.new_name > 0 then
                if advmarkers.rename_waypoint(pname, name, fields.new_name) then
                    selected_name[pname] = fields.new_name
                else
                    minetest.chat_send_player(pname, 'Error renaming waypoint!')
                end
                advmarkers.display_formspec(pname)
            else
                minetest.chat_send_player(pname,
                    'Please enter a new name for the waypoint.'
                )
            end
        elseif fields.teleport then
            minetest.show_formspec(pname, 'advmarkers-ssm', 'size[6,2.2]' ..
                'label[0.35,0.25;' .. minetest.formspec_escape(
                    'Teleport to a waypoint\n - ' .. name
                ) .. ']' ..
                'button[0,1.25;3,1;cancel;Cancel]' ..
                'button_exit[3,1.25;3,1;teleport_confirm;Teleport]')
        elseif fields.teleport_confirm then
            -- Teleport with /teleport
            local pos = advmarkers.get_waypoint(pname, name)
            if not pos then
                minetest.chat_send_player(pname, 'Error teleporting to waypoint!')
            elseif minetest.check_player_privs(pname, 'teleport') then
                player:set_pos(pos)
                minetest.chat_send_player(pname, 'Teleported to waypoint "' ..
                    name .. '".')
            else
                minetest.chat_send_player(pname, 'Insufficient privileges!')
            end
        elseif fields.delete then
            minetest.show_formspec(pname, 'advmarkers-ssm', 'size[6,2]' ..
                'label[0.35,0.25;Are you sure you want to delete this waypoint?]' ..
                'button[0,1;3,1;cancel;Cancel]' ..
                'button[3,1;3,1;delete_confirm;Delete]')
        elseif fields.delete_confirm then
            advmarkers.delete_waypoint(pname, name)
            selected_name[pname] = nil
            advmarkers.display_formspec(pname)
        elseif fields.cancel then
            advmarkers.display_formspec(pname)
        elseif name ~= selected_name[pname] then
            selected_name[pname] = name
            if not fields.quit then
                advmarkers.display_formspec(pname)
            end
        end
    elseif fields.display or fields.delete then
        minetest.chat_send_player(pname, 'Please select a waypoint.')
    end
    return true
end)

-- Auto-add waypoints on death.
minetest.register_on_dieplayer(function(player)
    local name
    if advmarkers.dated_death_markers then
        name = os.date('Death on %Y-%m-%d %H:%M:%S')
    else
        name = 'Death waypoint'
    end
    local pos  = player:get_pos()
    advmarkers.last_coords[player] = pos
    advmarkers.set_waypoint(player, pos, name)
    minetest.chat_send_player(player:get_player_name(),
        'Added waypoint "' .. name .. '".')
end)

-- Allow string exporting
minetest.register_chatcommand('mrkr_export', {
    params      = '',
    description = 'Exports an advmarkers string containing all your waypoints.',
    func = function(name, param)
        local export
        if param == 'old' then
            export = advmarkers.export(name, 'M')
        else
            export = advmarkers.export(name)
        end
        minetest.show_formspec(name, 'advmarkers-ignore',
            'field[_;Your waypoint export string;' ..
            minetest.formspec_escape(export) .. ']')
    end
})

register_chatcommand_alias('mrkr_export', 'wp_export', 'waypoint_export')

-- String importing
minetest.register_chatcommand('mrkr_import', {
    params      = '<advmarkers string>',
    description = 'Imports an advmarkers string. This will not overwrite ' ..
        'existing waypoints that have the same name.',
    func = function(name, param)
        if advmarkers.import(name, param) then
            return true, 'Waypoints imported!'
        else
            return false, 'Invalid advmarkers string!'
        end
    end
})

register_chatcommand_alias('mrkr_export', 'wp_import', 'waypoint_import')

-- Chat channels .coords integration.
-- You do not need to have chat channels installed for this to work.
local function get_coords(msg, strict)
    local s = 'Current Position: %-?[0-9]+, %-?[0-9]+, %-?[0-9]+%.'
    if strict then
        s = '^' .. s
    end
    local s, e = msg:find(s)
    local pos = false
    if s and e then
        pos = string_to_pos(msg:sub(s + 18, e - 1))
    end
    return pos
end

-- Get global co-ords
table.insert(minetest.registered_on_chat_messages, 1, function(name, msg)
    if msg:sub(1, 1) == '/' then return end
    local pos = get_coords(msg, true)
    if pos then
        advmarkers.last_coords = {}
        for _, player in ipairs(get_connected_players()) do
            advmarkers.last_coords[player:get_player_name()] = pos
        end
    end
end)

-- Override chat_send_player to get PMed co-ords etc
local old_chat_send_player = minetest.chat_send_player
function minetest.chat_send_player(name, msg, ...)
    if type(name) == 'string' and type(msg) == 'string' and
      get_player_by_name(name) then
        local pos = get_coords(msg)
        if pos then
            advmarkers.last_coords[name] = pos
        end
    end
    return old_chat_send_player(name, msg, ...)
end

-- Clean up variables if a player leaves
minetest.register_on_leaveplayer(function(player)
    local name = get_player(player, 0)
    hud[name]                       = nil
    formspec_list[name]             = nil
    selected_name[name]             = nil
    advmarkers.last_coords[name]    = nil
end)

-- Add '/mrkrthere'
minetest.register_chatcommand('mrkrthere', {
    params      = '',
    description = 'Alias for "/mrkr there".',
    func = function(name, param)
        return minetest.registered_chatcommands['mrkr'].func(name, 'there')
    end
})

-- SSCSM support
if minetest.global_exists('sscsm') and sscsm.register then
    sscsm.register({
        name = 'advmarkers',
        file = minetest.get_modpath('advmarkers') .. '/sscsm.lua',
    })
end
