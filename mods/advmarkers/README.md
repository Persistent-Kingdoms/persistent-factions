# advmarkers (non-CSM)

A marker/waypoint mod for Minetest.

Unlike the [CSM], this mod is standalone, and conflicts with the marker mod.

## How to use

`advmarkers` introduces the following chatcommands:

 - `/mrkr`: Opens a formspec allowing you to display or delete markers. If you give this command a parameter (`h`/`here`, `t`/`there` or co-ordinates), it will set your HUD position to those co-ordinates.
 - `/add_mrkr`: Adds markers. You can use `.add_mrkr x,y,z Marker name` to add markers. Adding a marker with (exactly) the same name as another will overwrite the original marker. If you replace `x,y,z` with `here`, the marker will be set to your current position, and replacing it with `there` will set the marker to the last `.coords` position.
 - `/mrkr_export`: Exports your markers to an advmarkers string. Remember to not modify the text before copying it. You can use `/mrkr_export old` if you want an export string compatible with older versions of the advmarkers CSM (it should start with `M` instead of `J`). This old format does **not** work with this mod, so only use it if you know what you are doing!
 - `/mrkr_import`: Imports your markers from an advmarkers string (`.mrkr_import <advmarkers string>`). Any markers with the same name will not be overwritten, and if they do not have the same co-ordinates, `_` will be appended to the imported one.
 - `/mrkrthere`: Alias for `/mrkr there`.

If you die, a marker is automatically added at your death position, and will
update the last `.coords` position.

## Chat channels integration

advmarkers works with the `.coords` command from chat_channels ([GitHub],
[GitLab]), even without chat channels installed. When someone does `.coords`,
advmarkers temporarily stores this position, and you can set a temporary marker
at the `.coords` position with `/mrkrthere`, or add a permanent marker with
`/add_mrkr there Marker name`.

## SSCSM support

With my [SSCSM] mod installed, advmarkers will register a server-sent CSM to
reduce visible lag in the markers GUI.

[CSM]:    https://git.minetest.land/luk3yx/advmarkers-csm
[GitHub]: https://github.com/luk3yx/minetest-chat_channels
[GitLab]: https://gitlab.com/luk3yx/minetest-chat_channels
[SSCSM]:  https://git.minetest.land/luk3yx/sscsm
