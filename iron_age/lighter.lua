--[[

	TechAge
	=======

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Lighter for Coalburner and Charcoalpile
	
]]--

-- Load support for intllib.
local MP = minetest.get_modpath("techage")
local S, NS = dofile(MP.."/intllib.lua")

minetest.register_node("techage:lighter_burn", {
	tiles = {"techage_lighter_burn.png"},
	
	after_place_node = function(pos)
		techage.start_pile(pos)
	end,
	
	on_timer = function(pos, elapsed)
		return techage.keep_running_pile(pos)
	end,
	
	on_destruct = function(pos)
		techage.stop_pile(pos)
	end,
	
	drop = "",
	light_source = 10,
	is_ground_content = false,
	groups = {crumbly = 2, not_in_creative_inventory=1},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("techage:coal_lighter_burn", {
	tiles = {"techage_lighter_burn.png"},
	
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		local playername = meta:get_string("playername")
		techage.start_burner(pos, playername)
	end,
	
	on_timer = function(pos, elapsed)
		return techage.keep_running_burner(pos)
	end,
	
	on_destruct = function(pos)
		techage.stop_burner(pos)
	end,
	
	drop = "",
	light_source = 10,
	is_ground_content = false,
	groups = {not_in_creative_inventory=1},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("techage:lighter", {
	description = S("TA1 Lighter"),
	tiles = {"techage_lighter.png"},
	on_ignite = function(pos, igniter)
		if minetest.find_node_near(pos, 1, "techage:charcoal") then
			minetest.after(1, techage.ironage_swap_node, pos, "techage:coal_lighter_burn")
		else
			minetest.after(1, techage.ironage_swap_node, pos, "techage:lighter_burn")
		end
	end,
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("playername", placer:get_player_name())
	end,
	is_ground_content = false,
	groups = {crumbly = 2, flammable = 2}, 
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_craft({
	output = 'techage:lighter 2',
	recipe = {
		{'group:wood'},
		{'farming:straw'},
		{''},
	}
})

techage.register_help_page("TA1 Lighter", [[lighter to ignite the Coal Burner
and the Coal Pile.]], "techage:lighter")

