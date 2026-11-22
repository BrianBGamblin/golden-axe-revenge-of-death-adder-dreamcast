// The Dreamcast's own settings (options menu; saved on the VMU with the EEPROM).
// 16 bytes; 0 is every field's default, so older saves (zeros here) still load.
#pragma once
#include <stdint.h>

struct DcOptions {
	uint8_t scanlines = 0;   // VGA 480p: 0 off, 1 light, 2 dark
	uint8_t smooth = 0;      // bilinear filtering of the picture
	uint8_t wide = 0;        // 1: 16:9 TV (the 4:3 picture pillarboxed for a stretching TV)
	uint8_t rumble = 1;
	uint8_t vmu_screen = 1;  // magic count on the VMU screens
	uint8_t mono = 0;        // 1: music to both speakers
	uint8_t music_att = 0;   // volume steps down from full (0..10)
	uint8_t sfx_att = 0;
	uint8_t controls = 0;    // button layout TYPE A..D
	uint8_t tv50 = 0;        // European console on a TV: 1 = PAL 50 Hz, 0 = PAL60
	uint8_t continues = 0;   // 0 unlimited (free play), 1..10 = 0..9 continues, 11 arcade coins
	uint8_t arcade_frame = 0; // 1: the arcade's 224 lines exactly; 0: FULL VIEW (16 more lines below: dlist.h); 2: WIDE (FULL VIEW + 53 columns each side, 16:9)
	uint8_t smooth_zoom = 0; // 1: scaled sprites (the intro's zooms) filtered smooth; shadows stay sharp
	int8_t pos_x = 0;        // the picture moved on the display: pixels right (-16..16)
	int8_t pos_y = 0;        // lines down (-12..12)
	uint8_t tv480i = 0;      // a TV cable: 1 = 480i (640x480 interlaced, for flat TVs that show 240p badly or not at all), 0 = 240p
};
constexpr int CONTINUES_ARCADE = 11;
