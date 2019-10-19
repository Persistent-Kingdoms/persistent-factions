--
-- Minetest advmarkers SSCSM
--
-- Copyright © 2019 by luk3yx
-- License: https://git.minetest.land/luk3yx/advmarkers/src/branch/master/LICENSE.md
--

advmarkers = {}
local data = {}

assert(not sscsm.restrictions or not sscsm.restrictions.chat_messages,
    'The advmarkers SSCSM needs to be able to send chat messages!')

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

-- Run remote command
-- This is easier to do with chatcommands because servers cannot send mod
--  channel messages to specific clients.
local csm_key = string.char(1) .. 'ADVMARKERS_SSCSM' .. string.char(1)
local function run_remote_command(cmd, param)
    local msg = csm_key
    if cmd then
        msg = msg .. cmd
        if param then msg = msg .. param end
    end
    minetest.run_server_chatcommand('wp', msg)
end

-- Display a waypoint
function advmarkers.display_waypoint(name)
    name = tostring(name)
    if data['marker-' .. name] then
        run_remote_command('0', tostring(name))
        return true
    else
        return false
    end
end

-- Get a waypoint
function advmarkers.get_waypoint(name)
    return string_to_pos(data['marker-' .. tostring(name)])
end
advmarkers.get_marker = advmarkers.get_waypoint

-- Delete a waypoint
function advmarkers.delete_waypoint(name)
    name = tostring(name)
    if data['marker-' .. name] ~= nil then
        data['marker-' .. name] = nil
        run_remote_command('D', name)
    end
end
advmarkers.delete_marker = advmarkers.delete_waypoint

-- Set a waypoint
function advmarkers.set_waypoint(pos, name)
    pos = pos_to_string(pos)
    if not pos then return end
    name = tostring(name)
    data['marker-' .. name] = pos
    run_remote_command('S', pos:gsub(' ', '') .. ' ' .. name)
    return true
end
advmarkers.set_marker = advmarkers.set_waypoint

-- Rename a waypoint and re-interpret the position.
function advmarkers.rename_waypoint(oldname, newname)
    oldname, newname = tostring(oldname), tostring(newname)
    local pos = advmarkers.get_waypoint(oldname)
    if not pos or not advmarkers.set_waypoint(pos, newname) then return end
    if oldname ~= newname then
        advmarkers.delete_waypoint(oldname)
    end
    return true
end
advmarkers.rename_marker = advmarkers.rename_waypoint

-- Import waypoints - Note that this won't import strings made by older
--  versions of the CSM.
function advmarkers.import(s, clear)
    if type(s) ~= 'table' then
        if s:sub(1, 1) ~= 'J' then return end
        s = minetest.decode_base64(s:sub(2))
        local success, msg = pcall(minetest.decompress, s)
        if not success then return end
        s = minetest.parse_json(msg)
    end

    -- Iterate over waypoints to preserve existing ones and check for errors.
    if type(s) ~= 'table' then return end
    if clear then data = {} end
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
end

-- Get waypoint names
function advmarkers.get_waypoint_names(sorted)
    local res = {}
    for name, pos in pairs(data) do
        if name:sub(1, 7) == 'marker-' then
            table.insert(res, name:sub(8))
        end
    end
    if sorted or sorted == nil then table.sort(res) end
    return res
end

-- Display the formspec
local formspec_list = {}
local selected_name = false
function advmarkers.display_formspec()
    local formspec = 'size[5.25,8]' ..
                     'label[0,0;Waypoint list ' ..
                        minetest.colorize('#888888', '(SSCSM)') .. ']' ..
                     'button_exit[0,7.5;1.3125,0.5;display;Display]' ..
                     'button[1.3125,7.5;1.3125,0.5;teleport;Teleport]' ..
                     'button[2.625,7.5;1.3125,0.5;rename;Rename]' ..
                     'button[3.9375,7.5;1.3125,0.5;delete;Delete]' ..
                     'textlist[0,0.75;5,6;marker;'

    -- Iterate over all the markers
    local id = 0
    local selected = 1
    formspec_list = advmarkers.get_waypoint_names()
    for id, name in ipairs(formspec_list) do
        if id > 1 then formspec = formspec .. ',' end
        if not selected_name then selected_name = name end
        if name == selected_name then selected = id end
        formspec = formspec .. '##' .. minetest.formspec_escape(name)
    end

    -- Close the text list and display the selected marker position
    formspec = formspec .. ';' .. tostring(selected) .. ']'
    if selected_name then
        local pos = advmarkers.get_marker(selected_name)
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
    return minetest.show_formspec('advmarkers-sscsm', formspec)
end

-- Register chatcommands
local mrkr_cmd
function mrkr_cmd(param)
    if param == '' then return advmarkers.display_formspec() end
    if param == '--ssm' then param = '' end
    minetest.run_server_chatcommand('wp', param)
end
sscsm.register_chatcommand('mrkr', mrkr_cmd)
sscsm.register_chatcommand('wp', mrkr_cmd)
sscsm.register_chatcommand('wps', mrkr_cmd)
sscsm.register_chatcommand('waypoint', mrkr_cmd)
sscsm.register_chatcommand('waypoints', mrkr_cmd)

function mrkr_cmd(param)
    minetest.run_server_chatcommand('add_wp', param)
    run_remote_command()
end

sscsm.register_chatcommand('add_wp', mrkr_cmd)
sscsm.register_chatcommand('add_waypoint', mrkr_cmd)
sscsm.register_chatcommand('add_mrkr', mrkr_cmd)

mrkr_cmd = nil

-- Set the HUD
minetest.register_on_formspec_input(function(formname, fields)
    if formname == 'advmarkers-ignore' then
        return true
    elseif formname ~= 'advmarkers-sscsm' then
        return
    end
    local name = false
    if fields.marker then
        local event = minetest.explode_textlist_event(fields.marker)
        if event.index then
            name = formspec_list[event.index]
        end
    else
        name = selected_name
    end

    if name then
        if fields.display then
            if not advmarkers.display_waypoint(name) then
                minetest.display_chat_message('Error displaying waypoint!')
            end
        elseif fields.rename then
            minetest.show_formspec('advmarkers-sscsm', 'size[6,3]' ..
                'label[0.35,0.2;Rename waypoint]' ..
                'field[0.3,1.3;6,1;new_name;New name;' ..
                minetest.formspec_escape(name) .. ']' ..
                'button[0,2;3,1;cancel;Cancel]' ..
                'button[3,2;3,1;rename_confirm;Rename]')
        elseif fields.rename_confirm then
            if fields.new_name and #fields.new_name > 0 then
                if advmarkers.rename_waypoint(name, fields.new_name) then
                    selected_name = fields.new_name
                else
                    minetest.display_chat_message('Error renaming waypoint!')
                end
                advmarkers.display_formspec()
            else
                minetest.display_chat_message(
                    'Please enter a new name for the waypoint.'
                )
            end
        elseif fields.teleport then
            minetest.show_formspec('advmarkers-sscsm', 'size[6,2.2]' ..
                'label[0.35,0.25;' .. minetest.formspec_escape(
                    'Teleport to a waypoint\n - ' .. name
                ) .. ']' ..
                'button[0,1.25;3,1;cancel;Cancel]' ..
                'button_exit[3,1.25;3,1;teleport_confirm;Teleport]')
        elseif fields.teleport_confirm then
            -- Teleport with /teleport
            local pos = advmarkers.get_waypoint(name)
            if pos then
                minetest.run_server_chatcommand('teleport',
                    pos.x .. ', ' .. pos.y .. ', ' .. pos.z)
            else
                minetest.display_chat_message('Error teleporting to waypoint!')
            end
        elseif fields.delete then
            minetest.show_formspec('advmarkers-sscsm', 'size[6,2]' ..
                'label[0.35,0.25;Are you sure you want to delete this marker?]' ..
                'button[0,1;3,1;cancel;Cancel]' ..
                'button[3,1;3,1;delete_confirm;Delete]')
        elseif fields.delete_confirm then
            advmarkers.delete_waypoint(name)
            selected_name = false
            advmarkers.display_formspec()
        elseif fields.cancel then
            advmarkers.display_formspec()
        elseif name ~= selected_name then
            selected_name = name
            advmarkers.display_formspec()
        end
    elseif fields.display or fields.delete then
        minetest.display_chat_message('Please select a marker.')
    end
    return true
end)

-- Update the waypoint list
minetest.register_on_receiving_chat_message(function(message)
    if message:sub(1, #csm_key) == csm_key then
        advmarkers.import(message:sub(#csm_key + 1), true)
        return true
    end
end)

run_remote_command()
