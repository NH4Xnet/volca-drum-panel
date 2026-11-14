-- @description Volca kit (save / kit + / kit - / send all)
-- @author NH4X
-- @version 1.0
-- @about
--   Volca Drum kits = REAPER presets of the JSFX "Volca Drum Panel".
--   What it does comes from the file name: (kit +), (kit -), (save), (send all). The four files are identical.
--   Track = track of the focused (or last focused) FX window, else the first selected track.
--     kit + / kit -  next / previous preset (wraps). Loading a preset sends the changes.
--     save           saves the panel as a new preset "Kit 001", "Kit 002", ... (next free number)
--                    (REAPER has no API for saving presets: this writes the panel's preset file in REAPER's format)
--     send all       the panel sends the whole kit.
--   The panel's readout shows what happened.
--   Part of the NH4X Volca Drum Suite: https://github.com/NH4Xnet/volca-drum-suite

local JSFX = "Volca Drum Panel"
local NSLIDERS = 156   -- up to the QPI sliders 151-156 (144-150 = randomize/morph/color/look ride along)
local SENDALL = 137
local GMEM = "NH4XVolca"
local INI_FALLBACK = reaper.GetResourcePath() .. "/presets/js-NH4X Volca Drum Suite_Volca Drum_Volca Drum Panel_jsfx.ini"

-- the panel's own preset file, as REAPER names it (depends on where the JSFX is installed)
local function preset_file(track, fx)
  if reaper.TrackFX_GetUserPresetFilename then
    local a, b = reaper.TrackFX_GetUserPresetFilename(track, fx, "")
    local fn = type(b) == "string" and b or type(a) == "string" and a or ""
    if fn ~= "" then return fn end
  end
  return INI_FALLBACK
end

local _, file = reaper.get_action_context()
local what = file:match("%(([%a%s%+%-]+)%)%.lua$")
if not what then return end

local function focused_track()
  local ret, tracknum = reaper.GetFocusedFX2()
  if ret & 1 == 1 and tracknum > 0 then return reaper.GetTrack(0, tracknum - 1) end
  return reaper.GetSelectedTrack(0, 0)
end

local function find_panel(track)
  for i = 0, reaper.TrackFX_GetCount(track) - 1 do
    local _, name = reaper.TrackFX_GetFXName(track, i, "")
    if name:find(JSFX, 1, true) then return i end
  end
end

-- tell the panel (readout)
local function notify(kind, name)
  reaper.gmem_attach(GMEM)
  name = name or ""
  for i = 1, #name do reaper.gmem_write(2 + i, name:byte(i)) end
  reaper.gmem_write(2, #name)
  reaper.gmem_write(1, kind)
  reaper.gmem_write(0, reaper.gmem_read(0) + 1)   -- counter last: the panel reacts on change
end

local track = focused_track()
if not track then return end
local fx = find_panel(track)
if not fx then return end

if what == "kit +" or what == "kit -" then
  reaper.TrackFX_NavigatePresets(track, fx, what == "kit +" and 1 or -1)
  local _, name = reaper.TrackFX_GetPreset(track, fx, "")
  notify(1, name)

elseif what == "send all" then
  local v = reaper.TrackFX_GetParam(track, fx, SENDALL - 1)
  reaper.TrackFX_SetParam(track, fx, SENDALL - 1, (math.floor(v + 0.5) + 1) % 1000)
  notify(3, "")

elseif what == "save" then
  local INI = preset_file(track, fx)
  -- read the existing file
  local text = ""
  local f = io.open(INI, "rb")
  if f then text = f:read("*a") f:close() end
  local count = tonumber(text:match("NbPresets=(%d+)")) or 0
  local maxn = 0
  for n in text:gmatch("\nName=Kit (%d+)") do maxn = math.max(maxn, tonumber(n)) end
  local name = string.format("Kit %03d", maxn + 1)

  -- slider values as REAPER writes them: 64 values, preset name, the rest
  local tok = {}
  for i = 1, NSLIDERS do
    local v = reaper.TrackFX_GetParam(track, fx, i - 1)
    tok[#tok + 1] = string.format("%g", math.floor(v * 1000 + 0.5) / 1000)
    if i == 64 then tok[#tok + 1] = '"' .. name .. '"' end
  end
  local data = table.concat(tok, " ")
  -- REAPER adds one checksum byte: sum of all data bytes mod 256 (a wrong one = preset won't load)
  local sum = 0
  for i = 1, #data do sum = (sum + data:byte(i)) % 256 end
  local hex = (data .. string.char(sum)):gsub(".", function(c) return string.format("%02X", c:byte()) end)

  if text == "" then text = "[General]\r\nNbPresets=0\r\n" end
  text = text:gsub("NbPresets=%d+", "NbPresets=" .. (count + 1), 1)
  text = text:gsub("[\r\n]*$", "") .. string.format("\r\n\r\n[Preset%d]\r\nData=%s\r\nLen=%d\r\nName=%s\r\n",
    count, hex, #data, name)

  -- backup once per day, then write
  local bak = INI .. ".bak-" .. os.date("%Y-%m-%d")
  if not reaper.file_exists(bak) and text ~= "" then
    local src = io.open(INI, "rb")
    if src then local b = io.open(bak, "wb") b:write(src:read("*a")) b:close() src:close() end
  end
  f = io.open(INI, "wb")
  if not f then reaper.ShowMessageBox("Could not write\n" .. INI, "Volca kit save", 0) return end
  f:write(text) f:close()

  reaper.TrackFX_SetPreset(track, fx, name)   -- make it the current preset (REAPER rereads the file)
  notify(2, name)
end
