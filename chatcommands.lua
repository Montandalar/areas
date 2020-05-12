local S = minetest.get_translator("areas")

minetest.register_chatcommand("protect", {
	params = S("<AreaName>"),
	description = S("Protect your own area"),
	privs = {[areas.config.self_protection_privilege]=true},
	func = function(name, param)
		if param == "" then
			return false, S("Invalid usage, see /help @1.", "protect")
		end
		local pos1, pos2 = areas:getPos(name)
		if not (pos1 and pos2) then
			return false, S("You need to select an area first.")
		end

		minetest.log("action", "/protect invoked, owner="..name..
				" AreaName="..param..
				" StartPos="..minetest.pos_to_string(pos1)..
				" EndPos="  ..minetest.pos_to_string(pos2))

		local canAdd, errMsg = areas:canPlayerAddArea(pos1, pos2, name)
		if not canAdd then
			return false, S("You can't protect that area: @1", errMsg)
		end

		local id = areas:add(name, param, pos1, pos2, nil)
		areas:save()

		return true, S("Area protected. ID: @1", id)
	end
})

local function setOwner(name, param)
	local ownerName, areaName = param:match('^(%S+)%s(.+)$')

	if not ownerName then
		return false, S("Invalid usage, see /help @1.", "set_owner")
	end

	local pos1, pos2 = areas:getPos(name)
	if not (pos1 and pos2) then
		return false, S("You need to select an area first.")
	end

	if not areas:player_exists(ownerName) then
		return false, S("The player \"@1\" does not exist.", ownerName)
	end

	minetest.log("action", name.." runs /set_owner. Owner = "..ownerName..
			" AreaName = "..areaName..
			" StartPos = "..minetest.pos_to_string(pos1)..
			" EndPos = "  ..minetest.pos_to_string(pos2))

	local id = areas:add(ownerName, areaName, pos1, pos2, nil)
	areas:save()

	minetest.chat_send_player(ownerName,
			S("You have been granted control over area #@1. "..
			"Type /list_areas to show your areas.", id))
	return true, S("Area protected. ID: @1", id)
end

local chatCommandParams = {
	params = S("<PlayerName>").." "..S("<AreaName>"),
	description = S("Protect an area between two positions and give"
		.." a player access to it without setting the parent of the"
		.." area to any existing area"),
	privs = areas.adminPrivs,
	func = setOwner
}

minetest.register_chatcommand("set_owner", chatCommandParams)
minetest.register_chatcommand("owner_set", chatCommandParams)

local function addOwner(name, param)
	local pid, ownerName, areaName
			= param:match('^(%d+) ([^ ]+) (.+)$')

	if not areaName then
		pid, ownerName = param:match('^(%d+) ([^ ]+)')
		pid = tonumber(pid)
		local parentArea = areas.areas[pid]
		if not parentArea then
			return false, S("Invalid usage, see /help @1.", "add_owner")
		end
		areaName = parentArea.name
		minetest.chat_send_player(name, string.format("Area name not given, defaulting to: %s", areaName))
	else
		pid = tonumber(pid)
		if not areas.areas[pid] then
			return false, S("The area @1 does not exist (b).", pid)
		end
	end

	local pos1, pos2 = areas:getPos(name)
	if not (pos1 and pos2) then
		local parentArea = areas.areas[pid]
		pos1 = parentArea.pos1
		pos2 = parentArea.pos2
	end

	if not areas:player_exists(ownerName) then
		return false, S("The player \"@1\" does not exist.", ownerName)
	end

	minetest.log("action", name.." runs /add_owner. Owner = "..ownerName..
			" AreaName = "..areaName.." ParentID = "..pid..
			" StartPos = "..pos1.x..","..pos1.y..","..pos1.z..
			" EndPos = "  ..pos2.x..","..pos2.y..","..pos2.z)

	-- Check if this new area is inside an area owned by the player
	if (not areas:isAreaOwner(pid, name)) or
	   (not areas:isSubarea(pos1, pos2, pid)) then
		return false, S("You can't protect that area.")
	end

	local id = areas:add(ownerName, areaName, pos1, pos2, pid)
	areas:save()

	minetest.chat_send_player(ownerName,
			S("You have been granted control over area #@1. "..
			"Type /list_areas to show your areas.", id))
	return true, S("Area protected. ID: @1", id)
end

chatCommandParams = {
	params = S("<ParentID>").." "..S("<PlayerName>").." "..S("[AreaName]"),
	description = S("Give a player access to a sub-area between two"
		.." positions that have already been protected,"
		.." or the whole area if you have no selection."
		.." Use set_owner if you don't want the parent to be set."),
	func = addOwner
}

minetest.register_chatcommand("add_owner", chatCommandParams)
minetest.register_chatcommand("owner_add", chatCommandParams)


local function renameArea(name, param)
	local id, newName = param:match("^(%d+)%s(.+)$")
	if not id then
		return false, S("Invalid usage, see /help @1.", "rename_area")
	end

	id = tonumber(id)
	if not id then
		return false, S("That area doesn't exist.")
	end

	if not areas:isAreaOwner(id, name) then
		return true, S("You don't own that area.")
	end

	areas.areas[id].name = newName
	areas:save()
	return true, S("Area renamed.")
end

chatCommandParams = {
	params = S("<ID>").." "..S("<newName>"),
	description = S("Rename an area that you own"),
	func = renameArea
}

minetest.register_chatcommand("rename_area", chatCommandParams)
minetest.register_chatcommand("area_rename", chatCommandParams)

local function findAreas(name, param)
	if param == "" then
		return false, S("A pattern is required.")
	end

	-- Check expression for validity
	local function testRegExp()
		("Test [1]: Player (0,0,0) (0,0,0)"):find(param)
	end
	if not pcall(testRegExp) then
		return false, S("Invalid Lua pattern.")
	end

	local matches = {}
	for id, area in pairs(areas.areas) do
		local str = areas:toString(id)
		if str:find(param) then
			table.insert(matches, str)
		end
	end
	if #matches > 0 then
		return true, table.concat(matches, "\n")
	else
		return true, S("No matches found.")
	end
end

chatCommandParams = {
	params = "<pattern>",
	description = S("Find areas using a Lua pattern match"),
	privs = areas.adminPrivs,
	func = findAreas
}

minetest.register_chatcommand("find_areas", chatCommandParams)
minetest.register_chatcommand("find_area", chatCommandParams)
minetest.register_chatcommand("areas_find", chatCommandParams)
minetest.register_chatcommand("area_find", chatCommandParams)

local function listAreasOfPlayer(name, param)
	if areas:player_exists(param) then
		local areaStrings = {}
		for id, area in pairs(areas.areas) do
			if area.owner == param then
				table.insert(areaStrings, areas:toString(id))
			end
		end
		return true, table.concat(areaStrings, "\n")
	else
		return false, S("No such player.")
	end
end

local function listAreas(name, param)
	local admin = minetest.check_player_privs(name, areas.adminPrivs)
	local areaStrings = {}
	if param ~= "" and admin then
		local intParam = tonumber(param)
		if intParam then
			if not areas.areas[intParam] then
				return false, S("Area does not exist.")
			end
			return true, areas:toString(intParam)
		end
		local start, fin = param:match("(%d+)-(%d+)")
		if not (start and fin) then
			if areas:player_exists(param) then
				return listAreasOfPlayer(name, param)
			else 
				return false, S("Invalid argument. See /help @1 (args: @2, @3 \"@4\")",
					"list_areas", tostring(start), tostring(fin), param)
			end
		else
			for i=start,fin do
				if (areas.areas[i]) then
					table.insert(areaStrings, areas:toString(i))
				end
			end
		end
	end
	if next(areaStrings) == nil then -- empty table
		for id, area in pairs(areas.areas) do
			if admin or areas:isAreaOwner(id, name) then
				table.insert(areaStrings, areas:toString(id))
			end
		end
	end
	if #areaStrings == 0 then
		return true, S("No visible areas.")
	end
	return true, table.concat(areaStrings, "\n")
end

chatCommandParams = {
	params = '[ "" | id | range | player_name ]',
	description = S("List your areas, or all areas if you are an admin."
		.." Admins may also specify a specify a specific ID, range of ids or player name."),
	func = listAreas
}

minetest.register_chatcommand("list_areas", chatCommandParams)
minetest.register_chatcommand("areas_list", chatCommandParams)

chatCommandParams = {
	privs = areas.adminPrivs,
	params = "<player>",
	description = S("List the areas owned by a player. Only available to admins, otherwise for your areas use /list_areas."),
	func = listAreasOfPlayer
}

minetest.register_chatcommand("list_areas_player", chatCommandParams)

local function recursiveRemoveAreas (name, param)
	local id = tonumber(param)
	if not id then
		return false, S("Invalid usage, see"
				.." /help @1.", "recursive_remove_areas")
	end

	if not areas:isAreaOwner(id, name) then
		return false, S("Area @1 does not exist or is"
				.." not owned by you.", id)
	end

	areas:remove(id, true)
	areas:save()
	return true, S("Removed area @1 and its sub areas.", id)
end

chatCommandParams = {
	params = S("<ID>"),
	description = S("Recursively remove areas using an ID"),
	func = recursiveRemoveAreas
}

minetest.register_chatcommand("recursive_remove_areas", chatCommandParams)
minetest.register_chatcommand("remove_areas_recursive", chatCommandParams)
minetest.register_chatcommand("areas_remove_recursive", chatCommandParams)

local function removeArea(name, param)
	local id = tonumber(param)
	if not id then
		return false, S("Invalid usage, see /help @1.", "remove_area")
	end

	if not areas:isAreaOwner(id, name) then
		return false, S("Area @1 does not exist or"
				.." is not owned by you.", id)
	end

	areas:remove(id)
	areas:save()
	return true, S("Removed area @1", id)
end

chatCommandParams = {
	params = S("<ID>"),
	description = S("Remove an area using an ID"),
	func = removeArea
}

minetest.register_chatcommand("remove_area", chatCommandParams)
minetest.register_chatcommand("area_remove", chatCommandParams)


minetest.register_chatcommand("change_owner", {
	params = S("<ID>").." "..S("<NewOwner>"),
	description = S("Change the owner of an area using its ID"),
	func = function(name, param)
		local id, newOwner = param:match("^(%d+)%s(%S+)$")
		if not id then
			return false, S("Invalid usage, see"
					.." /help @1.", "change_owner")
		end

		if not areas:player_exists(newOwner) then
			return false, S("The player \"@1\" does not exist.", newOwner)
		end

		id = tonumber(id)
		if not areas:isAreaOwner(id, name) then
			return false, S("Area @1 does not exist"
					.." or is not owned by you.", id)
		end
		areas.areas[id].owner = newOwner
		areas:save()
		minetest.chat_send_player(newOwner,
			S("@1 has given you control over the area \"@2\" (ID @3).",
				name, areas.areas[id].name, id))
		return true, S("Owner changed.")
	end
})

local function areaOpen(name, param)
	local id = tonumber(param)
	if not id then
		return false, S("Invalid usage, see /help @1.", "area_open")
	end

	if not areas:isAreaOwner(id, name) then
		return false, S("Area @1 does not exist"
				.." or is not owned by you.", id)
	end
	local open = not areas.areas[id].open
	-- Save false as nil to avoid inflating the DB.
	areas.areas[id].open = open or nil
	areas:save()
	return true, open and S("Area opened.") or S("Area closed.")
end

chatCommandParams = {
	params = S("<ID>"),
	description = S("Toggle an area open (anyone can interact) or closed"),
	func = areaOpen
}

minetest.register_chatcommand("area_open", chatCommandParams)
minetest.register_chatcommand("open_area", chatCommandParams)

local function areaClose(name, param)
	local id = tonumber(param)
	if not id then
		return false, S("Invalid usage, see /help @1.", "area_open")
	end

	if not areas:isAreaOwner(id, name) then
		return false, S("Area @1 does not exist"
				.." or is not owned by you.", id)
	end
	local open = not areas.areas[id].open
	-- Save false as nil to avoid inflating the DB.
	areas.areas[id].open = false
	areas:save()
	return ("Area closed.")
end

chatCommandParams = {
	description = S("Make an area closed (not open)."),
	func = areaClose
}

minetest.register_chatcommand("area_close", chatCommandParams)
minetest.register_chatcommand("close_area", chatCommandParams)


if areas.factions_available then
	minetest.register_chatcommand("area_faction_open", {
		params = S("<ID>"),
		description = S("Toggle an area open/closed for members in your faction."),
		func = function(name, param)
			local id = tonumber(param)
			if not id then
				return false, S("Invalid usage, see /help @1.", "area_faction_open")
			end
			
			if not areas:isAreaOwner(id, name) then
				return false, S("Area @1 does not exist"
						.." or is not owned by you.", id)
			end
			local open = not areas.areas[id].faction_open
			-- Save false as nil to avoid inflating the DB.
			areas.areas[id].faction_open = open or nil
			areas:save()
			return true, open and S("Area opened for faction members.")
				or S("Area closed for faction members.")
		end
	})
end

local function moveArea(name, param)
	local id = tonumber(param)
	if not id then
		return false, S("Invalid usage, see /help @1.", "move_area")
	end

	local area = areas.areas[id]
	if not area then
		return false, S("Area does not exist.")
	end

	local pos1, pos2 = areas:getPos(name)
	if not pos1 then
		return false, S("You need to select an area first.")
	end

	areas:move(id, area, pos1, pos2)
	areas:save()

	return true, S("Area successfully moved.")
end

chatCommandParams = {
	params = S("<ID>"),
	description = S("Move (or resize) an area to the current positions."),
	privs = areas.adminPrivs,
	func = moveArea,
}

minetest.register_chatcommand("move_area", chatCommandParams)
minetest.register_chatcommand("area_move", chatCommandParams)


minetest.register_chatcommand("area_info", {
	description = S("Get information about area configuration and usage."),
	func = function(name, param)
		local lines = {}
		local privs = minetest.get_player_privs(name)

		-- Short (and fast to access) names
		local cfg = areas.config
		local self_prot  = cfg.self_protection
		local prot_priv  = cfg.self_protection_privilege
		local limit      = cfg.self_protection_max_areas
		local limit_high = cfg.self_protection_max_areas_high
		local size_limit = cfg.self_protection_max_size
		local size_limit_high = cfg.self_protection_max_size_high

		local has_high_limit = privs.areas_high_limit
		local has_prot_priv = not prot_priv or privs[prot_priv]
		local can_prot = privs.areas or (self_prot and has_prot_priv)
		local max_count = can_prot and
			(has_high_limit and limit_high or limit) or 0
		local max_size = has_high_limit and
			size_limit_high or size_limit

		-- Self protection information
		local self_prot_line = self_prot and S("Self protection is enabled.") or
					S("Self protection is disabled.")
		table.insert(lines, self_prot_line)
		-- Privilege information
		local priv_line = has_prot_priv and
					S("You have the necessary privilege (\"@1\").", prot_priv) or
					S("You don't have the necessary privilege (\"@1\").", prot_priv)
		table.insert(lines, priv_line)
		if privs.areas then
			table.insert(lines, S("You are an area"..
				" administrator (\"areas\" privilege)."))
		elseif has_high_limit then
			table.insert(lines,
				S("You have extended area protection"..
				" limits (\"areas_high_limit\" privilege)."))
		end

		-- Area count
		local area_num = 0
		for id, area in pairs(areas.areas) do
			if area.owner == name then
				area_num = area_num + 1
			end
		end
		table.insert(lines, S("You have @1 areas.", area_num)) 

		-- Area limit
		local area_limit_line = privs.areas and
			S("Limit: no area count limit") or
			S("Limit: @1 areas", max_count)
		table.insert(lines, area_limit_line)

		-- Area size limits
		local function size_info(str, size)
			table.insert(lines, S("@1 spanning up to @2x@3x@4.",
				str, size.x, size.y, size.z))
		end
		local function priv_limit_info(lpriv, lmax_count, lmax_size)
			size_info(S("Players with the \"@1\" privilege"..
				" can protect up to @2 areas", lpriv, lmax_count),
				lmax_size)
		end
		if self_prot then
			if privs.areas then
				priv_limit_info(prot_priv,
					limit, size_limit)
				priv_limit_info("areas_high_limit",
					limit_high, size_limit_high)
			elseif has_prot_priv then
				size_info(S("You can protect areas"), max_size)
			end
		end

		return true, table.concat(lines, "\n")
	end,
})

