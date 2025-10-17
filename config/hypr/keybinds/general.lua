-- =======================================================================================
--  GENERAL KEYBINDS MODULE (LUA) | CHIMERA GUARDIAN ARCH
--  Defines all essential keyboard shortcuts for the Hyprland environment.
-- =======================================================================================

-- Define the main modifier key (SUPER = Windows Key)
local MOD = "SUPER"

-- Define a helper function for cleaner keybinding syntax
local bind = function(mod, key, func, arg)
    hyprctl.keyword("bind", table.concat({mod, key, func, arg}, ","))
end

-- ===================================================
--  ESSENTIAL APPLICATIONS
-- ===================================================
bind(MOD, "RETURN", "exec", "kitty")        -- Open Terminal
bind(MOD, "D", "exec", "rofi -show drun")  -- Open Application Launcher
bind(MOD, "E", "exec", "thunar")           -- Open File Manager
bind(MOD, "L", "exec", "swaylock")         -- Lock Screen

-- ===================================================
--  QUALITY OF LIFE & PRODUCTIVITY TOOLS
-- ===================================================
-- Show clipboard history via Rofi
bind(MOD, "V", "exec", "cliphist list | rofi -dmenu | cliphist decode | wl-copy")

-- Screenshot fullscreen
bind("", "Print", "exec", "grim ~/Pictures/Screenshot-$(date +'%Y%m%d-%H%M%S').png")

-- Screenshot a selected region
bind("SHIFT", "Print", "exec", "slurp | grim -g - ~/Pictures/Screenshot-$(date +'%Y%m%d-%H%M%S').png")

-- ===================================================
--  WINDOW & SESSION MANAGEMENT
-- ===================================================
bind(MOD, "Q", "killactive", "")          -- Close active window
bind(MOD, "M", "exit", "")                -- Exit Hyprland session (logout)

-- Move focus between windows
bind(MOD, "left", "movefocus", "l")
bind(MOD, "right", "movefocus", "r")
bind(MOD, "up", "movefocus", "u")
bind(MOD, "down", "movefocus", "d")

-- Move the active window
bind(MOD .. " SHIFT", "left", "movewindow", "l")
bind(MOD .. " SHIFT", "right", "movewindow", "r")
bind(MOD .. " SHIFT", "up", "movewindow", "u")
bind(MOD .. " SHIFT", "down", "movewindow", "d")

-- ===================================================
--  WORKSPACE MANAGEMENT
-- ===================================================
-- Switch to a specific workspace
for i = 1, 9 do
    bind(MOD, tostring(i), "workspace", tostring(i))
end

-- Move the active window to a specific workspace
for i = 1, 9 do
    bind(MOD .. " SHIFT", tostring(i), "movetoworkspace", tostring(i))
end

-- Scroll through workspaces using the mouse wheel
bind(MOD, "mouse_down", "workspace", "e+1")
bind(MOD, "mouse_up", "workspace", "e-1")