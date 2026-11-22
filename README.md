# Golden Axe: The Revenge of Death Adder — Dreamcast Edition

**A disc builder.** Sega's 1992 arcade game, running natively on a real Sega Dreamcast,
built on your PC from your own arcade ROM set.

An unofficial fan port by **Gamblin Games**. Free. Not for sale. Not affiliated with,
endorsed by, or supported by SEGA. *Golden Axe* and *The Revenge of Death Adder* belong to SEGA.

> **There is no game in this download.** No ROMs, no disc image, no pictures, no music, no
> game program. The builder makes all of that on your PC, from the ROM files you supply.
> Please do not share built disc images.

## Download

Get **GoldenAxe-RODA-Dreamcast-Builder** from the [Releases](../../releases) page (one zip, about
145 MB). The files in this repository are the kit's scripts and notices; the zip is the whole kit.

## What you need

- A PC with 64-bit Windows 10 or 11, about 4 GB of free disk space, 8 GB of RAM.
- **Your own `ga2` ROM set** — the MAME set "Golden Axe: The Revenge of Death Adder (World, Rev B)",
  as `ga2.zip` or as a folder. The builder checks every file against the set it was tested with.
- **MAME 0.284.** If you do not have that exact version, the builder offers to download the
  official release from the MAME team's GitHub into its own folder (100 MB). Your own MAME is
  never touched.
- To play: a Dreamcast and a CD-R, or an optical-drive emulator (GDEMU, MODE), or the Flycast emulator.

## How to build the disc

1. Unzip this kit anywhere.
2. Put your `ga2.zip` beside `Build-Disc.cmd` (or drag it onto `Build-Disc.cmd`).
3. Double-click `Build-Disc.cmd`.

That is all. It runs unattended and takes about **25 minutes** on a mid-range PC; nearly
all of that is MAME playing the game's soundtrack and effects so they can be recorded.
The result is `GoldenAxe-RODA-Dreamcast.cdi` in the kit folder.

At the end the builder compares your disc, file by file, with the reference disc of this release
and tells you whether it is identical.

If the build stops, run it again: it carries on where it stopped. `Build-Disc.cmd` takes the
same options as the script (`-Fresh` starts over, `-Jobs 2` for a small PC, `-Mame <path>`).

## Playing it

- **Burn** the `.cdi` to a CD-R with DiscJuggler, or ImgBurn with its CDI plug-in, at a slow
  speed — or copy it to a GDEMU / MODE card — or open it in Flycast.
- **Start** starts and joins a game. Continues are free by default; with CONTINUES set to ARCADE
  the **L trigger** drops a coin, as at the cabinet.
- **R trigger** opens the options at any time.
- Up to **four players**, controllers in ports A–D (set PLAYERS in GAME OPTIONS).
- Hold **A + B + X + Y + Start** to return to the title.

### Options

| | |
|---|---|
| **GAME OPTIONS** | Difficulty, lives, vitality, players (2–4), continues, demo sound — the arcade board's own settings. |
| **PICTURE** | ARCADE (the arcade screen exactly), FULL VIEW (16 more lines below), WIDE (16:9 — set the TV to wide). |
| **SCREEN 16:9** | Keeps a 4:3 picture the right shape on a wide TV. |
| **TV MODE** | 240P is how the arcade game was made and is the mode to use: sharpest and fastest. 480I is there for flat TVs that will not show 240p; it is a little softer and slows down in busy fights. A VGA monitor or HDMI box is detected by itself and runs at 480p. |
| **ZOOM** | Scaled pictures as the arcade drew them, or smoothed. |
| **SCANLINES / SMOOTHING** | Scanlines (light or dark) on a VGA monitor or HDMI box; picture smoothing. |
| **HORIZONTAL / VERTICAL POS** | Moves the picture on the screen. |
| **SOUND** | Stereo or mono, music and effects volume. |
| **CONTROLS** | Four button layouts. |
| **VIBRATION / VMU DISPLAY** | Rumble on hits and magic; your magic pots on the VMU screen. |

Settings are saved to the VMU.

**If the picture ever goes wrong** (a mode your TV does not take): hold **L + R + Start** for two
seconds. All picture options go back to safe defaults. **L + R + Y** held for two seconds
switches between 240P and 480I.

## Known issues

- **480I drops frames.** With TV MODE set to 480I the game loses frame rate once more than a few
  enemies are on screen. **240P does not** - it is how the arcade game was made, it is sharper, and
  it is the mode to use on any TV that shows it. 480I is only there for flat TVs that will not
  show 240p.
- The very busiest fights (a dozen enemies) dip below full speed in 240P too.
- FULL VIEW shows 16 more lines than the arcade screen had. Where the game has no picture for
  them, the ground is carried on and full-screen pictures are stretched slightly.
- Windows may warn that the kit's programs are from an unknown publisher (they are not signed),
  and a strict antivirus may want your permission to let them run.

## How far it has been tested

Honestly:

- Played on a real NTSC Dreamcast on a CRT at 240p: plays well, sharp text, music and effects in place.
- 480p through VGA / HDMI boxes, WIDE and 16:9: built and checked in an emulator; **not yet confirmed on real hardware.**
- 480I on a real console: steady picture, but it loses frame rate with more than a few enemies on screen. 240P does not.
- The busiest fights (a dozen enemies on screen) drop below full speed on a real console.
- PAL consoles (50 Hz): supported in the code, not tested on hardware.
- This is a **beta**. If something is wrong on your console, the safe reset above will get you a picture back.

## Found a problem?

Open an issue on the project page with: your console (region, cable, TV), what you did, and
what you saw. A photo of the screen helps a great deal.

## Why a builder and not a disc image

Because the game is SEGA's. This kit holds only our own work and openly licensed tools. Every
byte of SEGA's game on your disc comes from the ROM files you already have:

- the game program is translated to Dreamcast code on your PC, from your program ROMs;
- the graphics are packed from your graphics ROMs;
- the music and effects are recorded by MAME, on your PC, from your sound ROMs;
- the title card, menu backdrop and save icon are drawn by running your ROMs.

## Credits

- **Port, recompiler, renderer, builder:** Gamblin Games.
- **The game:** SEGA (1992). All rights in it are theirs.
- **MAME** (mamedev.org): the port's CPU core and video hardware model are built on MAME's NEC V60
  core (Farfetch'd, R. Belmont) and Sega System 32 video code (Aaron Giles), BSD-3-Clause.
  MAME itself records the sound during the build.
- **KallistiOS** — the Dreamcast operating layer the port runs on — and its authors.
- The GNU toolchain (GCC, binutils), newlib, zlib, libpng, genromfs, makeip, mkisofs, cdi4dc/img4dc,
  Python, NumPy, SciPy, OpenCV, Pillow, LZ4, Nuitka.

Licences and source locations for all of these are in `LICENSES/` and `THIRD-PARTY.md`.
