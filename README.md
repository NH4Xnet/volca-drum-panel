# Volca Drum Panel

A free editor for the **Korg volca drum** inside REAPER, as one JSFX file. All parameters of all 6 parts and the waveguide on one screen, with a big readout that shows what you just changed in plain words (e.g. `SAW · OSCILLATE · EXP` instead of a raw number).

By NH4X. Version 1.0. Music: https://nh4x.bandcamp.com/

![Volca Drum Panel in REAPER](screenshot.png)

## What it does
- **Every parameter on one screen:** 6 parts (both layers + mix) and the waveguide. Drag, mouse wheel, double-click for default, or hover and type a number.
- **Readable values:** Select shows source, modulation and envelope by name; pan, filter, clip and model show what they mean.
- **Kits** = REAPER presets of the plugin. Loading one sends the changes to the volca. **SEND ALL** pushes the whole kit.
- **Link L1+L2** per part: a change on one layer goes to the other layer too.
- **Copy / paste** a part, also into another kit.
- **Randomize** part, layer or the whole kit, with an amount and drum-friendly ranges (short attacks, filter never fully closed). **Undo / redo**.
- **Locks:** lock single cells, rows or whole parts so randomize leaves them alone.
- **Morph A > B:** take two snapshots, then blend between them with one control.
- **One piano roll for all 6 parts:** notes 65 / 67 / 69 / 71 / 72 / 74 on any channel are sent to part 1-6.
- Everything is a plugin parameter: automation and MIDI controllers work.

## Requirements
- REAPER (Windows; on macOS it should work, but the fonts will look different, not tested).
- Korg volca drum connected via MIDI.
- **Split channel mode** on the volca (part 1-6 = MIDI channel 1-6). See the Korg manual.
- **FILT and CLIP** (purple row names) need the custom firmware **vdcf** by hj-oja (https://github.com/hj-oja/vdcf). On the stock Korg firmware these two do nothing; everything else works.

## Install
1. In REAPER: **Options > Show REAPER resource path in explorer/finder**, open the `Effects` folder.
2. Copy `Volca Drum Panel.jsfx` into it.
3. On a track: add the FX **JS: Volca Drum Panel**.
4. Set the track's **MIDI hardware output** to the port of your volca drum.
5. Press **SEND ALL** once so the volca matches the panel.

## How to use
| Action | How |
|---|---|
| Change a value | Drag or mouse wheel on the bar |
| Default value | Double-click the bar |
| Exact value | Hover the bar, type 0-127, Enter |
| Select a part | Click its title (PART 01 ... WAVEGUIDE) |
| Copy / paste a part | **SOUND** button, or right-click a part title |
| Save / load a kit | REAPER's preset menu at the top of the FX window |
| Randomize | Pick target and amount in RANDOM, press **ROLL**. **UNDO** takes back the last roll or paste (press again = redo) |
| Lock a cell | Right-click (or Shift+click) the bar |
| Lock a row | Click the row name (this part) / right-click it (all parts) |
| Lock a part | Shift+click its title |
| Morph | **SET A**, change or load a kit, **SET B**, then move the MORPH bar |

Locks and morph snapshots are saved with the project, not in presets.

## Good to know
- The volca has no MIDI out, so the panel only knows what it sent. If the volca was switched on late, press **SEND ALL**.
- Nothing is sent when a project loads (no surprise changes).
- The panel sends at most 8 CCs per audio block so a full kit dump doesn't choke the MIDI line.
- Pitch quantize has no MIDI CC, so it's front panel only.
- For MIDI controllers: Roll (slider 146) and Undo (147) act as buttons (send 1), Morph = slider 148.

## License
Free to use and change. If you share a changed version, please credit the original.
