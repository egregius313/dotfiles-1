-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({ preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function (err)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true

		naughty.notify({ preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err) })
		in_error = false
	end)
end

-- Notify system startup errors.
do
	local home = os.getenv("HOME")
	for _, file in pairs({home .. "/errors-dmesg.log", home .. "/errors-systemd.log"}) do
		local f = io.open (file,'r')
		if f ~= nil then
			f:close ()
			naughty.notify({ preset = naughty.config.presets.critical,
					title = "System startup error!",
					text = "See " .. file })
		end
	end
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(awful.util.get_themes_dir() .. "default/theme.lua")
beautiful.init(awful.util.getdir("config") .. "/themes/occam/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = os.getenv("TERMCMD") or "xterm"

-- Get OS. Make sure to read one line only, skipping end of line.
local f = io.popen("uname")
local ostype = f:read("*l")
f:close()

-- Audio commands
-- Linux
local audio_increase = "amixer set Master 5%+"
local audio_decrease = "amixer set Master 5%-"
local audio_toggle = "amixer set Master toggle"
if ostype == "FreeBSD" then
	audio_increase = "mixer vol +5"
	audio_decrease = "mixer vol -5"
	audio_toggle = "mixer vol ^"
end


if ostype == "Linux" then
	vicious = require("vicious")
end

-- Default modkey.
modkey = "Mod4"

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

separator = " | "

cpuwidget = wibox.widget.textbox()
netwidget = wibox.widget.textbox()
audiowidget = wibox.widget.textbox()
batwidget = wibox.widget.textbox()

if ostype == "Linux" then
	-- CPU
	vicious.register(cpuwidget, vicious.widgets.cpu, separator .. '<span color="#CC8F52">CPU $1%</span>')

	-- Net
	-- CHECK: not sure if args["{".. device .." carrier}"] may have values below 0. What do values of the args table mean?
	-- Note: we must make sure not to take the loopback interface into account.
	local proc = io.popen("ls -1 /sys/class/net | grep -v '^lo$'")
	local ifarray = {}
	for line in proc:lines() do
		table.insert (ifarray, line);
	end
	proc:close()
	vicious.register(netwidget, vicious.widgets.net, function (widget, args)
			for _,device in pairs(ifarray) do
				value = tonumber(args["{".. device .." carrier}"])
				if value ~= nil and value ~= 0 then
					return separator .. '<span color="#CC9393">↓' .. args["{" .. device .. " down_kb}"] .. '</span> <span color="#7F9F7F">↑' .. args["{" .. device .. " up_kb}"] .. '</span>'
				end
			end
			return ""
	end, 3)

	-- Audio
	vicious.register(audiowidget, vicious.widgets.volume, separator .. "$2 $1%", 1, "Master")

	-- Battery
	local batf = io.popen("ls '/sys/class/power_supply' 2>/dev/null")
	local batl = batf:read("*a")
	local batlimit = 10
	if batl ~= "" then
		-- This functions changes the status color when batlimit is reached.
		vicious.register(batwidget, vicious.widgets.bat,
			function (widget, args)
				-- We check if time is displayed (otherwise it's 'N/A'), and if minutes are less than limit.
				if args[1] == "−"
					and string.len(args[3]) == 5
					and tonumber(string.sub(args[3],1,2)) == 0
					and tonumber(string.sub(args[3],4,5)) <= batlimit
				then
					return separator .. '<span color="#FF0000">' .. args[2] .. '%' .. args[1] .. args[3] .. '</span>'
				else
					return separator .. '<span color="#73A9CD">' .. args[2] .. '%' .. args[1] .. args[3] .. '</span>'
				end
			end,
			60, "BAT0")
	end
	batf:close()
end

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
	awful.button({ }, 1, function(t) t:view_only() end),
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({ }, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
	awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local function set_wallpaper(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.fit(wallpaper, s)
	end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
	-- Wallpaper
	set_wallpaper(s)

	-- Each screen has its own tag table.
	awful.tag({1}, s, awful.layout.suit.tile)

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(awful.util.table.join(
		awful.button({ }, 1, function () awful.layout.inc( 1) end),
		awful.button({ }, 3, function () awful.layout.inc(-1) end),
		awful.button({ }, 4, function () awful.layout.inc( 1) end),
		awful.button({ }, 5, function () awful.layout.inc(-1) end)))

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

	-- Create the wibox
	s.mywibox = awful.wibar({ position = "top", screen = s })

	-- Add widgets to the wibox
	s.mywibox:setup {
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			mylauncher,
			s.mytaglist,
			s.mypromptbox,
		},
		s.mytasklist, -- Middle widget
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			batwidget,
			audiowidget,
			netwidget,
			cpuwidget,
			wibox.widget.textbox(" |"),
			mytextclock,
			wibox.widget.systray(),
			s.mylayoutbox,
		},
	}
end)
-- }}}

-- {{{ Mouse bindings
-- Simple function to move the mouse to the bottom right corner of the screen.
local function move_mouse_away()
	mouse.coords({ x=mouse.screen.geometry.width, y=mouse.screen.geometry.height })
end

-- Move the mouse when rc.lua is read (startup)
move_mouse_away()

-- Fallback when no mouse is at hand.
-- local function move_mouse(x, y)
-- 	pos = mouse.coords()
-- 	local fact = 10
-- 	mouse.coords({ x=pos.x + fact*x, y=pos.y + fact*y })
-- end
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
	awful.key({ modkey, }, "s", hotkeys_popup.show_help,
		{description="show help", group="awesome"}),

	awful.key({ modkey, }, "Tab",
		function ()
			awful.client.focus.byidx( 1)
		end,
		{description = "focus next by index", group = "client"}
	),
	awful.key({ modkey, }, "Escape",
		function ()
			awful.client.focus.byidx(-1)
		end,
		{description = "focus previous by index", group = "client"}
	),

	-- Layout manipulation
	awful.key({ modkey, "Shift" }, "j", function () awful.client.swap.byidx(	1)		end,
		{description = "swap with next client by index", group = "client"}),
	awful.key({ modkey, "Shift" }, "k", function () awful.client.swap.byidx( -1)		end,
		{description = "swap with previous client by index", group = "client"}),

	-- Standard program
	awful.key({ modkey, }, "Return", function () awful.spawn("emacsclient -a '' -n -c -e '(eshell t)'") end,
		{description = "open a terminal", group = "launcher"}),
	awful.key({ modkey, "Control" }, "r", awesome.restart,
		{description = "reload awesome", group = "awesome"}),
	awful.key({ modkey, }, "w",  function () awful.spawn("qutebrowser") end,
		{description="web browser", group="launcher"}),
	awful.key({ modkey, }, "e",  function () awful.spawn(os.getenv("EDITOR")) end,
		{description="editor", group="launcher"}),
	-- Mutt needs to be started in the folder where you want to save attachments.
	awful.key({ modkey, }, "m",  function () awful.spawn(terminal .. " -e sh -c 'cd ~/temp && mutt'") end,
		{description="mail user agent", group="launcher"}),
	awful.key({ }, "Print",  function () awful.spawn("scrot '" .. os.getenv("HOME") .. "/temp/screen-%F-%T.png'") end,
		{description="screenshot", group="launcher"}),

	-- Screen lock. xlockmore is useful for LDAP login because slock does not work with it.
	-- Don't use 'spawn_with_shell' if you want to keep Awesome's config portable.
	awful.key({ modkey, }, "z",  function () awful.spawn("sh -c 'xlock 2>/dev/null || slock'") end,
		{description="lock screen", group="awesome"}),

	-- Touchpad control
	awful.key({ }, "XF86TouchpadToggle", function () os.execute('xinput list-props "SynPS/2 Synaptics TouchPad" | grep -q "Device Enabled [^:]*:[[:space:]]*1" && xinput disable "SynPS/2 Synaptics TouchPad" || xinput enable "SynPS/2 Synaptics TouchPad"') end,
		{description="toggle touchpad", group="mouse"}),
	awful.key({ }, "XF86Tools",          function () os.execute('xinput list-props "SynPS/2 Synaptics TouchPad" | grep -q "Device Enabled [^:]*:[[:space:]]*1" && xinput disable "SynPS/2 Synaptics TouchPad" || xinput enable "SynPS/2 Synaptics TouchPad"') end,
		{description="toggle touchpad", group="mouse"}),
	awful.key({ modkey, "Control" }, "m",  function () os.execute('xinput list-props "SynPS/2 Synaptics TouchPad" | grep -q "Device Enabled [^:]*:[[:space:]]*1" && xinput disable "SynPS/2 Synaptics TouchPad" || xinput enable "SynPS/2 Synaptics TouchPad"') end,
		{description="toggle touchpad", group="mouse"}),
	awful.key({ modkey, "Shift" }, "m", move_mouse_away,
		{description="move mouse away", group="mouse"}),

	-- Audio volume
	awful.key({ modkey }, "KP_Subtract",   function () awful.util.spawn(audio_decrease) end,
		{description = "raise volume", group = "audio"}),
	awful.key({ modkey }, "KP_Add",        function () awful.util.spawn(audio_increase) end,
		{description = "lower volume", group = "audio"}),
	awful.key({ modkey }, "KP_Enter",      function () awful.util.spawn(audio_toggle) end,
		{description = "toggle audio", group = "audio"}),

	awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn(audio_decrease) end,
		{description = "lower volume", group = "audio"}),
	awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn(audio_increase) end,
		{description = "raise volume", group = "audio"}),
	awful.key({ }, "XF86AudioMute",        function () awful.util.spawn(audio_toggle) end,
		{description = "toggle audio", group = "audio"}),

	awful.key({ modkey }, "n",
		function ()
			local c = awful.client.restore()
			-- Focus restored client
			if c then
				client.focus = c
				c:raise()
			end
		end,
		{description = "restore minimized", group = "client"}),

	awful.key({ modkey }, "x",
		function ()
			awful.prompt.run {
				prompt       = "Run Lua code: ",
				textbox      = awful.screen.focused().mypromptbox.widget,
				exe_callback = awful.util.eval,
				history_path = awful.util.get_cache_dir() .. "/history_eval"
			}
		end,
		{description = "lua execute prompt", group = "awesome"}),
	-- Prompt
	awful.key({ modkey }, "r", function () awful.screen.focused().mypromptbox:run() end,
		{description = "run prompt", group = "launcher"})
)

clientkeys = awful.util.table.join(
	awful.key({ modkey,  }, "f", function (c) c.maximized = not c.maximized  end,
		{description = "(un)maximize", group = "client"}),
	awful.key({ modkey, "Shift" }, "f", function (c) c.fullscreen = not c.fullscreen  end,
		{description = "fullscreen", group = "client"}),

	awful.key({ modkey, "Shift" }, "c", function (c) c:kill() end,
		{description = "close", group = "client"}),
	awful.key({ modkey, }, "space", awful.client.floating.toggle,
		{description = "toggle floating", group = "client"})
)

clientbuttons = awful.util.table.join(
		awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
		awful.button({ modkey }, 1, awful.mouse.client.move),
		awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{ rule = { },
		properties = { border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			size_hints_honor = false,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap+awful.placement.no_offscreen
		}
	},

	-- Floating clients.
	{ rule_any = {
			instance = {
				"DTA", -- Firefox addon DownThemAll.
				"copyq", -- Includes session name in class.
				"exe", -- wine
			},
			class = {
				"Arandr",
				"Gpick",
				"Kruler",
				"MessageWin", -- kalarm.
				"Wpa_gui",
				"pinentry",
				"veromix",
				"xtightvncviewer",
				"mupen64plus",
				"mpv",
			},

			name = {
				"Event Tester", -- xev.
			},
			role = {
				"AlarmWindow", -- Thunderbird's calendar.
				"pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
			}
	}, properties = { floating = true }},
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
	-- Set the windows at the slave,
	-- i.e. put it at the end of others instead of setting it master.
	-- if not awesome.startup then awful.client.setslave(c) end

	if awesome.startup and
		not c.size_hints.user_position
		and not c.size_hints.program_position then
			-- Prevent clients from being unreachable after screen count changes.
			awful.placement.no_offscreen(c)
	end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
	if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
		and awful.client.focus.filter(c) then
		client.focus = c
	end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
