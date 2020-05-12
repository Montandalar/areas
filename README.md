Areas mod for Minetest
======================

Dependencies
------------

Minetest 5.0.0+ is recommended, but 0.4.16+ should work as well.


Configuration
-------------

Open the tab `Settings -> All Settings -> Mods -> areas` to get a list of all
possible settings.

For server owners: Check `settingtypes.txt` and modify your `minetest.conf`
according to the wanted setting changes.



Tutorial
--------

1) Specify the corner positions of the area you would like to protect.
Use one of the following commands:

  * `/area_pos set` and punch the two corner nodes to set them.
  * `/area_pos set1/set2` and punch only the first or second corner node to
	set them one at a time.
  * `/area_pos1/2` to set one of the positions to your current position.
  * `/area_pos1/2 X Y Z` to set one of the positions to the specified
	coordinates.

2) Protect the selected area by running one of the following commands:

  * `/set_owner <OwnerName> <AreaName>` -- If you have the `areas` privilege.
  * `/protect <AreaName>` -- If you have the `areas` privilege or the server
	administrator has enabled area self-protection.

The area name is used only for informational purposes and has no functional
importance.

For example: `/set_owner SomePlayer Mese city`

3) You now own an area. You may now add sub-owners to it if you want to (see command `/add_owner`). Before using the `/add_owner` command you have to
select the corners of the sub-area as you did in step 1.

If you want to add access to just a sub-area of the area, you can select a smaller area inside it. If you want to add access to the whole area, no selection is necessary; `/add_owner` will grant access to the whole area if you have no selection.

The `/add_owner` command expects three arguments:
  1. The ID number of the parent area (the area that you want to add a
	sub-area to).
  2. The name of the player that will own the sub-area.
  3. The name of the sub-area (can contain spaces) - this is optional, if it is not included the existing area has its name re-used.

For example: `/add_owner 123 BobTheBuilder Diamond lighthouse`


Commands
--------
There are also aliases for most commands so that the word order is not important; `/add_owner` is the same as `/owner_add` for example.

  * `/protect <AreaName>` -- Protects an area for yourself. (if
	self-protection is enabled)

  * `/add_owner <ParentID> <OwnerName> <ChildName>` -- Grants another player
	control over part (or all) of an area.

  * `/rename_area <ID> <NewName>` -- Renames an existing area.

  * `/list_areas` -- Lists all of the areas that you own, or all areas if you
	have the `areas` privilege. Admins may also specify a specify a specific ID, range of ids or any player name.

  * `/remove_area <ID>` -- Removes an area that you own. Any sub-areas of that
	area are made sub-areas of the removed area's parent, if it exists.
	If the removed area has no parent it's sub-areas will have no parent.

  * `/recursive_remove_areas <ID>` -- Removes an area and all sub-areas of it.

  * `/change_owner <ID> <NewOwner>` -- Change the owner of an area.

  * `/area_info` -- Returns information about area configuration and usage.

  * `/select_area <ID>` -- Sets the area positions to those of an existing
	area.

  * `/area_pos {set,set1,set2,get}` -- Sets the area positions by punching
	nodes or shows the current area positions.

  * `/area_pos1 [X,Y,Z|X Y Z]` -- Sets area position one to your position or
	the one supplied.

  * `/area_pos2 [X,Y,Z|X Y Z]` -- Sets area position two to your position or
	the one supplied.

### Admin-only Commands

Apart from overriding all restrictions about ownership, admins also have some exclusive commands:

  * `/find_areas <Regex>` -- Finds areas using a Lua pattern.
	For example, to find castles:

		/find_areas [Cc]astle

  * `/list_areas_player` -- Lists the areas owned by a player. Only available to admins, otherwise for your areas use /list_areas.

  * `/move_area` -- Move (or resize) an area to the current positions.

  * `/set_owner <OwnerName> <AreaName>` -- Protects an area for a specified
	player. (requires the `areas` privilege)

License
-------

Copyright (C) 2013 ShadowNinja

Licensed under the GNU LGPL version 2.1 or later.
See LICENSE.txt and http://www.gnu.org/licenses/lgpl-2.1.txt

