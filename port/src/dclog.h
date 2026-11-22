// Logging in the Dreamcast build goes out the serial port: at 115200 baud a
// line stalls the game for milliseconds on a real console. On only in test
// builds (build.sh: SCRIPT / DUMP / SNDTEST / MENUTEST / EETEST / PROF, or LOG=1).
#pragma once
#include <cstdio>
#ifndef DCLOG
#define DCLOG 0
#endif
#define LOG(...) do { if (DCLOG) printf(__VA_ARGS__); } while (0)
