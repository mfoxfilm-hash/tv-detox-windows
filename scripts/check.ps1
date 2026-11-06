# Read-only: confirms the TV started, shows what's off, the changed settings and free memory.
. "$PSScriptRoot\lib.ps1"
$tv = Require-TV
$out = @()
$out += "Checked $(Get-Date) on $tv"
$out += "Started up: " + ((Sh $tv "getprop sys.boot_completed") -eq "1")
$out += "Uptime: " + (Sh $tv "uptime")
$out += "On screen: " + (Sh $tv "dumpsys activity activities 2>/dev/null | grep -m1 -E 'topResumedActivity|mResumedActivity'")
$off = Join-Path $Root "undo\apps-turned-off.txt"
foreach ($p in (Read-List $off)) { $out += "  off? $p : $(Is-Off $tv $p)" }
$sv = Join-Path $Root "undo\settings-old-values.txt"
foreach ($l in (Read-List $sv)) { $ns, $k, $old = $l -split '\s+', 3; $out += "  $ns $k = $(Sh $tv "settings get $ns $k") (was $old)" }
$mem = Sh $tv "cat /proc/meminfo"
$out += ($mem -split "`n" | Where-Object { $_ -match "^(MemTotal|MemAvailable|SwapTotal|SwapFree)" })
$before = Join-Path $Root "snapshot-before\meminfo.txt"
if (Test-Path $before) { $out += "Before:"; $out += (Get-Content $before | Where-Object { $_ -match "^(MemAvailable|SwapFree)" }) }
$out | ForEach-Object { Write-Host $_ }
$out | Out-File (Join-Path $LogDir "check.log") -Append -Encoding utf8
Write-Host ""
Write-Host "Tip: memory right after a restart is not a fair comparison. Check again after the TV has been on for an hour."
Pause-Exit "Remember to turn off Wireless debugging and USB debugging (or Developer options) when you're finished."
