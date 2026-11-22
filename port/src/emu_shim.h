// Just enough of MAME's emu.h for the V60 core to compile standalone.
#pragma once
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstdarg>
#include <functional>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;
typedef uint32_t offs_t;

enum { CLEAR_LINE = 0, ASSERT_LINE = 1, HOLD_LINE = 2 };
enum { INPUT_LINE_NMI = 0x7f };

[[noreturn]] void fatalerror(const char *fmt, ...);
void logerror(const char *fmt, ...);
#define osd_printf_debug(...) ((void)0)

#include <cassert>
#include <cmath>
#include <cstring>
inline float u2f(uint32_t v) { float f; memcpy(&f, &v, 4); return f; }
inline uint32_t f2u(float f) { uint32_t v; memcpy(&v, &f, 4); return v; }

// eminline.h semantics
constexpr int64_t mul_32x32(int32_t a, int32_t b) { return int64_t(a) * int64_t(b); }
constexpr uint64_t mulu_32x32(uint32_t a, uint32_t b) { return uint64_t(a) * uint64_t(b); }
inline int32_t div_64x32_rem(int64_t a, int32_t b, int32_t &rem) {
	int32_t q = int32_t(a / b); rem = int32_t(a % b); return q;
}
inline uint32_t divu_64x32_rem(uint64_t a, uint32_t b, uint32_t &rem) {
	uint32_t q = uint32_t(a / b); rem = uint32_t(a % b); return q;
}
template <typename T> constexpr T BIT(T x, int n) { return (x >> n) & T(1); }
template <int B, typename T, typename... U> T bitswap(T val, U... b) {
	int bits[] = {int(b)...};
	T r = 0;
	for (int i = 0; i < B; i++) r = (r << 1) | ((val >> bits[i]) & 1);
	return r;
}
constexpr uint16_t swapendian_int16(uint16_t v) { return uint16_t((v << 8) | (v >> 8)); }
constexpr uint32_t swapendian_int32(uint32_t v) {
	return (v << 24) | ((v << 8) & 0xff0000) | ((v >> 8) & 0xff00) | (v >> 24);
}

// The V60 sees a 24-bit, 16-bit-wide little-endian bus. Every access is
// broken into native 16-bit bus cycles in the order MAME's memory system
// uses, so a replayed device log lines up access for access.
struct address_space {
	u16 (*r16)(offs_t a, u16 mask);
	void (*w16)(offs_t a, u16 data, u16 mask);

	// Fast paths (optional): program ROM and work RAM are plain memory, so
	// reading them byte-wise here gives exactly what the 16-bit bus split
	// would. Everything else still goes through r16/w16.
	const u8 *rom_lo = nullptr, *rom_hi = nullptr, *rom_data = nullptr;  // 128K, 128K, 512K
	u8 *ram = nullptr;                                                   // 64K at 0x200000, mirrored
	const u8 *rom_ptr(offs_t a, offs_t n) const {
		if (!rom_lo) return nullptr;
		a &= 0xffffff;
		if (a >= 0xf00000) a &= 0xfffff;
		else if (a >= 0x200000) return nullptr;
		if (a < 0x80000) return ((a & 0x1ffff) + n <= 0x20000) ? rom_lo + (a & 0x1ffff) : nullptr;
		if (a < 0x100000) return ((a & 0x1ffff) + n <= 0x20000) ? rom_hi + (a & 0x1ffff) : nullptr;
		return ((a & 0x7ffff) + n <= 0x80000) ? rom_data + (a & 0x7ffff) : nullptr;
	}
	bool is_ram(offs_t a) const { return ram && (a & 0xf00000) == 0x200000; }
	// n bytes starting at a, all inside the RAM window (mirrors wrap at 64K)
	bool ram_span(offs_t a, int n) const { return is_ram(a) && (a & 0xfffff) + n <= 0x100000; }
	// aligned work-RAM accesses as one native load/store (the SH4 and the V60 are both
	// little-endian; an aligned access never crosses the 64K mirror). PC: only while
	// the development aids are off
#ifdef _arch_dreamcast
	bool ram_fast(offs_t a, offs_t align) const { return is_ram(a) && !(a & align); }
#else
	bool ram_fast(offs_t a, offs_t align) const { return is_ram(a) && !(a & align) && !ram_touched && ram_watch < 0; }
#endif
#ifdef _arch_dreamcast
	u8 &rb(offs_t a) { return ram[a & 0xffff]; }
#else
	u8 &rb(offs_t a) { if (ram_touched) ram_touched[a & 0xffff] = 1; return ram[a & 0xffff]; }
	u8 *ram_touched = nullptr;     // development aid (PC): mark work-RAM bytes the program reads or writes
	// development aid (PC): log writes to work-RAM byte ram_watch (frame, value, instruction)
	long ram_watch = -1;
	const uint32_t *pc_now = nullptr;
	FILE *watch_log = nullptr;
	int *watch_frame = nullptr;
	void wlog(offs_t a, int n, u32 d) {
		for (int i = 0; i < n; i++)
			if (((a + i) & 0xffff) == (ram_watch & 0xffff))
				fprintf(watch_log, "%d %02x pc %06x\n", watch_frame ? *watch_frame : 0, unsigned((d >> (8 * i)) & 0xff), pc_now ? unsigned(*pc_now) : 0);
	}
#endif
	u8 fetch8(offs_t a) { const u8 *p = rom_ptr(a, 1); return p ? p[0] : read_byte(a); }
	u16 fetch16(offs_t a) { const u8 *p = rom_ptr(a, 2); return p ? u16(p[0] | p[1] << 8) : read_word_unaligned(a); }
	u32 fetch32(offs_t a) { const u8 *p = rom_ptr(a, 4); return p ? u32(p[0] | p[1] << 8 | p[2] << 16 | u32(p[3]) << 24) : read_dword_unaligned(a); }

	u8 read_byte(offs_t a) {
		if (is_ram(a)) return ram[a & 0xffff];
		if (const u8 *p = rom_ptr(a, 1)) return p[0];
		a &= 0xffffff;
		return (a & 1) ? r16(a & ~1, 0xff00) >> 8 : r16(a, 0x00ff) & 0xff;
	}
	u16 read_word_unaligned(offs_t a) {
		if (ram_fast(a, 1)) return *(const u16 *)&ram[a & 0xffff];
		if (ram_span(a, 2)) return u16(rb(a) | rb(a + 1) << 8);
		if (const u8 *p = rom_ptr(a, 2)) return u16(p[0] | p[1] << 8);
		a &= 0xffffff;
		if (!(a & 1)) return r16(a, 0xffff);
		u16 lo = r16(a - 1, 0xff00) >> 8;
		u16 hi = r16((a + 1) & 0xffffff, 0x00ff) & 0xff;
		return lo | (hi << 8);
	}
	u32 read_dword_unaligned(offs_t a) {
		if (ram_fast(a, 3)) return *(const u32 *)&ram[a & 0xffff];
		if (ram_span(a, 4)) return u32(rb(a) | rb(a + 1) << 8 | rb(a + 2) << 16 | u32(rb(a + 3)) << 24);
		if (const u8 *p = rom_ptr(a, 4)) return u32(p[0] | p[1] << 8 | p[2] << 16 | u32(p[3]) << 24);
		a &= 0xffffff;
		if (!(a & 1)) {
			u32 lo = r16(a, 0xffff);
			u32 hi = r16((a + 2) & 0xffffff, 0xffff);
			return lo | (hi << 16);
		}
		u32 b0 = r16(a - 1, 0xff00) >> 8;
		u32 mid = r16((a + 1) & 0xffffff, 0xffff);
		u32 b3 = r16((a + 3) & 0xffffff, 0x00ff) & 0xff;
		return b0 | (mid << 8) | (b3 << 24);
	}
	u32 read_dword(offs_t a) { return read_dword_unaligned(a); }
	u64 read_qword_unaligned(offs_t a) {
		u64 lo = read_dword_unaligned(a);
		return lo | (u64(read_dword_unaligned(a + 4)) << 32);
	}
	void write_byte(offs_t a, u8 d) {
#ifndef _arch_dreamcast
		if (ram_watch >= 0 && is_ram(a)) wlog(a, 1, d);
#endif
		if (is_ram(a)) { rb(a) = d; return; }
		a &= 0xffffff;
		if (a & 1) w16(a & ~1, u16(d) << 8, 0xff00);
		else w16(a, d, 0x00ff);
	}
	void write_word_unaligned(offs_t a, u16 d) {
#ifndef _arch_dreamcast
		if (ram_watch >= 0 && ram_span(a, 2)) wlog(a, 2, d);
#endif
		if (ram_fast(a, 1)) { *(u16 *)&ram[a & 0xffff] = d; return; }
		if (ram_span(a, 2)) { rb(a) = u8(d); rb(a + 1) = u8(d >> 8); return; }
		a &= 0xffffff;
		if (!(a & 1)) { w16(a, d, 0xffff); return; }
		w16(a - 1, u16(d << 8), 0xff00);
		w16((a + 1) & 0xffffff, d >> 8, 0x00ff);
	}
	void write_dword_unaligned(offs_t a, u32 d) {
#ifndef _arch_dreamcast
		if (ram_watch >= 0 && ram_span(a, 4)) wlog(a, 4, d);
#endif
		if (ram_fast(a, 3)) { *(u32 *)&ram[a & 0xffff] = d; return; }
		if (ram_span(a, 4)) { rb(a) = u8(d); rb(a + 1) = u8(d >> 8); rb(a + 2) = u8(d >> 16); rb(a + 3) = u8(d >> 24); return; }
		a &= 0xffffff;
		if (!(a & 1)) {
			w16(a, d & 0xffff, 0xffff);
			w16((a + 2) & 0xffffff, d >> 16, 0xffff);
			return;
		}
		w16(a - 1, u16(d << 8), 0xff00);
		w16((a + 1) & 0xffffff, (d >> 8) & 0xffff, 0xffff);
		w16((a + 3) & 0xffffff, d >> 24, 0x00ff);
	}
	void write_qword_unaligned(offs_t a, u64 d) {
		write_dword_unaligned(a, u32(d));
		write_dword_unaligned(a + 4, u32(d >> 32));
	}
};
