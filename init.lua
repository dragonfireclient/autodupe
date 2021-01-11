autodupe = {}

local function prepare_item_collect(pos)
	minetest.localplayer:set_pos(vector.subtract(pos, vector.new(0, 1, 0)))
end

local function node_inv_str(pos)
	return "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
end

local function inv_empty(pos)
	local inv = minetest.get_inventory(node_inv_str(pos))
	return not inv or not inv.src or inv.src[1]:get_name() == ""
end

local function get_free_inv_slot()
	for index, stack in ipairs(minetest.get_inventory("current_player").main) do
		if stack:get_name() == "" then
			return index
		end
	end
	return 1
end

function autodupe.needed(index)
	local player = minetest.localplayer
	local ppos = player:get_pos()
	local furnaces = minetest.find_nodes_near(ppos, 5, "mcl_furnaces:furnace", true)
	local found_furnace = false
	for _, fpos in ipairs(furnaces) do
		if inv_empty(fpos) then
			found_furnace = true
			local invstr = node_inv_str(fpos)
			local invact = InventoryAction("move")
			invact:from("current_player", "main", index)
			invact:to(invstr, "src", 1)
			invact:apply()
			minetest.interact("activate", {type = "nothing"})
			break
		end
	end

	if not found_furnace then
		local airs = minetest.find_nodes_near(ppos, 5, "air", false)
		for _, apos in ipairs(airs) do
			if inv_empty(apos) then
				if minetest.switch_to_item("mcl_furnaces:furnace") then
					minetest.place_node(apos)
					prepare_item_collect(apos)
				end
				return
			end
		end
	end
end

local function dupe_furnaces()
	local furnace_index
	for index, stack in ipairs(minetest.get_inventory("current_player").main) do
		if stack:get_name() == "mcl_furnaces:furnace" then
			if furnace_index then
				return true
			end
			furnace_index = index
		end
	end
	if furnace_index then
		autodupe.needed(furnace_index)
	end
end

function autodupe.cleanup()
	if not dupe_furnaces() then
		return false
	end
	local player = minetest.localplayer
	local ppos = player:get_pos()
	local furnaces = minetest.find_nodes_near(ppos, 5, "mcl_furnaces:furnace", true)
	for _, fpos in ipairs(furnaces) do
		prepare_item_collect(fpos)
		autotool.select_best_tool("mcl_furnaces:furnace")
		minetest.dig_node(fpos)
		return false
	end
	return true
end

minetest.register_globalstep(function(dtime)
	if not minetest.settings:get_bool("autodupe") then return end
	local player = minetest.localplayer
	if not player then return end
	local airs = minetest.find_nodes_near(player:get_pos(), 5, "air", true)
	for _, p in ipairs(airs) do
		if not inv_empty(p) then
			local invstr = node_inv_str(p)
			local invact = InventoryAction("move")
			invact:from(invstr, "src", 1)
			invact:to("current_player", "main", get_free_inv_slot())
			invact:apply()
		end
	end
	local furnaces = minetest.find_nodes_near(player:get_pos(), 5, "mcl_furnaces:furnace", true)
	local dug_any = false
	local index = player:get_wield_index()
	for _, p in ipairs(furnaces) do
		local inv = minetest.get_inventory(node_inv_str(p))
		if not inv_empty(p) then
			if not dug_any then
				autotool.select_best_tool("mcl_furnaces:furnace")
				dug_any = true
			end
			minetest.dig_node(p)
		end
	end
	if dug_any then
		player:set_wield_index(index)
		minetest.close_formspec("")
	end
end)

minetest.register_cheat("AutoDupe", "World", "autodupe")
