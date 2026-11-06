# Turns off (never uninstalls) each app in apps-to-turn-off.txt, one at a time.
# Each app is written to undo\apps-turned-off.txt only after the TV confirms it is off.
. "$PSScriptRoot\lib.ps1"
$tv = Require-TV
$log = "turn-off.log"
Log $log "=== $(Get-Date) on $tv ==="
$list = Read-List (Join-Path $Root "apps-to-turn-off.txt")
if (-not $list.Count) { Pause-Exit "apps-to-turn-off.txt is empty. Add one package name per line." }
New-Item -ItemType Directory -Force -Path (Join-Path $Root "undo") | Out-Null
$undo = Join-Path $Root "undo\apps-turned-off.txt"

Write-Host "These apps will be turned off (not deleted):"
$list | ForEach-Object { Write-Host "  $_" }
if ((Read-Host "Type yes to go ahead") -ne "yes") { Pause-Exit "Nothing changed." }

foreach ($p in $list) {
  if (Is-Protected $tv $p) { Write-Host "SKIP (protected, the TV may need it): $p"; Log $log "skip protected $p"; continue }
  if (-not (Is-Installed $tv $p)) { Write-Host "SKIP (not installed): $p"; Log $log "skip missing $p"; continue }
  if (Is-Off $tv $p) { Write-Host "SKIP (already off before this script): $p"; Log $log "skip already-off $p"; continue }
  Write-Host "Turning off $p ..."
  $o = Sh $tv "pm disable-user --user 0 $p"
  Log $log "$p : $o"
  Start-Sleep 1
  if (Is-Off $tv $p) { $p | Out-File $undo -Append -Encoding ascii; Log $log "ok $p" }
  else { Log $log "FAILED $p"; Pause-Exit "Couldn't turn off $p. Stopped here; everything before it is in undo\apps-turned-off.txt." }
}
Write-Host "Saving... (Android writes this a few seconds later)"
Start-Sleep 15
Pause-Exit "Done. undo.bat turns all of these back on."
