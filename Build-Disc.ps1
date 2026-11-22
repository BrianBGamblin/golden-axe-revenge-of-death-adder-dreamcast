# Golden Axe: The Revenge of Death Adder - Dreamcast Edition : disc builder
#
# Builds a Dreamcast disc image on YOUR PC from YOUR OWN arcade ROM set (MAME set "ga2").
# Nothing of the game is in this kit: every picture, sound and line of game program on the
# disc is made here, now, from your ROM files.
#
#   Build-Disc.cmd                      (looks for ga2.zip or a ga2 folder beside this file)
#   Build-Disc.cmd C:\roms\ga2.zip
#   powershell -ExecutionPolicy Bypass -File Build-Disc.ps1 -Roms C:\roms\ga2.zip [-Mame C:\MAME\mame.exe] [-Yes] [-Fresh]
#
#   -Roms    ga2.zip, or a folder holding the ga2 ROM files
#   -Mame    your mame.exe (MAME 0.284). Without it the builder looks in the usual places and,
#            if none is found, offers to download the official MAME 0.284 from mamedev's GitHub
#   -Yes     answer yes to the download question
#   -Fresh   throw the work folder away and start again (default: carry on where it stopped)
#   -Jobs    MAME recordings run at once (default 4; use 2 on a small PC)
#   -OwnMame always use the builder's own downloaded MAME, never one found on this PC
param([string]$Roms = "", [string]$Mame = "", [switch]$Yes, [switch]$Fresh, [int]$Jobs = 4, [string]$Work = "", [string]$Out = "", [switch]$OwnMame)

$ErrorActionPreference = "Stop"
$Kit = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Work) { $Work = Join-Path $Kit "work" }
if (-not $Out) { $Out = Join-Path $Kit "GoldenAxe-RODA-Dreamcast.cdi" }
$MameVersion = "0.284"
$MameUrl = "https://github.com/mamedev/mame/releases/download/mame0284/mame0284b_x64.exe"
$MameSha256 = "dbfe2bd0019b1139044a61d63e24a7dbda8360a26d3bcb36f4747e6724359b64"
$T0 = Get-Date

function Say($msg) { Write-Host ("[{0,5:N1} min] {1}" -f ((Get-Date) - $T0).TotalMinutes, $msg) }
function Fail($msg) { Write-Host ""; Write-Host "STOPPED: $msg" -ForegroundColor Red; exit 1 }
function Done($name) { Test-Path (Join-Path $Work "stamps\$name") }
function Mark($name) { New-Item -ItemType File -Force (Join-Path $Work "stamps\$name") | Out-Null }

# one program, its output to a log; stops the build if it fails
function Run($log, $exe, $argv, $cwd) {
    $logf = Join-Path $Work "logs\$log.log"
    Push-Location $cwd
    try {
        $old = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        & $exe @argv *> $logf
        $code = $LASTEXITCODE
        $ErrorActionPreference = $old
    } finally { Pop-Location }
    if ($code -ne 0) {
        Get-Content $logf -Tail 15 | ForEach-Object { Write-Host "    $_" }
        Fail "$log failed (exit $code). Full log: $logf"
    }
}
# the kit's tool program (compiled: bin\gatool.exe)
$GaExe = Join-Path $Kit "bin\gatool\gatool.exe"
$GaDev = $false
if (-not (Test-Path $GaExe)) {
    if ($env:GAR_DEV -and (Test-Path (Join-Path $Kit "tools-src\gatool.py"))) { $GaDev = $true } else { Fail "bin\gatool\gatool.exe is missing - unpack the whole kit." }
}
function Tool($log, $argv, $cwd) {
    if ($GaDev) { Run $log "python" (@((Join-Path $Kit "tools-src\gatool.py")) + $argv) $cwd } else { Run $log $GaExe $argv $cwd }
}

Write-Host ""
Write-Host "Golden Axe: The Revenge of Death Adder - Dreamcast Edition : disc builder"
Write-Host "An unofficial fan port by Gamblin Games. Not affiliated with or endorsed by SEGA."
Write-Host "The game belongs to SEGA; you need your own ROM set (MAME: ga2). Free, never for sale."
Write-Host ""

# ---------------------------------------------------------------- 0. folders, ROMs
if ($Fresh -and (Test-Path $Work)) { Remove-Item -Recurse -Force $Work }
foreach ($d in "stamps", "logs", "roms\ga2", "rec", "recomp\harness", "recomp\dc\obj", "recomp\dc\romdisk", "recomp\dc\cd_data", "recomp\dc\logo",
        "recomp\traces\script", "recomp\traces\pvr_check", "reference\mame-source\cpu") {
    New-Item -ItemType Directory -Force (Join-Path $Work $d) | Out-Null
}
$RomDir = Join-Path $Work "roms\ga2"
if (-not (Done "roms")) {
    if (-not $Roms) {
        foreach ($c in "ga2.zip", "ga2", "roms\ga2.zip", "roms\ga2") { if (Test-Path (Join-Path $Kit $c)) { $Roms = Join-Path $Kit $c; break } }
    }
    if (-not $Roms -or -not (Test-Path $Roms)) { Fail "No ROM set. Put your ga2.zip beside Build-Disc.cmd, or drop it onto Build-Disc.cmd." }
    Say "ROM set: $Roms"
    if ((Get-Item $Roms).PSIsContainer) { Copy-Item (Join-Path $Roms "*") $RomDir -Force }
    else { Expand-Archive -LiteralPath $Roms -DestinationPath $RomDir -Force }
    Tool "roms" @("roms", $RomDir, (Join-Path $Kit "data\roms.json")) $Work
    Get-Content (Join-Path $Work "logs\roms.log") -Tail 1 | ForEach-Object { Say $_ }
    Mark "roms"
}

# ---------------------------------------------------------------- 1. MAME
function MameVersionOf($exe) { try { ((& $exe -version) | Select-Object -First 1) -replace ' .*', '' } catch { "" } }
if ($OwnMame) { $Mame = ""; if (Test-Path (Join-Path $Work "mame\mame.exe")) { $Mame = Join-Path $Work "mame\mame.exe" } }
elseif (-not $Mame) {
    foreach ($c in (Join-Path $Kit "mame\mame.exe"), (Join-Path $Work "mame\mame.exe"), "C:\MAME\mame.exe", "C:\mame\mame.exe") { if (Test-Path $c) { $Mame = $c; break } }
    if (-not $Mame) { $g = Get-Command mame.exe -ErrorAction SilentlyContinue; if ($g) { $Mame = $g.Source } }
}
if ($Mame -and (MameVersionOf $Mame) -ne $MameVersion) {
    Say ("{0} is MAME {1}; the builder is tested with {2} and uses its own copy of {2}." -f $Mame, (MameVersionOf $Mame), $MameVersion)
    $Mame = ""
    if (Test-Path (Join-Path $Work "mame\mame.exe")) { $Mame = Join-Path $Work "mame\mame.exe" }
}
if (-not $Mame) {
    Write-Host "MAME $MameVersion is needed to record the game's sound from your ROMs."
    Write-Host "The builder can download the official release (100 MB) from:"
    Write-Host "  $MameUrl"
    Write-Host "into its own work folder. Your own MAME, if you have one, is not touched."
    if (-not $Yes) { $a = Read-Host "Download it now? [Y/n]"; if ($a -and $a -notmatch '^[Yy]') { Fail "MAME $MameVersion is needed. Get it from mamedev.org and run again with -Mame <path to mame.exe>." } }
    $pkg = Join-Path $Work "mame0284b_x64.exe"
    if (-not (Test-Path $pkg) -or (Get-FileHash $pkg -Algorithm SHA256).Hash.ToLower() -ne $MameSha256) {
        Say "downloading MAME $MameVersion ..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $MameUrl -OutFile $pkg -UseBasicParsing
    }
    if ((Get-FileHash $pkg -Algorithm SHA256).Hash.ToLower() -ne $MameSha256) { Fail "The MAME download does not match its published checksum. Delete $pkg and try again." }
    Say "unpacking MAME ..."
    $md = Join-Path $Work "mame"
    New-Item -ItemType Directory -Force $md | Out-Null
    $p = Start-Process -FilePath $pkg -ArgumentList "-o`"$md`"", "-y" -Wait -PassThru -WindowStyle Hidden
    $Mame = Join-Path $md "mame.exe"
    if (-not (Test-Path $Mame)) { Fail "MAME did not unpack into $md." }
}
Say "MAME: $Mame"

# ---------------------------------------------------------------- 2. the board's own data (10 s)
$H = Join-Path $Work "recomp\harness"
$Dc = Join-Path $Work "recomp\dc"
if (-not (Done "init")) {
    Say "starting the board once (factory settings, protection data) ..."
    $id = Join-Path $Work "rec\init"
    if (Test-Path $id) { Remove-Item -Recurse -Force $id }
    New-Item -ItemType Directory -Force $id | Out-Null
    Run "mame_init" $Mame @("ga2", "-noreadconfig", "-rompath", (Join-Path $Work "roms"), "-cfg_directory", "cfg", "-nvram_directory", "nvram",
        "-video", "none", "-sound", "none", "-nothrottle", "-seconds_to_run", "100000", "-autoboot_script", (Join-Path $Kit "lua\board_init.lua")) $id
    if (-not (Test-Path "$id\dpram.bin") -or -not (Test-Path "$id\nvram\ga2\mainpcb_eeprom")) { Fail "MAME did not run the game. Is the ROM set complete? See $Work\logs\mame_init.log" }
    Copy-Item "$id\dpram.bin" "$H\v25_dpram.bin" -Force
    Copy-Item "$id\nvram\ga2\mainpcb_eeprom" "$H\eeprom_base.bin" -Force
    Tool "eeprom" @("eeprom4", "$H\eeprom_base.bin", "$H\eeprom_4p.bin") $Work
    Mark "init"
}

# ---------------------------------------------------------------- 3. sound recordings (background)
# name, sample rate, frames, span, start, mask, stop, gap, holdfade, commands
$all = ((1..255) | ForEach-Object { '{0:x2}' -f $_ }) -join ','
$Recs = @(
    @{ n = "music_clean"; rate = 44100; frames = 290700; span = 14400; start = 200; mask = "80"; stop = ""; gap = 30; hold = $true;  cmds = "81,82,83,84,85,86,87,88,89,8a,8b,8c,8d,8e,8f,90,91,92,93,94,95" },
    @{ n = "music";       rate = 44100; frames = 302900; span = 14400; start = 200; mask = "80"; stop = "00"; gap = 20; hold = $false; cmds = "81,82,84,85,86,87,88,89,8a,8b,8c,8d,8e,8f,90,91,92,93,94,95,96,b7" },
    @{ n = "music2";      rate = 44100; frames = 73100;  span = 36000; start = 200; mask = "80"; stop = "00"; gap = 20; hold = $false; cmds = "81,83,97" },
    @{ n = "survey";      rate = 48000; frames = 76800;  span = 300;   start = 200; mask = "80"; stop = "00"; gap = 20; hold = $false; cmds = $all }
)
$RecDir = Join-Path $Work "rec"
function StartRec($r) {
    $d = Join-Path $RecDir $r.n
    if (Test-Path $d) { Remove-Item -Recurse -Force $d }
    New-Item -ItemType Directory -Force "$d\nvram\ga2" | Out-Null
    Copy-Item "$H\eeprom_base.bin" "$d\nvram\ga2\mainpcb_eeprom" -Force
    $env:SP_CMDS = $r.cmds; $env:SP_SPAN = "$($r.span)"; $env:SP_START = "$($r.start)"; $env:SP_FRAMES = "$($r.frames)"; $env:SP_GAP = "$($r.gap)"
    $env:SP_SCHED = "$($r.n).sched.txt"
    foreach ($v in "SP_MASK", "SP_STOP", "SP_HOLDFADE") { Remove-Item "Env:$v" -ErrorAction SilentlyContinue }
    if ($r.mask) { $env:SP_MASK = $r.mask }
    if ($r.stop) { $env:SP_STOP = $r.stop }
    if ($r.hold) { $env:SP_HOLDFADE = "1" }
    $a = "ga2 -noreadconfig -rompath `"$(Join-Path $Work 'roms')`" -cfg_directory cfg -nvram_directory nvram -video none -sound none -nothrottle -seconds_to_run 100000 " +
         "-autoboot_script `"$(Join-Path $Kit 'lua\sound_rec.lua')`" -wavwrite $($r.n).wav -samplerate $($r.rate)"
    Start-Process -FilePath $Mame -ArgumentList $a -WorkingDirectory $d -WindowStyle Hidden -PassThru -RedirectStandardOutput "$d\mame.out" -RedirectStandardError "$d\mame.err"
}
$queue = New-Object System.Collections.ArrayList
foreach ($r in $Recs) { if (-not (Done "rec_$($r.n)")) { [void]$queue.Add($r) } }
$running = @{}
function PumpRecs {
    foreach ($n in @($running.Keys)) {
        $e = $running[$n]
        if ($e.p.HasExited) {
            $wav = Join-Path $RecDir "$n\$n.wav"
            $want = 44 + [int64]$e.r.frames * ($e.r.rate / 60) * 4
            if (-not (Test-Path $wav) -or (Get-Item $wav).Length -lt $want - 8192) { Fail "The recording '$n' stopped early. See $RecDir\$n\mame.err" }
            Mark "rec_$n"; $running.Remove($n); Say "recording '$n' done"
        }
    }
    while ($running.Count -lt $Jobs -and $queue.Count -gt 0) {
        $r = $queue[0]; $queue.RemoveAt(0)
        $running[$r.n] = @{ p = (StartRec $r); r = $r }
    }
}
function RecProgress {
    $done = 0.0; $total = 0.0
    foreach ($r in $Recs) {
        $total += $r.frames
        if (Done "rec_$($r.n)") { $done += $r.frames; continue }
        $wav = Join-Path $RecDir "$($r.n)\$($r.n).wav"
        if ($running.ContainsKey($r.n) -and (Test-Path $wav)) { $done += [Math]::Min($r.frames, (Get-Item $wav).Length / (($r.rate / 60) * 4)) }
    }
    [int](100 * $done / $total)
}
if ($queue.Count -gt 0) { Say "MAME is recording the game's music and effects in the background ($($queue.Count) recordings; the longest part of the build)" }
PumpRecs

try {
    # ------------------------------------------------------------ 4. program + pictures (while MAME records)
    if (-not (Done "translate")) {
        Say "translating the game program for the Dreamcast ..."
        Copy-Item (Join-Path $Kit "port\mame\cpu\v60") (Join-Path $Work "reference\mame-source\cpu") -Recurse -Force
        Copy-Item (Join-Path $Kit "port\src\v60_core.cpp"), (Join-Path $Kit "port\src\v60_core.h"), (Join-Path $Kit "port\src\emu_shim.h"),
            (Join-Path $Kit "port\src\rc_runtime.inc"), (Join-Path $Kit "port\src\dc_options.h") $H -Force
        Tool "translate" @("translate", (Join-Path $Kit "data\coverage.succ"), $RomDir) $Work
        Mark "translate"
    }
    PumpRecs
    if (-not (Done "pictures")) {
        Say "drawing the menu backdrop, the title card and the save icon from the game ..."
        Set-Content -Path "$Work\kit_script.txt" -Value "vdump 1550`nshot 1800" -Encoding ascii
        Run "script_run" (Join-Path $Kit "bin\script_run.exe") @("kit_script.txt", "1800", ($RomDir -replace '\\', '/')) $Work
        Tool "menu_snap" @("menu-snap", "recomp\traces\script\vid01550.bin", "recomp\harness\menu_snap.z") $Work
        Tool "vmu_icon" @("vmu-icon", "recomp\traces\script\f01800.png", "20", "0", "200", "recomp\dc\vmu_icon.inc") $Work
        $env:KEEP = "1fe"; $env:FULLSHOT = "2190"; $env:GA2_ROMS = ($RomDir -replace '\\', '/')
        Run "pvr_check" (Join-Path $Kit "bin\pvr_check.exe") @("2190", "5000") $Work
        Remove-Item Env:KEEP, Env:FULLSHOT, Env:GA2_ROMS
        Tool "title" @("title", "recomp\traces\pvr_check\full02190.png", (Join-Path $Kit "data\title_words.npz"), "recomp\dc\logo") $Work
        Copy-Item (Join-Path $Kit "data\gg_?.z") "$Dc\logo" -Force
        Mark "pictures"
    }
    PumpRecs
    if (-not (Done "packs")) {
        Say "packing the graphics ..."
        Tool "packs_orig" @("packs", "orig", ($RomDir -replace '\\', '/'), "recomp/dc") $Work
        Tool "press_start" @("press-start", "recomp/dc/press_start.bin") $Work
        Tool "packs_dc" @("packs", "dc", "recomp/dc") $Work
        Mark "packs"
    }
    PumpRecs
    $TC = Join-Path $Kit "toolchain"
    $Bin = Join-Path $TC "sh-elf\bin"
    $K = Join-Path $TC "kos"
    $CF = @("-O2", "-fomit-frame-pointer", "-ml", "-m4-single-only", "-ffunction-sections", "-fdata-sections", "-D_arch_dreamcast", "-D_arch_sub_pristine",
        "-I$K\include", "-I$K\kernel\arch\dreamcast\include", "-I$K\addons\include", "-I$TC\kos-ports\include", "-I$TC\kos-ports\include\zlib", "-I../harness")
    $CXF = $CF + @("-std=gnu++17", "-fno-rtti", "-fno-exceptions", "-w")
    if (-not (Done "compile")) {
        Say "compiling the translated program (a few minutes) ..."
        Copy-Item (Join-Path $Kit "port\obj\*.o") "$Dc\obj" -Force
        Copy-Item (Join-Path $Kit "port\src\vmu_save.cpp"), (Join-Path $Kit "port\src\vmu_save.h"), (Join-Path $Kit "port\src\dclog.h") $Dc -Force
        Run "cc_vmu_save" "$Bin\sh-elf-g++.exe" ($CXF + @("-c", "-o", "obj/vmu_save.o", "vmu_save.cpp")) $Dc
        Run "cc_v60_core" "$Bin\sh-elf-g++.exe" ($CXF + @("-c", "-o", "obj/v60_core.o", "../harness/v60_core.cpp")) $Dc
        Mark "compile"
    }
    PumpRecs
    if (-not (Done "link")) {
        Say "building the program file ..."
        foreach ($f in "epr-14961b.ic17", "epr-14958b.ic8", "epr-15148b.ic18", "epr-15147b.ic9") { Copy-Item (Join-Path $RomDir $f) "$Dc\romdisk" -Force }
        Copy-Item "$H\eeprom_4p.bin" "$Dc\romdisk\eeprom_base.bin" -Force
        Copy-Item "$H\v25_dpram.bin", "$H\menu_snap.z" "$Dc\romdisk" -Force
        Copy-Item "$Dc\logo\gg_?.z", "$Dc\logo\logo_?.z" "$Dc\romdisk" -Force
        Run "genromfs" "$TC\utils\genromfs.exe" @("-f", "romdisk.img", "-d", "romdisk", "-V", "garoda", "-v") $Dc
        Run "bin2c" "$TC\utils\bin2c.exe" @("romdisk.img", "romdisk_tmp.c", "romdisk") $Dc
        Run "cc_romdisk" "$Bin\sh-elf-gcc.exe" ($CF + @("-c", "-o", "romdisk_tmp.o", "romdisk_tmp.c")) $Dc
        Run "ld_romdisk" "$Bin\sh-elf-gcc.exe" @("-ml", "-m4-single-only", "-o", "romdisk.o", "-r", "romdisk_tmp.o", "-L$K\lib\dreamcast", "-Wl,--whole-archive", "-lromdiskbase") $Dc
        $objs = "audio_dc", "dlist", "dlist_sprites", "extras", "kos_snd_stream", "machine", "main_dc", "options_menu", "prof", "pvr_backend", "pvr_plan", "v60_core", "video", "vmu_save" | ForEach-Object { "obj/$_.o" }
        Run "link" "$Bin\sh-elf-g++.exe" ($CF + @("-T$TC\utils\shlelf.xc", "-nostdlib", "-L$K\lib\dreamcast", "-L$K\addons\lib\dreamcast", "-L$TC\kos-ports\lib",
            "-o", "garoda.elf") + $objs + @("romdisk.o", "-lz", "-Wl,--start-group", "-lstdc++", "-lkallisti", "-lm", "-lc", "-lgcc", "-Wl,--end-group")) $Dc
        Run "objcopy" "$Bin\sh-elf-objcopy.exe" @("-R", ".stack", "-O", "binary", "garoda.elf", "garoda.bin") $Dc
        Remove-Item "$Dc\romdisk_tmp.c" -ErrorAction SilentlyContinue
        Mark "link"
    }

    # ------------------------------------------------------------ 5. wait for the recordings
    $last = -1
    while ($running.Count -gt 0 -or $queue.Count -gt 0) {
        PumpRecs
        $p = RecProgress
        if ($p -ge $last + 10) { Say "recording the sound: $p %"; $last = $p }
        Start-Sleep -Seconds 5
    }
} finally {
    foreach ($e in $running.Values) { if (-not $e.p.HasExited) { try { $e.p.Kill() } catch {} } }
}

# ---------------------------------------------------------------- 6. sound for the disc
$Cd = "$Dc\cd_data"
if (-not (Done "sound")) {
    Say "cutting the music and the effects ..."
    $ad = Join-Path $RecDir "all"
    New-Item -ItemType Directory -Force $ad | Out-Null
    foreach ($r in $Recs) {
        foreach ($f in "$($r.n).wav", "$($r.n).sched.txt") { $s = Join-Path $RecDir "$($r.n)\$f"; if (Test-Path $s) { Move-Item $s $ad -Force } }
    }
    Tool "music" @("music", (Join-Path $Kit "data\music_cuts.json"), $ad, $Cd) $Work
    Tool "lfx" @("lfx", $Cd) $Work
    Tool "sfx" @("sfx", "$ad\survey.wav", "$ad\survey.sched.txt", (Join-Path $Kit "data\survey_classes.txt"), "$Cd\SFX.PAK") $Work
    Copy-Item (Join-Path $Kit "data\FADE.TBL") $Cd -Force
    Mark "sound"
}

# ---------------------------------------------------------------- 7. the disc image
Say "making the disc image ..."
$Root = "$Dc\cd_root"
if (Test-Path $Root) { Remove-Item -Recurse -Force $Root }
New-Item -ItemType Directory -Force $Root | Out-Null
$TC = Join-Path $Kit "toolchain"
Run "scramble" "$TC\utils\scramble.exe" @("garoda.bin", "cd_root/1ST_READ.BIN") $Dc
Copy-Item "$Cd\*" $Root -Force
# the boot sector (IP.BIN): made once with KallistiOS's makeip (its replacement bootstrap) for this title; it is the same on every disc
Copy-Item (Join-Path $Kit "data\IP.BIN") "$Dc\IP.BIN" -Force
Run "mkisofs" "$TC\utils\mkisofs.exe" @("-C", "0,11702", "-V", "GARODA", "-G", "IP.BIN", "-r", "-J", "-l", "-quiet", "-o", "garoda.iso", "cd_root") $Dc
if (Test-Path $Out) { Remove-Item $Out -Force }
Run "cdi4dc" "$TC\utils\cdi4dc.exe" @("garoda.iso", $Out) $Dc
Remove-Item "$Dc\garoda.iso" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------- 8. the same disc as the tested one?
$same = $true
$logf = Join-Path $Work "logs\check.log"
$old = $ErrorActionPreference; $ErrorActionPreference = "Continue"
if ($GaDev) { & python (Join-Path $Kit "tools-src\gatool.py") check (Join-Path $Kit "data\disc_manifest.json") $Root *> $logf } else { & $GaExe check (Join-Path $Kit "data\disc_manifest.json") $Root *> $logf }
if ($LASTEXITCODE -ne 0) { $same = $false }
$ErrorActionPreference = $old
Write-Host ""
Get-Content $logf | ForEach-Object { Write-Host "  $_" }
Write-Host ""
if ($same) { Write-Host "Your disc is identical, file for file, to the reference disc of this release." -ForegroundColor Green }
else { Write-Host "Some files differ from the reference disc (list above). The image was still made; it may well work, but it is not the reference one." -ForegroundColor Yellow }
Write-Host ""
Write-Host ("Disc image: {0}  ({1:N0} MB)" -f $Out, ((Get-Item $Out).Length / 1MB))
Write-Host ("Built in {0:N0} minutes. Burn it to a CD-R (see README) or load it in an emulator." -f ((Get-Date) - $T0).TotalMinutes)
Write-Host "The 'work' folder can be deleted now."
