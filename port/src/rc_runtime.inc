// Recompiled-block runtime, included at the end of v60_core.cpp (so the
// generated blocks see MAME's macros). Blocks come from recomp/rc/translate.py.
#if __has_include("rc_blocks.inc")
#include "rc_blocks.inc"
#endif
#ifndef RC_HAVE_BLOCKS
const v60_device::rc_entry v60_device::s_rc_table[] = {{0, nullptr, 0, 0}};
const int v60_device::s_rc_count = 0;
#endif

#include <map>
std::map<uint32_t, uint64_t> *g_pchist;     // development aid (PCHIST): instructions run per block entry PC
uint64_t g_rc_calls, g_rc_insns, g_rc_none;     // development aid (RCSTATS): blocks run, their instructions, lookups with no block

namespace {
// the block entry PCs, open-addressed, and a direct-mapped cache of recent lookups
// in front holding the block itself (fn null: no block there). Built once
enum { RC_BITS = 15, RC_SIZE = 1 << RC_BITS };
int32_t rc_slot[RC_SIZE];
struct RcRecent { uint32_t pc, len, entry; uint32_t (v60_device::*fn)(); };
RcRecent rc_recent[1024];
bool rc_built;

void rc_build() {
	for (int i = 0; i < RC_SIZE; i++) rc_slot[i] = -1;
	for (int i = 0; i < v60_device::s_rc_count; i++) {
		uint32_t h = (v60_device::s_rc_table[i].pc * 2654435761u) >> (32 - RC_BITS);
		while (rc_slot[h] >= 0) h = (h + 1) & (RC_SIZE - 1);
		rc_slot[h] = i;
	}
	for (auto &r : rc_recent) { r.pc = ~0u; r.len = 0; r.entry = 0; r.fn = nullptr; }
	rc_built = true;
}

inline const RcRecent &rc_find(uint32_t pc) {
	RcRecent &r = rc_recent[(pc ^ (pc >> 10)) & 1023];
	if (r.pc != pc) {
		r.pc = pc;
		r.len = 0;
		r.fn = nullptr;
		for (uint32_t h = (pc * 2654435761u) >> (32 - RC_BITS);; h = (h + 1) & (RC_SIZE - 1)) {
			int32_t i = rc_slot[h];
			if (i < 0) break;
			if (v60_device::s_rc_table[i].pc == pc) {
				r.len = v60_device::s_rc_table[i].len; r.entry = v60_device::s_rc_table[i].entry; r.fn = v60_device::s_rc_table[i].fn;
				break;
			}
		}
	}
	return r;
}
}

uint32_t v60_device::rc_exec(uint32_t max_len)
{
	if (!rc_built) rc_build();
	const RcRecent &r = rc_find(PC);
#ifndef _arch_dreamcast
	if (!r.fn) g_rc_none++;
#endif
	if (!r.fn || r.len > max_len) return 0;          // none, or it would run past an event: the caller interprets
	uint32_t pc = PC; (void)pc;
	m_rc_entry = r.entry;
	uint32_t n = (this->*r.fn)();
#ifndef _arch_dreamcast
	g_rc_calls++; g_rc_insns += n;
	if (g_pchist) (*g_pchist)[pc] += n;
#endif
	return n;
}

// After the first block of a chunk (Machine::rc_run): more blocks, the lookup
// inlined, while no irq is pending, the idle loop is not next (the chunk's idle
// skip must see it) and the next block fits before the event: fit0 - n; a
// loop inside a block may go round again under budget0 - n (translate.py)
uint32_t v60_device::rc_chain(uint32_t n, int fit0, int budget0)
{
	while (m_irq_line == CLEAR_LINE && PC != 0x133505 && fit0 - int(n) > 0) {
		const RcRecent &r = rc_find(PC);
		if (!r.fn || int(r.len) > fit0 - int(n)) break;
		m_rc_done = 0;
		m_rc_budget = budget0 - int(n) > 0 ? uint32_t(budget0 - int(n)) : 0;
#ifndef _arch_dreamcast
		uint32_t pc = PC;
#endif
		m_rc_entry = r.entry;
		uint32_t m = (this->*r.fn)();
#ifndef _arch_dreamcast
		g_rc_calls++; g_rc_insns += m;
		if (g_pchist) (*g_pchist)[pc] += m;
#endif
		n += m;
	}
	return n;
}
