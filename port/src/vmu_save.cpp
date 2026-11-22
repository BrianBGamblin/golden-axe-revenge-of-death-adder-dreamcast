// recomp/dc/vmu_save.cpp - see vmu_save.h
#include "dclog.h"
#include "vmu_save.h"
#include <kos.h>
#include <dc/vmu_pkg.h>
#include <dc/vmufs.h>
#include <cstring>
#include <cstdio>

#include "vmu_icon.inc"          // recomp/dc/vmu_icon.py: the title's kanji logo

static const char FILE_NAME[] = "GARODA.SYS";
static const uint32_t MAGIC = 0x504f4147;    // 'GAOP'

struct Payload {
	uint32_t magic;
	uint32_t version;
	uint8_t eeprom[128];
	DcOptions opt;
};

uint16_t eeprom_crc(const uint8_t img[128]) {
	uint32_t r = 0xdebdeb00;
	auto shift8 = [&r]() {
		for (int i = 0; i < 8; i++) {
			bool c = r >> 31;
			r <<= 1;
			if (c) r ^= 0x10210000;
		}
	};
	for (int i = 0x0a; i < 0x0a + 0x3a; i++) {
		r = (r & 0xffffff00) | img[i];
		shift8();
	}
	shift8();
	return uint16_t(r >> 16);
}

void eeprom_seal(uint8_t img[128]) {
	uint32_t n;
	memcpy(&n, img + 0x0a, 4);
	n++;
	memcpy(img + 0x0a, &n, 4);
	uint16_t c = eeprom_crc(img);
	memcpy(img + 0x08, &c, 2);
	memcpy(img + 0x44, img + 0x08, 0x3c);
}

static maple_device_t *card;
static char card_name[4];
static Payload saved;                 // what the card holds (or would, once written)
static Payload pending;
static volatile bool writing;
static int changed_frames = -1;
static bool loaded;                   // vmu_load ran: saving is on (off for replayed recordings)

static maple_device_t *first_card() {
	for (int i = 0; i < 8; i++) {
		maple_device_t *d = maple_enum_type(i, MAPLE_FUNC_MEMCARD);
		if (d) return d;
	}
	return nullptr;
}

static void name_card(maple_device_t *d) {
	card = d;
	if (d) snprintf(card_name, sizeof card_name, "%c%d", 'A' + d->port, d->unit);
}

bool vmu_load(uint16_t eeprom[64], DcOptions &opt) {
	loaded = true;
	for (int i = 0; i < 8; i++) {
		maple_device_t *d = maple_enum_type(i, MAPLE_FUNC_MEMCARD);
		if (!d) break;
		void *buf = nullptr;
		int size = 0;
		if (vmufs_read(d, FILE_NAME, &buf, &size) < 0 || !buf) continue;
		vmu_pkg_t pkg;
		Payload p;
		bool ok = vmu_pkg_parse((uint8_t *)buf, size, &pkg) >= 0 && pkg.data_len == int(sizeof p);
		if (ok) memcpy(&p, pkg.data, sizeof p);
		free(buf);
		uint16_t crc;
		if (ok) memcpy(&crc, p.eeprom + 8, 2);
		if (!ok || p.magic != MAGIC || crc != eeprom_crc(p.eeprom)) {
			LOG("vmu: %s on %c%d is not a good save, ignored\n", FILE_NAME, 'A' + d->port, d->unit);
			continue;
		}
		memcpy(eeprom, p.eeprom, 128);
		opt = p.opt;
		name_card(d);
		saved = p;
		LOG("vmu: settings loaded from %s\n", card_name);
		return true;
	}
	name_card(first_card());
	// nothing saved yet: what the card should hold is what we run with (written on the first change)
	saved.magic = MAGIC;
	saved.version = 1;
	memcpy(saved.eeprom, eeprom, 128);
	saved.opt = opt;
	return false;
}

static void *write_thread(void *) {
	vmu_pkg_t pkg = {};
	strcpy(pkg.desc_short, "GOLDEN AXE RODA");
	strcpy(pkg.desc_long, "Settings");
	strcpy(pkg.app_id, "GARODA");
	pkg.icon_cnt = 1;
	memcpy(pkg.icon_pal, vmu_icon_pal, sizeof vmu_icon_pal);
	pkg.icon_data = (uint8_t *)vmu_icon_px;
	pkg.data_len = sizeof pending;
	pkg.data = (const uint8_t *)&pending;
	uint8_t *out = nullptr;
	int n = 0;
	int r = -1;
	if (vmu_pkg_build(&pkg, &out, &n) >= 0) {
		r = vmufs_write(card, FILE_NAME, out, n, VMUFS_OVERWRITE);
		free(out);
	}
	LOG("vmu: save to %s %s\n", card_name, r < 0 ? "FAILED" : "done");
	writing = false;
	return nullptr;
}

void vmu_save_poll(const uint16_t eeprom[64], const DcOptions &opt) {
	if (writing || !loaded) return;
	bool same = !memcmp(saved.eeprom, eeprom, 128) && !memcmp(&saved.opt, &opt, sizeof opt);
	if (same) { changed_frames = -1; return; }
	// wait for the change to settle (the test menu writes word by word)
	if (++changed_frames < 60) return;
	changed_frames = -1;
	if (!card || !maple_enum_type(0, MAPLE_FUNC_MEMCARD)) name_card(first_card());
	memcpy(saved.eeprom, eeprom, 128);
	saved.opt = opt;
	if (!card) return;                // no card: nothing to write to (the change is kept for this session)
	pending = saved;
	writing = true;
	thd_create(1, write_thread, nullptr);
}

const char *vmu_save_card() { return card ? card_name : nullptr; }
