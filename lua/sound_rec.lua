-- sound_rec.lua - play the arcade's sound commands one at a time while MAME records
-- (-wavwrite). The attract mode is silent, so a command written to the sound latch
-- (0x700000) during it is heard alone.
--   SP_CMDS   "81,ad,..." hex commands, one every SP_SPAN frames from SP_START
--   SP_STOP   hex command written SP_GAP frames before each one (optional)
--   SP_MASK   the game's own latch writes become this command (one that does nothing)
--   SP_HOLDFADE  with SP_MASK: the game's own music-fade writes (0x7000f0) are held at 0
--   SP_FRAMES run length; SP_SCHED = the schedule file written
if _G.sp_done then return end
_G.sp_done = true
local space = manager.machine.devices[":mainpcb:maincpu"].spaces["program"]
local cmds = {}
for c in string.gmatch(os.getenv("SP_CMDS") or "", "[^,]+") do cmds[#cmds + 1] = tonumber(c, 16) end
local start = tonumber(os.getenv("SP_START") or "120")
local span = tonumber(os.getenv("SP_SPAN") or "600")
local stop = os.getenv("SP_STOP") and tonumber(os.getenv("SP_STOP"), 16) or nil
local gap = tonumber(os.getenv("SP_GAP") or "30")
local frames = tonumber(os.getenv("SP_FRAMES") or "3000")
local f = 0

local sched = io.open(os.getenv("SP_SCHED") or "schedule.txt", "w")
local mask_cmd = os.getenv("SP_MASK") and tonumber(os.getenv("SP_MASK"), 16) or nil
local ours = false
if mask_cmd then
	_G.sp_tap = space:install_write_tap(0x700000, 0x700001, "sp_latch", function(offset, data, mem_mask)
		if ours then return end
		sched:write(string.format("tap %d offset %x data %x mask %x\n", f, offset, data, mem_mask)); sched:flush()
		if (mem_mask & 0xff) ~= 0 then return (data & 0xff00) | mask_cmd end
	end)
end
if mask_cmd and os.getenv("SP_HOLDFADE") then
	_G.sp_fadetap = space:install_write_tap(0x7000f0, 0x7000f1, "sp_fade", function(offset, data, mem_mask)
		if (mem_mask & 0xff) ~= 0 then
			if (data & 0xff) ~= 0 then sched:write(string.format("tap fade %d value %x\n", f, data & 0xff)); sched:flush() end
			return data & 0xff00
		end
	end)
end
emu.register_frame_done(function()
	f = f + 1
	for i, c in ipairs(cmds) do
		local at = start + (i - 1) * span
		if stop and f == at - gap then ours = true; space:write_u8(0x700000, stop); ours = false end
		if f == at then
			ours = true; space:write_u8(0x700000, c); ours = false
			sched:write(string.format("%d %02x\n", f, c))
			sched:flush()
		end
	end
	if f >= frames then sched:close(); manager.machine:exit() end
end)
