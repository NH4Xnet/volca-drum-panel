-- @description Volca listener (start)
-- @author NH4X
-- @version 1.0
-- @about
--   Starts the small background helper of the NH4X Volca Drum Suite. A JSFX can't write files or read
--   region names, so this helper does it for the panel and the sequencer:
--   - panel SOUND menu: SAVE / RENAME / DELETE a sound file
--   - sequencer REGIONS button: regions named "P1 ...", "P2 ..." switch the patterns
--   Run it once by hand and answer "Yes": from then on it starts with REAPER (one line in Scripts/__startup.lua).
--   Running it again restarts the helper. Everything else in the suite works without it.

local r = reaper
local GMEM = "NH4XVolca"
local TITLE = "Volca listener"

-- where this file is (also when __startup.lua runs it with dofile)
local me = debug.getinfo(1, "S").source:gsub("^@", "")
local dir = me:match("^(.*[/\\])") or ""
local res = r.GetResourcePath()

local function notify(text)   -- one line in the panel's readout
  r.gmem_attach(GMEM)
  for i = 1, #text do r.gmem_write(2 + i, text:byte(i)) end
  r.gmem_write(2, #text)
  r.gmem_write(1, 6)
  r.gmem_write(0, r.gmem_read(0) + 1)
end

local from_startup = VOLCA_LISTENER_STARTUP
VOLCA_LISTENER_STARTUP = nil

if not from_startup then
  -- run by hand: offer the autostart once (only if __startup.lua doesn't start it yet)
  local sfile = res .. "/Scripts/__startup.lua"
  local text = ""
  local f = io.open(sfile, "rb")
  if f then text = f:read("*a") f:close() end
  if not text:find("Volca listener (start).lua", 1, true) then
    local ans = r.ShowMessageBox(
      "The Volca listener is starting now.\n\n" ..
      "Start it automatically every time REAPER starts?\n" ..
      "(Adds one line to Scripts/__startup.lua. Nothing else in that file is changed.)",
      TITLE, 4)
    if ans == 6 then
      -- path relative to the resource folder when possible (portable installs can move)
      local p = me:gsub("\\", "/")
      local base = res:gsub("\\", "/")
      local line
      if p:sub(1, #base + 1):lower() == (base .. "/"):lower() then
        line = 'do local f = reaper.GetResourcePath() .. "/' .. p:sub(#base + 2) .. '"; ' ..
               'if reaper.file_exists(f) then VOLCA_LISTENER_STARTUP = true; dofile(f) end end'
      else
        line = 'do local f = [[' .. p .. ']]; if reaper.file_exists(f) then VOLCA_LISTENER_STARTUP = true; dofile(f) end end'
      end
      local nl = (text ~= "" and not text:find("\n$")) and "\n" or ""
      local w = io.open(sfile, "ab")
      if w then
        w:write(nl, "-- NH4X Volca Drum Suite: background helper (sound save + REGIONS)\n", line, "\n")
        w:close()
        r.ShowMessageBox("Done. The listener now starts with REAPER.\n\n" .. sfile, TITLE, 0)
      else
        r.ShowMessageBox("Could not write\n" .. sfile .. "\n\nThe listener runs now, but not after a restart.", TITLE, 0)
      end
    end
  end
  -- run again = end the old instance and start fresh, no REAPER dialog (REAPER 7.03+)
  if r.set_action_options then r.set_action_options(1 | 2) end
end

notify("LISTENER RUNNING")
VOLCA_SOUND_MODE = "listen"
dofile(dir .. "Volca sound (save).lua")
