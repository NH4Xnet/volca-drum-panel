-- @description Volca sound (save / load)
-- @author NH4X
-- @version 1.0
-- @about
--   Volca Drum sounds = one part of the JSFX "Volca Drum Panel" (22 values: L1, L2, Pan..Clip).
--   What it does comes from the file name: (save), (load). The two files are identical.
--   Part = the focused part of the panel (click its title).
--     save   asks for a name, writes Data/NH4X Volca/VolcaSounds/<name>.txt
--     load   menu at the mouse with all saved sounds, loads the chosen one into the focused part
--            (for a key or controller; the panel's own SOUND menu loads without any script)
--   The panel's SOUND menu SAVE / RENAME / DELETE and the sequencer's REGIONS need the background helper:
--   run the action "Volca listener (start)" once (it can start itself with REAPER).
--   Delete moves the file into VolcaSounds/Deleted (undo: move it back by hand).
--   Part of the NH4X Volca Drum Suite: https://github.com/NH4Xnet/volca-drum-suite

local JSFX = "Volca Drum Panel"
local PER_PART = 22
local GMEM = "NH4XVolca"          -- gmem name + ExtState section (shared with panel + sequencer)
local HEAD = "NH4XVolca"          -- first word of sound files + index (the panel skips lines starting with it)
local DIR = reaper.GetResourcePath() .. "/Data/NH4X Volca/VolcaSounds"
local INDEX = reaper.GetResourcePath() .. "/Data/NH4X Volca/VolcaSounds index.txt"

-- mode: "listen" from "Volca listener (start)", else from the file name
local _, file = reaper.get_action_context()
local mode = VOLCA_SOUND_MODE or file:match("%((%a+)%)%.lua$")
VOLCA_SOUND_MODE = nil
if mode ~= "save" and mode ~= "load" and mode ~= "listen" then return end

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

-- tell the panel (readout); same message format as the kit scripts
local function notify(kind, text)
  reaper.gmem_attach(GMEM)
  text = text or ""
  for i = 1, #text do reaper.gmem_write(2 + i, text:byte(i)) end
  reaper.gmem_write(2, #text)
  reaper.gmem_write(1, kind)
  reaper.gmem_write(0, reaper.gmem_read(0) + 1)   -- counter last: the panel reacts on change
end

local function list_sounds()
  local t, i = {}, 0
  while true do
    local f = reaper.EnumerateFiles(DIR, i)
    if not f then break end
    local n = f:match("^(.+)%.txt$")
    if n then t[#t + 1] = n end
    i = i + 1
  end
  table.sort(t, function(a, b) return a:lower() < b:lower() end)
  return t
end

-- index for the panel's SOUND menu: header + all names (sorted)
local function write_index()
  local f = io.open(INDEX, "w")
  if not f then return end
  f:write(HEAD .. "SoundIndex 1\n")
  for _, n in ipairs(list_sounds()) do f:write(n, "\n") end
  f:close()
end

-- menu at the mouse with all sounds; returns the picked name or nil
local function pick_sound(title)
  local names = list_sounds()
  if #names == 0 then notify(6, "SOUNDS · NONE SAVED YET") return end
  local x, y = reaper.GetMousePosition()
  gfx.init("Volca sound", 0, 0, 0, x, y)
  gfx.x, gfx.y = 0, 0
  local sel = gfx.showmenu("#" .. title .. "||" .. table.concat(names, "|"))
  gfx.quit()
  if sel < 2 then return end   -- 0 = cancelled, 1 = title
  return names[sel - 1]
end

local function clean_name(name)
  -- file-safe name; menu-safe start (REAPER menus treat # ! < > | specially)
  return (name:gsub('[\\/:%*%?"<>|]', "-"):gsub("^[%s#!<>]+", ""):gsub("%s+$", ""))
end

-- delete = move into VolcaSounds\Deleted (undo: move it back by hand); rename = new name, same folder
local function manage(what)
  if what == "delete" then
    local name = pick_sound("DELETE SOUND")
    if not name then return end
    if reaper.ShowMessageBox('Delete "' .. name .. '"?\n(It goes to VolcaSounds/Deleted.)', "Volca sound delete", 4) ~= 6 then return end
    local bin = DIR .. "/Deleted"
    reaper.RecursiveCreateDirectory(bin, 0)
    local dst = bin .. "/" .. name .. ".txt"
    if reaper.file_exists(dst) then dst = bin .. "/" .. name .. " " .. os.date("%Y-%m-%d %H%M%S") .. ".txt" end
    local ok = os.rename(DIR .. "/" .. name .. ".txt", dst)
    write_index()
    notify(6, ok and ("SOUND DELETED · " .. name) or ("COULD NOT DELETE · " .. name))
  else -- rename
    local old = pick_sound("RENAME SOUND")
    if not old then return end
    local ok, new = reaper.GetUserInputs("Volca sound rename", 1, "New name:,extrawidth=160", old)
    if not ok then return end
    new = clean_name(new)
    if new == "" or new == old then return end
    local dst = DIR .. "/" .. new .. ".txt"
    if reaper.file_exists(dst) and new:lower() ~= old:lower() then
      reaper.ShowMessageBox('"' .. new .. '" exists already.', "Volca sound rename", 0) return
    end
    local done = os.rename(DIR .. "/" .. old .. ".txt", dst)
    write_index()
    notify(6, done and ("RENAMED · " .. old .. " > " .. new) or ("COULD NOT RENAME · " .. old))
  end
end

local function run(what)
  if what == "delete" or what == "rename" then return manage(what) end
  local track = focused_track()
  if not track then return end
  local fx = find_panel(track)
  if not fx then return end

  reaper.gmem_attach(GMEM)
  local part = math.floor(reaper.gmem_read(200) + 0.5)
  if part < 0 or part > 5 then
    notify(6, "SOUNDS · CLICK A PART FIRST")
    return
  end
  local first = part * PER_PART   -- 0-based param index of the part's first slider

  if what == "save" then
    reaper.RecursiveCreateDirectory(DIR, 0)
    local used = {}
    for _, n in ipairs(list_sounds()) do used[n:lower()] = true end
    local k = 1
    while used[string.format("sound %03d", k)] do k = k + 1 end
    local ok, name = reaper.GetUserInputs("Volca sound save · part " .. (part + 1), 1,
      "Name:,extrawidth=160", string.format("Sound %03d", k))
    if not ok then return end
    name = clean_name(name)
    if name == "" then return end
    local path = DIR .. "/" .. name .. ".txt"
    if reaper.file_exists(path) and
       reaper.ShowMessageBox('"' .. name .. '" exists. Overwrite?', "Volca sound save", 4) ~= 6 then return end
    local vals = {}
    for j = 0, PER_PART - 1 do
      vals[#vals + 1] = string.format("%d", math.floor(reaper.TrackFX_GetParam(track, fx, first + j) + 0.5))
    end
    local f = io.open(path, "w")
    if not f then reaper.ShowMessageBox("Could not write\n" .. path, "Volca sound save", 0) return end
    f:write(HEAD .. "Sound 1\n", "from part ", part + 1, "\n", table.concat(vals, " "), "\n")
    f:close()
    write_index()
    notify(5, name)

  else -- load
    local names = list_sounds()
    write_index()
    if #names == 0 then notify(6, "SOUNDS · NONE SAVED YET") return end
    local x, y = reaper.GetMousePosition()
    gfx.init("Volca sound", 0, 0, 0, x, y)
    gfx.x, gfx.y = 0, 0
    local sel = gfx.showmenu("#LOAD INTO PART " .. (part + 1) .. "||" .. table.concat(names, "|"))
    gfx.quit()
    if sel < 2 then return end   -- 0 = cancelled, 1 = title
    local name = names[sel - 1]
    local f = io.open(DIR .. "/" .. name .. ".txt", "r")
    if not f then return end
    local text = f:read("*a") f:close()
    local line = text:match("\n[^\n]*\n([%d%s]+)") or ""
    local vals = {}
    for v in line:gmatch("%d+") do vals[#vals + 1] = tonumber(v) end
    if #vals ~= PER_PART then notify(6, "SOUNDS · FILE BROKEN: " .. name) return end
    notify(4, name .. " > PART " .. (part + 1))   -- first, so the panel doesn't call it a kit load
    for j = 1, PER_PART do reaper.TrackFX_SetParam(track, fx, first + j - 1, vals[j]) end
  end
end

-- 1. the job of this run (startup = listen only)
if mode ~= "listen" then run(mode) end

-- 2. background listener for the panel's SAVE entry, unless one is already running
--    (heartbeat in ExtState GMEM/listener; cleared when the listener ends)
local beat = tonumber(reaper.GetExtState(GMEM, "listener")) or 0
if reaper.time_precise() - beat < 1.0 then return end

-- re-running this action while its listener runs: end the old one and start fresh (no REAPER dialog)
if mode ~= "listen" and reaper.set_action_options then reaper.set_action_options(1 | 2) end

reaper.gmem_attach(GMEM)
reaper.gmem_write(201, 0)   -- drop requests from before the start
reaper.atexit(function() reaper.DeleteExtState(GMEM, "listener", false) end)

-- regions named "P<n> ..." -> gmem 2000+ for the sequencer (heartbeat every scan, list only on change)
local last_sig, last_scan = nil, 0
local function scan_regions()
  local now = reaper.time_precise()
  if now - last_scan < 0.2 then return end
  last_scan = now
  local list, sig = {}, {}
  local _, nm, nr = reaper.CountProjectMarkers(0)
  for i = 0, nm + nr - 1 do
    local _, isrgn, pos, rgnend, name = reaper.EnumProjectMarkers(i)
    if isrgn then
      local n = tonumber((name or ""):match("^%s*[Pp](%d+)"))
      if n and n >= 1 and n <= 16 and #list < 64 then
        local a, b = reaper.TimeMap2_timeToQN(0, pos), reaper.TimeMap2_timeToQN(0, rgnend)
        list[#list + 1] = { a, b, n - 1 }
        sig[#sig + 1] = string.format("%.6f %.6f %d", a, b, n)
      end
    end
  end
  reaper.gmem_write(2000, (reaper.gmem_read(2000) + 1) % 1000000)
  local s = table.concat(sig, ";")
  if s == last_sig then return end
  last_sig = s
  reaper.gmem_write(2001, 0)   -- count first to 0: the sequencer never reads a half-written list
  for i, r in ipairs(list) do
    reaper.gmem_write(2002 + (i - 1) * 3, r[1]); reaper.gmem_write(2003 + (i - 1) * 3, r[2]); reaper.gmem_write(2004 + (i - 1) * 3, r[3])
  end
  reaper.gmem_write(2001, #list)
end

local function listen()
  reaper.SetExtState(GMEM, "listener", tostring(reaper.time_precise()), false)
  reaper.gmem_attach(GMEM)
  scan_regions()
  local req = reaper.gmem_read(201)   -- 1 save, 3 delete, 4 rename (from the panel's SOUND menu)
  if req == 1 or req == 3 or req == 4 then
    reaper.gmem_write(201, 0)
    run(req == 1 and "save" or req == 3 and "delete" or "rename")
  end
  reaper.defer(listen)
end
listen()
