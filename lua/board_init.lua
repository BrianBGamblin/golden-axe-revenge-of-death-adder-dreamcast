-- board_init.lua - what the board's protection CPU leaves in its shared RAM (2 KB, the main
-- program only reads it): one image after 30 frames -> dpram.bin. The run also lets the game
-- write its factory settings to MAME's nvram, which the builder picks up afterwards.
if _G.dp_done then return end
_G.dp_done = true
local space = manager.machine.devices[":mainpcb:maincpu"].spaces["program"]
local frame = 0
emu.register_frame_done(function()
	frame = frame + 1
	if frame == 30 then
		local out = io.open("dpram.bin", "wb")
		local t = {}
		for i = 0, 0x7fd do t[#t + 1] = string.char(space:read_u16(0xa00000 + i * 2) & 0xff) end
		t[#t + 1] = "\0\0"
		out:write(table.concat(t))
		out:close()
	end
	if frame >= 600 then manager.machine:exit() end
end)
