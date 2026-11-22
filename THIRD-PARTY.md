# Third-party software in this kit

This kit bundles other people's software so that you have nothing to install. Each piece is
under its own licence; the texts are in `LICENSES/`. For the pieces whose licence asks that the
source code be offered (GCC, binutils, genromfs, mkisofs, cdi4dc), the source archives are
attached to the same release page this kit was downloaded from
(`gcc-13.2.0.tar.xz`, `binutils-2.43.tar.xz`, `KallistiOS-d142b568.tar.gz` - which holds the
compiler patches under `utils/dc-chain` and the sources of genromfs, bin2c, scramble and makeip -
`cdrtools-2.01.tar.bz2`, `img4dc-master.tar.gz`), and Gamblin Games will also supply a copy on
request through the project page.

Nothing in this kit comes from SEGA. No part of the game is included.

## Built into the Dreamcast program

| Component | Licence | Where it is used | Source |
|---|---|---|---|
| MAME NEC V60 CPU core (Farfetch'd, R. Belmont) | BSD-3-Clause | `port/mame/cpu/v60/`, `port/src/v60_core.*` (generated from it), and the translator's output | https://github.com/mamedev/mame (src/devices/cpu/v60) |
| MAME Sega System 32 video (Aaron Giles) | BSD-3-Clause | the port's video model (in `port/obj/`) follows `segas32_video.cpp` | https://github.com/mamedev/mame (src/mame/sega) |
| KallistiOS | KOS licence (BSD-style) | `toolchain/kos/` (headers, libraries), `port/obj/kos_snd_stream.o` (its sound stream, with two fixes of ours) | https://github.com/KallistiOS/KallistiOS (commit d142b568) |
| newlib | BSD-style (see COPYING.NEWLIB) | C library linked into the program | https://sourceware.org/newlib/ |
| libgcc, libstdc++ | GPL-3.0 with the GCC Runtime Library Exception | linked into the program | https://gcc.gnu.org/ (13.2.0) |
| zlib | zlib licence | linked into the program | https://zlib.net/ |

## Tools run during the build

| Component | Licence | Where | Source |
|---|---|---|---|
| GCC 13.2.0 for sh-elf | GPL-3.0 | `toolchain/sh-elf/` | https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/ with KallistiOS's patches: https://github.com/KallistiOS/KallistiOS/tree/master/utils/dc-chain |
| GNU binutils 2.43 for sh-elf | GPL-3.0 | `toolchain/sh-elf/` | https://ftp.gnu.org/gnu/binutils/ |
| genromfs | GPL-2.0 | `toolchain/utils/genromfs.exe` | in KallistiOS, utils/genromfs |
| bin2c, scramble | KOS licence / public domain (Marcus Comstedt) | `toolchain/utils/` | in KallistiOS, utils/ |
| IP.BIN boot sector, made with KallistiOS's makeip | BSD-2-Clause (see LICENSES/makeip) | `data/IP.BIN`: the IP.BIN Replacement bootstrap by LiENUS that makeip embeds, with this title's fields | in KallistiOS, utils/makeip |
| mkisofs (cdrtools 2.01) | GPL-2.0 | `toolchain/utils/mkisofs.exe` | https://sourceforge.net/projects/cdrtools/ |
| cdi4dc (IMG4DC, SiZiOUS) | GPL-3.0 | `toolchain/utils/cdi4dc.exe` | https://github.com/sizious/img4dc |
| Python 3.13, NumPy, SciPy, OpenCV, Pillow, LZ4 | PSF, BSD, Apache-2.0, HPND, BSD | inside `bin/gatool/` | python.org, numpy.org, scipy.org, opencv.org, python-pillow.org, github.com/python-lz4 |
| Nuitka (compiled `gatool`) | Apache-2.0 | `bin/gatool/` | https://nuitka.net/ |

The compiler binaries are those shipped with DreamSDK (https://dreamsdk.org), unmodified.

## Fetched at build time, not bundled

| Component | Licence | Notes |
|---|---|---|
| MAME 0.284 | GPL-2.0-or-later (project as a whole) | Downloaded from https://github.com/mamedev/mame/releases/tag/mame0284 only if you have no MAME 0.284, with your consent, checksum verified. |

## Ours

Everything else — the builder script, `bin/gatool`, `bin/script_run.exe`, `bin/pvr_check.exe`,
the objects in `port/obj/`, the Lua scripts, the data tables in `data/` — is © Gamblin Games and
is provided free of charge under the terms in `LICENSE.txt`.
