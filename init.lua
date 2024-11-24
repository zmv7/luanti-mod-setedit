local F = core.formspec_escape

local settings = {}
local selected = {}

local function setedit(name, prompt)
	if not selected[name] then
		selected[name] = 1
	end
	settings[name] = {}
	local lset = settings[name]
	local lsel = selected[name]

	local st = core.settings:to_table()
	for k in pairs(st) do
		if not prompt or prompt == "" or k:match(prompt:gsub('([^%w])','%%%1')) then
			table.insert(lset, k)
		end
	end
	table.sort(lset)
	local out = {}
	for i, setting in ipairs(lset) do
		local val = st[setting]
		table.insert(out,setting..","..val)
	end
	local fs = "size[9,11]" ..
	"field[0.3,0.5;7.6,1;search;Search;"..F(prompt or "").."]" ..
	"field_close_on_enter[search;false]" ..
	"button[7.5,0.2;1.5,1;search_btn;Search]" ..
	"tablecolumns[text;text]" ..
	"table[0,1;8.8,9;settings;"..table.concat(out,",")..";"..lsel.."]" ..
	"field[0.3,10.6;7.6,1;value;"..F(lset[lsel] or "")..";"..
		F(core.settings:get(lset[lsel] or "") or "").."]" ..
	"field_close_on_enter[value;false]" ..
	"button[7.5,10.3;1.5,1;apply_btn;Apply]"

	if INIT == "client" then
		core.show_formspec("setedit",fs)
	else
		core.show_formspec(name, "setedit",fs)
	end
end

local function setedit_fshandler(player, formname, fields)
	if formname ~= "setedit" then return end
	local name = INIT == "client" and player:get_name() or player:get_player_name()
	if fields.settings then
		local evnt = core.explode_table_event(fields.settings)
		if evnt.type ~= "INV" then
			selected[name] = evnt.row
			if evnt.type == "DCL" then
				local setting = settings[name][selected[name]]
				local val = core.settings:get(setting or "")
				if val == "true" or val == "false" then
					core.settings:set(setting, val == "true" and "false" or "true")
				end
			end
		end
	end
	if fields.apply_btn or fields.key_enter_field == "value" then
		core.settings:set(settings[name][selected[name]], fields.value)
	end
	if fields.quit then
		settings[name] = nil
		selected[name] = nil
		return
	end
	setedit(name, fields.search)
end

if INIT == "client" then
	core.register_on_formspec_input(function(formname, fields)
		return setedit_fshandler(core.localplayer, formname, fields)
	end)
else
	core.register_on_player_receive_fields(setedit_fshandler)
end

core.register_chatcommand("setedit",{
	desciption = "Open setedit",
	params = "[search pattern]",
	func = function(name, param)
		if INIT == "client" then
			param = name
			name = core.localplayer:get_name()
		end
		setedit(name, param)
end})

if INIT == "client" then
	core.register_chatcommand("set",{
		desciption = "Manage settings",
		params = "<setting> [value]",
		func = function(param)
			if not param or param == "" then
				return false, "Missing parameters"
			end
			local setting, val = param:match("^(%S+) (.+)$")
			if not (setting and val) then
				setting = param
				return true, setting .. " = " ..
					(core.settings:get(setting) or "<undefined>")
			end
			core.settings:set(setting, val)
			return true, setting .. " = " .. val
	end})
end
