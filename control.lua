require("config")

local hide_on_platform = "more-minimap-autohide--hide-on-space-platform"
local hide_on_platform__fire_lights = "fl-disable-platform-minimap"
local hide_on_night__fire_lights = "fl-disable-night-minimap"

function warn_fl_conflict()
	local fl = settings.startup[hide_on_platform__fire_lights]
	if fl and fl.value then
		game.print("[font=heading-1]More Minimap Autohide[/font] Conflict with [color=#ff2200]Fire Lights[/color]: 'Remove Space Platform Minimap' is enabled there. Please disable it to avoid minimap conflicts.")
	end
end

function init()
	storage.mapview = storage.mapview or {}
	for i, player in pairs(game.players) do
		if storage.mapview[i] == nil then
			storage.mapview[i] = player.game_view_settings.show_minimap
		end
	end
	warn_fl_conflict()
end

function init_player(event)
	-- Default new players to true; reading show_minimap at on_player_created
	-- may return false before the player's UI is fully initialized.
	storage.mapview[event.player_index] = true
end

function toggle_view(player_index, view)
	local settings = game.players[player_index].game_view_settings
	settings[view] = not settings[view]
end

function toggle_view_map(event)
	toggle_view(event.player_index, "show_minimap")
	storage.mapview[event.player_index] = game.players[event.player_index].game_view_settings.show_minimap
end

function toggle_view_research(event)
	toggle_view(event.player_index, "show_research_info")
end

function toggle_view_toolbar(event)
	toggle_view(event.player_index, "show_controller_gui")
end

function toggle_view_alerts(event)
	toggle_view(event.player_index, "show_alert_gui")
end

if viewsettings.enable_minimap_hotkey then
	script.on_event("toggle_view_map", toggle_view_map)
end

if viewsettings.enable_research_hotkey then
	script.on_event("toggle_view_research", toggle_view_research)
end

if viewsettings.enable_toolbar_hotkey then
	script.on_event("toggle_view_toolbar", toggle_view_toolbar)
end

if viewsettings.enable_alerts_hotkey then
	script.on_event("toggle_view_alerts", toggle_view_alerts)
end

function set_map_view(player, state)
	if player.game_view_settings.show_minimap ~= state then
		toggle_view(player.index, "show_minimap")
	end
end

function updated_selected(event)
	local player = game.players[event.player_index]

	if settings.get_player_settings(player)[hide_on_platform].value and player.surface.platform ~= nil then
		return
	end

	local fl_night = settings.startup[hide_on_night__fire_lights]
	if fl_night and fl_night.value and player.surface.darkness > 0.5 then
		return
	end

	local selected = player.selected
	if storage.mapview[event.player_index] then
		if selected and viewsettings.hide_minimap_on[selected.type] then
			set_map_view(player, false)
		else
			set_map_view(player, true)
		end
	end
end

local autohide_minimap = false
for _, bool in pairs(viewsettings.hide_minimap_on) do
	autohide_minimap = autohide_minimap or bool
end
if autohide_minimap then
	script.on_event(defines.events.on_selected_entity_changed, updated_selected)
end

script.on_event(defines.events.on_player_changed_surface, function(event)
	local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
	if settings.get_player_settings(player)[hide_on_platform].value then
		player.game_view_settings.show_minimap = player.surface.platform == nil
	end
end)

script.on_init(init)
script.on_configuration_changed(init)
script.on_event(defines.events.on_player_created, init_player)