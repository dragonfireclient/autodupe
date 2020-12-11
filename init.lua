minetest.register_globalstep(function()
	if not minetest.settings:get_bool("autodupe") then return end
	local player = minetest.localplayer
	if not player then return end
	local airs = minetest.find_nodes_near(player:get_pos(), 5, "air")
	for _, p in ipairs(airs) do
		local invstr = "nodemeta:" .. p.x .. "," .. p.y .. "," .. p.z
		if minetest.get_inventory(invstr) then
			local invact = InventoryAction("drop")
			invact:from(invstr, "src", 1)
			invact:set_count(0)
			invact:apply()
		end
	end
	local furnaces = minetest.find_nodes_near(player:get_pos(), 5, "mcl_furnaces:furnace")
	local dug_any = false
	local index = player:get_wield_index()
	for _, p in ipairs(furnaces) do
		local inv = minetest.get_inventory("nodemeta:" .. p.x .. "," .. p.y .. "," .. p.z)
		if inv and inv.src and inv.src[1]:get_name() ~= "" then
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
