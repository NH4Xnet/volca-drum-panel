-- @description Volca duck to selected tracks (toggle)
-- @author NH4X
-- @version 1.0
-- @about
--   Adds the sequencer's duck trigger to every selected track, or removes it again (toggle per track).
--   Source = the track with "Volca Drum Sequencer". Its DUCK row picks the lanes that send the trigger (C1, ch 10).
--   The receive it makes: audio none, MIDI channel 10 -> bus 2 (original channel), pre-fader post-FX.
--   It only touches receives with exactly that signature. Other sends / receives stay as they are.
--   On the ducking track: a plugin that ducks on MIDI notes, e.g. ShaperBox 3 (VST3): MIDI input Bus 2
--   + 'Map REAPER MIDI buses to VST3 MIDI buses' in its pin menu (can't be set by script: reminder only).
--   Part of the NH4X Volca Drum Suite: https://github.com/NH4Xnet/volca-drum-suite

local r = reaper
local SRC_CH, DST_BUS = 10, 2
local FLAGS = SRC_CH | (DST_BUS << 22)   -- low 5 bits = source ch, bits 22+ = dest bus (0 = original)
local MODE = 3                           -- pre-fader (post-FX): sequencer MIDI is made by the JSFX

local function tname(tr)
  local ok, _, n = pcall(r.GetTrackName, tr)
  return ok and n or "?"
end

local function has_fx(tr, pat)
  for i = 0, r.TrackFX_GetCount(tr) - 1 do
    local _, n = r.TrackFX_GetFXName(tr, i, "")
    if n:find(pat, 1, true) then return n end
  end
end

-- find the sequencer tracks
local cands = {}
for i = 0, r.CountTracks(0) - 1 do
  local tr = r.GetTrack(0, i)
  for j = 0, r.TrackFX_GetCount(tr) - 1 do
    local _, n = r.TrackFX_GetFXName(tr, j, "")
    if n:find("Volca Drum Sequencer", 1, true) then cands[#cands + 1] = { tr = tr, kind = "Volca Drum Sequencer" }; break end
  end
end

if #cands == 0 then
  r.ShowMessageBox("No track with the Volca Drum Sequencer found.", "Duck to selected tracks", 0)
  return
end

local src = cands[1]
if #cands > 1 then
  local items = {}
  for k, c in ipairs(cands) do items[k] = c.kind .. "  (" .. tname(c.tr) .. ")" end
  gfx.init("", 0, 0)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local pick = gfx.showmenu("#Duck trigger from|" .. table.concat(items, "|"))
  gfx.quit()
  if pick < 2 then return end
  src = cands[pick - 1]
end

local nsel = r.CountSelectedTracks(0)
if nsel == 0 then
  r.ShowMessageBox("Select the track(s) that should duck first.", "Duck to selected tracks", 0)
  return
end

-- compare tracks by GUID (pointer userdata may not compare equal)
local SRCG = r.GetTrackGUID(src.tr)
local function srcof(dst, k)
  local t = r.GetTrackSendInfo_Value(dst, -1, k, "P_SRCTRACK")
  local ok, g = pcall(r.GetTrackGUID, t)
  return ok and g or ""
end

local function is_duck(dst, k)
  return srcof(dst, k) == SRCG
     and math.floor(r.GetTrackSendInfo_Value(dst, -1, k, "I_SRCCHAN")) == -1
     and math.floor(r.GetTrackSendInfo_Value(dst, -1, k, "I_MIDIFLAGS")) == FLAGS
end

local out, warn = {}, {}
r.Undo_BeginBlock()
for s = 0, nsel - 1 do
  local dst = r.GetSelectedTrack(0, s)
  local nm = tname(dst)
  if dst == src.tr then
    out[#out + 1] = nm .. ": skipped (this is the sequencer track)"
  else
    -- existing own receive? -> remove (toggle)
    local removed = 0
    for k = r.GetTrackNumSends(dst, -1) - 1, 0, -1 do
      if is_duck(dst, k) then r.RemoveTrackSend(dst, -1, k); removed = removed + 1 end
    end
    if removed > 0 then
      out[#out + 1] = nm .. ": duck receive REMOVED"
    else
      local idx = r.CreateTrackSend(src.tr, dst)
      r.SetTrackSendInfo_Value(src.tr, 0, idx, "I_SENDMODE", MODE)
      r.SetTrackSendInfo_Value(src.tr, 0, idx, "I_SRCCHAN", -1)
      r.SetTrackSendInfo_Value(src.tr, 0, idx, "I_MIDIFLAGS", FLAGS)
      -- self-check: read it back from the receiving side
      local ok = false
      for k = 0, r.GetTrackNumSends(dst, -1) - 1 do if is_duck(dst, k) then ok = true end end
      out[#out + 1] = nm .. ": duck receive ADDED" .. (ok and " (checked OK)" or "  !! CHECK FAILED, look at the routing window")
      local sb = has_fx(dst, "ShaperBox")
      if not sb then
        warn[#warn + 1] = nm .. ": no ShaperBox found (any plugin that ducks on MIDI notes works; ShaperBox 3 VST3 after the synth is tested)"
      elseif not sb:find("VST3", 1, true) then
        warn[#warn + 1] = nm .. ": ShaperBox is not the VST3 version (bus mapping needs VST3)"
      else
        warn[#warn + 1] = nm .. ": ShaperBox pins -> I/O -> MIDI input Bus 2 + 'Map REAPER MIDI buses to VST3 MIDI buses' (if not done yet)"
      end
    end
    -- other receives from the sequencer that carry MIDI = notes may reach the synth
    for k = 0, r.GetTrackNumSends(dst, -1) - 1 do
      if srcof(dst, k) == SRCG and not is_duck(dst, k) then
        local mf = math.floor(r.GetTrackSendInfo_Value(dst, -1, k, "I_MIDIFLAGS"))
        if (mf & 31) ~= 31 then
          warn[#warn + 1] = nm .. ": has another receive from " .. tname(src.tr) .. " with MIDI on (left as is; it can play the synth)"
        end
      end
    end
  end
end
r.Undo_EndBlock("Volca duck to selected tracks", -1)


local msg = "From: " .. src.kind .. " (" .. tname(src.tr) .. ")\n\n" .. table.concat(out, "\n")
if #warn > 0 then msg = msg .. "\n\n" .. table.concat(warn, "\n") end
r.ShowMessageBox(msg, "Duck to selected tracks", 0)
