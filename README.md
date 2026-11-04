# Volca Drum Panel

A free editor for the **Korg volca drum** inside REAPER, as one JSFX file. All parameters of all 6 parts and the waveguide on one screen, with a big readout that shows what you just changed in plain words (e.g. `SAW · OSCILLATE · EXP` instead of a raw number).

By NH4X. Version 1.0.1. Music: https://nh4x.bandcamp.com/

![Volca Drum Panel in REAPER](screenshot.png)

**New here? Go straight to [Setup](#setup-do-this-once-5-minutes). It takes 5 minutes, and step 2 is the one people miss.**

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

## What you need
- REAPER (made on Windows; on macOS it should work, but the fonts will look different, not tested).
- A Korg volca drum connected to your computer by MIDI (a MIDI interface or a USB-MIDI cable).
- The volca set to **split channel mode**, so part 1-6 listen on MIDI channel 1-6. The Korg manual shows how.
- **FILT and CLIP** (purple row names) need the custom firmware **vdcf** by hj-oja (https://github.com/hj-oja/vdcf). On the stock Korg firmware these two do nothing; everything else works.

## Setup: do this once (5 minutes)

> [!IMPORTANT]
> Most "it doesn't work" problems come from step 2 or step 4. If the volca stays silent, check those two first.

**1. Copy the file into REAPER**
In REAPER, go to **Options > Show REAPER resource path in explorer/finder**. A folder opens. Go into the `Effects` folder and drop `Volca Drum Panel.jsfx` in there.

**2. Let REAPER talk to your volca**
REAPER ignores MIDI ports until you switch them on.
Open **Options > Preferences** (Ctrl+P) and go to **Audio > MIDI Outputs**. Find the port your volca is plugged into (your MIDI interface or USB cable), right-click it and choose **Enable output**. Click OK.

**3. Put the panel on a track**
Make a new track, click its **FX** button and add **JS: Volca Drum Panel**. The panel opens.

**4. Send the track to the volca**
Click the track's **Route** button. Under **MIDI Hardware Output**, pick your volca's port and leave it on **Send to original channels**.
Don't pick a single channel there: the panel talks to part 1-6 on channels 1-6, and with one fixed channel only one part would listen.

**5. Sync once**
Press **SEND ALL** on the panel. Now the volca sounds exactly like what you see. Turn a control and you should hear it change right away.

**Playing it:** draw notes in a MIDI item on the same track (notes 65 / 67 / 69 / 71 / 72 / 74 = part 1-6). To play live from a keyboard, also arm the track and switch on input monitoring.

## How to use
| Action | How |
|---|---|
| Change a value | Drag or mouse wheel on the bar |
| Default value | Double-click the bar |
| Exact value | Hover the bar, type 0-127, Enter |
| Select (SEL) | Drag left/right from anywhere on the bar (slow, relative). Mouse wheel = one combination per notch |
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

## Changes
- 1.0.1: Select (SEL) is easier to set with the mouse: slow relative drag, wheel = one combination per notch.
- 1.0: first release.

## License
Free to use and change. If you share a changed version, please credit the original.
