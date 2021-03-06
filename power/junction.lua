--[[

	TechAge
	=======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	Junction for power distribution

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta


local function bit(p)
  return 2 ^ (p - 1)  -- 1-based indexing
end

-- Typical call:  if hasbit(x, bit(3)) then ...
local function hasbit(x, p)
  return x % (p + p) >= p       
end

local function setbit(x, p)
  return hasbit(x, p) and x or x + p
end
	
local function get_node_box(val, size, boxes)
	local fixed = {{-size, -size, -size, size, size, size}}
	for i = 1,6 do
		if hasbit(val, bit(i)) then
			for _,box in ipairs(boxes[i]) do
				table.insert(fixed, box)
			end
		end
	end
	return {
		type = "fixed",
		fixed = fixed,
	}
end

-- 'size' is the size of the junction cube without any connection, e.g. 1/8
-- 'boxes' is a table with 6 table elements for the 6 possible connection arms
-- 'tlib2' is the tubelib2 instance
-- 'node' is the node definition with tiles, callback functions, and so on
-- 'index' number for the inventory node (default 0)
function techage.register_junction(name, size, boxes, tlib2, node, index)
	local names = {}
	for idx = 0,63 do
		local ndef = table.copy(node)
		if idx == (index or 0) then
			ndef.groups.not_in_creative_inventory = 0
		else
			ndef.groups.not_in_creative_inventory = 1
		end
		ndef.groups.techage_trowel = 1
		ndef.drawtype = "nodebox"
		ndef.node_box = get_node_box(idx, size, boxes)
		ndef.paramtype2 = "facedir"
		ndef.on_rotate = screwdriver.disallow
		ndef.paramtype = "light" 
		ndef.use_texture_alpha = techage.CLIP
		ndef.sunlight_propagates = true 
		ndef.is_ground_content = false 
		ndef.drop = name..(index or "0")
		minetest.register_node(name..idx, ndef)
		tlib2:add_secondary_node_names({name..idx})
		-- for the case that 'tlib2.force_to_use_tubes' is set
		tlib2:add_special_node_names({name..idx}) 
		names[#names + 1] = name..idx
	end
	return names
end

local SideToDir = {B=1, R=2, F=3, L=4}
local function dir_to_dir2(dir, param2)
	if param2 == 0 then
		return dir
	elseif param2 == 1 then
		return ({4,1,2,3,5,6})[dir]
	elseif param2 == 2 then
		return ({3,4,1,2,5,6})[dir]
	elseif param2 == 3 then
		return ({2,3,4,1,5,6})[dir]
	end
	return dir
end

function techage.junction_type(pos, network, default_side, param2)
	local connected = function(self, pos, dir)
		if network:is_primary_node(pos, dir) then
			local param2, npos = self:get_primary_node_param2(pos, dir)
			if param2 then
				local d1, d2, num = self:decode_param2(npos, param2)
				dir = tubelib2.Turn180Deg[dir]
				return d1 == dir or dir == d2
		    end
		end
	end

	local val = 0
	if default_side then
		val = setbit(val, bit(SideToDir[default_side]))
	end
	for dir = 1,6 do
		local dir2 = dir_to_dir2(dir, param2)
		if network.force_to_use_tubes then
			if connected(network, pos, dir) then
				val = setbit(val, bit(dir2))
			elseif network:is_special_node(pos, dir) then
				val = setbit(val, bit(dir2))
			end
		else
			if connected(network, pos, dir) then
				val = setbit(val, bit(dir2))
			elseif network:is_secondary_node(pos, dir) then
				val = setbit(val, bit(dir2))
			end
		end
	end
	return val
end	

