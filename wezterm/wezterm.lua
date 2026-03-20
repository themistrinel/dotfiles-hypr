local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.55
config.macos_window_background_blur = 25
config.initial_cols = 150
config.initial_rows = 40
config.adjust_window_size_when_changing_font_size = false

config.font = wezterm.font("JetBrainsMono Nerd Font", {
	weight = "Bold",
})
config.font_size = 17
config.enable_scroll_bar = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false -- Move para o topo (padrão)
config.window_padding = {
	left = 24,
	right = 24,
	top = 24,
	bottom = 0, -- Fix gap at the bottom
}

-- Função para detectar se o Neovim está rodando no painel atual
local function is_vim(pane)
	local process_info = pane:get_foreground_process_info()
	if not process_info then
		return false
	end

	local name = process_info.name:lower()
	return name:find("n?vim") ~= nil
end

-- Listener para atualizar o padding dinamicamente
wezterm.on("update-status", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if is_vim(pane) then
		if not overrides.window_padding or overrides.window_padding.left ~= 0 then
			overrides.window_padding = {
				left = 0,
				right = 0,
				top = 0,
				bottom = 0,
			}
			window:set_config_overrides(overrides)
		end
	else
		if overrides.window_padding and overrides.window_padding.left == 0 then
			overrides.window_padding = nil
			window:set_config_overrides(overrides)
		end
	end
end)
config.window_decorations = "NONE"
local schemes = wezterm.color.get_builtin_schemes()
config.color_scheme = "TokyoNight"
config.default_cursor_style = "BlinkingBar"
local act = wezterm.action

local mod = {
	SUPER = "SUPER",
	SUPER_REV = "SUPER|SHIFT",
	OPT = "OPT",
}

config.leader = {
	key = "a",
	mods = "CTRL",
}
config.mouse_bindings = {
	{
		event = {
			Up = {
				streak = 1,
				button = "Left",
			},
		},
		mods = mod.SUPER,
		action = act.OpenLinkAtMouseCursor,
	},
}

config.colors = {
	tab_bar = {
		background = "rgba(20, 20, 20, 0.6)",

		active_tab = {
			bg_color = "#1f2937", -- azul acinzentado escuro
			fg_color = "#e5e7eb", -- quase branco
			intensity = "Bold",
			underline = "None",
			italic = false,
			strikethrough = false,
		},

		inactive_tab = {
			bg_color = "rgba(30, 30, 30, 0.4)",
			fg_color = "#9ca3af",
		},

		inactive_tab_hover = {
			bg_color = "#374151",
			fg_color = "#e5e7eb",
			italic = true,
		},

		new_tab = {
			bg_color = "rgba(20, 20, 20, 0.4)",
			fg_color = "#6b7280",
		},

		new_tab_hover = {
			bg_color = "#4b5563",
			fg_color = "#f9fafb",
			intensity = "Bold",
		},
	},
}

-- config.colors = {
--   tab_bar = {
--     background = scheme.background,

--     active_tab = {
--       bg_color = scheme.selection_bg or scheme.brights[1],
--       fg_color = scheme.selection_fg or scheme.foreground,
--       intensity = "Bold",
--     },

--     inactive_tab = {
--       bg_color = scheme.background,
--       fg_color = scheme.ansi[8], -- cinza do theme
--     },

--     inactive_tab_hover = {
--       bg_color = scheme.brights[1],
--       fg_color = scheme.foreground,
--       italic = true,
--     },

--     new_tab = {
--       bg_color = scheme.background,
--       fg_color = scheme.ansi[7],
--     },

--     new_tab_hover = {
--       bg_color = scheme.brights[2],
--       fg_color = scheme.background,
--       intensity = "Bold",
--     },
--   },
-- }

config.keys = { -- panes: split panes
	{
		key = [[\]],
		mods = mod.SUPER,
		action = wezterm.action.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},
	{
		key = [[\]],
		mods = mod.SUPER_REV,
		action = wezterm.action.SplitVertical({
			domain = "CurrentPaneDomain",
		}),
	}, -- panes: zoom+close pane
	{
		key = "Enter",
		mods = mod.SUPER,
		action = act.TogglePaneZoomState,
	},
	{
		key = "w",
		mods = mod.SUPER,
		action = act.CloseCurrentPane({
			confirm = false,
		}),
	}, -- panes: navigation
	{
		key = "k",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "h",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Right"),
	}, -- panes: resize_pane
	{
		key = "p",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "resize_pane",
			one_shot = false,
			timemout_miliseconds = 1000,
		}),
	},
	{
		key = "p",
		mods = mod.SUPER,
		action = act.ActivateCommandPalette,
	},
	{
		key = "u",
		mods = mod.SUPER,
		action = wezterm.action.QuickSelectArgs({
			label = "open url",
			patterns = {
				"\\((https?://\\S+)\\)",
				"\\[(https?://\\S+)\\]",
				"\\{(https?://\\S+)\\}",
				"<(https?://\\S+)>",
				"\\bhttps?://\\S+[)/a-zA-Z0-9-]+",
			},
			action = wezterm.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				wezterm.log_info("opening: " .. url)
				wezterm.open_with(url)
			end),
		}),
	}, -- tabs: navigation
	{
		key = "[",
		mods = mod.SUPER,
		action = act.ActivateTabRelative(-1),
	},
	{
		key = "]",
		mods = mod.SUPER,
		action = act.ActivateTabRelative(1),
	},
	{
		key = "[",
		mods = mod.SUPER_REV,
		action = act.MoveTabRelative(-1),
	},
	{
		key = "]",
		mods = mod.SUPER_REV,
		action = act.MoveTabRelative(1),
	},
	{
		key = ",",
		mods = mod.OPT,
		action = wezterm.action_callback(function(window, pane)
			local wez_config_path = os.getenv("HOME") .. "/.config/wezterm/wezterm.lua"
			wezterm.log_info("wez config" .. wez_config_path)
			window:perform_action(
				wezterm.action.SpawnCommandInNewTab({
					args = { "nvim", wez_config_path },
					set_environment_variables = {
						PATH = "/opt/homebrew/bin:" .. os.getenv("PATH"),
					},
				}),
				pane
			)
		end),
	}, -- copy mode
	{
		key = "f",
		mods = mod.SUPER,
		action = act.ToggleFullScreen,
	},
}

wezterm.on("gui-startup", function(cmd)
	local screen = wezterm.gui.screens().active
	local ratio = 0.8 -- 90% da tela
	local width = math.floor(screen.width * ratio)
	local height = math.floor(screen.height * ratio)
	local x = math.floor((screen.width - width) / 2)
	local y = math.floor((screen.height - height) / 2)

	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():set_inner_size(width, height)
	window:gui_window():set_position(x, y)
end)

return config
