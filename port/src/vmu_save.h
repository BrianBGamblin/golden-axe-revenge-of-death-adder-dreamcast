// VMU save: the arcade's EEPROM (its test-menu settings) plus the Dreamcast
// options, in one file GARODA.SYS on the first memory card found.
#pragma once
#include <stdint.h>

#include "dc_options.h"

// the arcade's own EEPROM check: CRC-16 (0x1021) over bytes 0x0A..0x43,
// register seeded 0xDEBD, as the game's routine at 0x130251
uint16_t eeprom_crc(const uint8_t img[128]);
// after changing settings bytes: counter++, CRC, mirror copy at 0x44 (as 0x130178)
void eeprom_seal(uint8_t img[128]);

// boot: fills eeprom/opt from the card if a valid save is there (true)
bool vmu_load(uint16_t eeprom[64], DcOptions &opt);
// once a frame: saves (in a background thread) when either has changed
void vmu_save_poll(const uint16_t eeprom[64], const DcOptions &opt);
// the card we save to ('A1' etc.), or null for none
const char *vmu_save_card();
