# Applies settings.txt (namespace key value per line), saving each OLD value first,
# waits 30 seconds, restarts the TV once, and checks it comes back.
. "$PSScriptRoot\lib.ps1"
$tv = Require-TV
$ip = $tv.Split(":")[0]
$log = "settings.log"
Log $log "=== $(Get-Date) on $tv ==="
$lines = Read-List (Join-Path $Root "settings.txt")
if (-not $lines.Count) { Pause-Exit "settings.txt is empty." }
Write-Host "These settings will change:"
foreach ($l in $lines) {
  $ns, $k, $v = $l -split '\s+', 3
  Write-Host ("  {0} {1}: {2} -> {3}" -f $ns, $k, (Sh $tv "settings get $ns $k"), $v)
}
if ((Read-Host "Type yes to apply them and restart the TV") -ne "yes") { Pause-Exit "Nothing changed." }
New-Item -ItemType Directory -Force -Path (Join-Path $Root "undo") | Out-Null
$undo = Join-Path $Root "undo\settings-old-values.txt"
foreach ($l in $lines) {
  $ns, $k, $v = $l -split '\s+', 3
  $old = Sh $tv "settings get $ns $k"
  "$ns $k $old" | Out-File $undo -Append -Encoding ascii
  Sh $tv "settings put $ns $k $v" | Out-Null
  $now = Sh $tv "settings get $ns $k"
  Log $log "$ns $k : $old -> $now (wanted $v)"
  Write-Host "$k = $now"
}
Write-Host "Waiting 30 seconds so the TV saves everything..."
Start-Sleep 30
Log $log "reboot $(Get-Date)"
Adb -s $tv reboot | Out-Null
Write-Host "Restarting the TV. This takes 1-3 minutes."
Write-Host "If the screen stays dark, press Power on the remote. Wireless debugging may switch itself off after a restart; if so, turn it back on."
Start-Sleep 45
$new = $null
for ($i = 0; $i -lt 40 -and -not $new; $i++) { $new = Find-TV; if (-not $new) { Start-Sleep 5 } }
if (-not $new) { Pause-Exit "The TV hasn't come back on the network yet. When it's on the home screen and Wireless debugging is on, run check.bat. If it's stuck at the logo, run undo.bat once you can connect." }
for ($i = 0; $i -lt 30; $i++) { if ((Sh $new "getprop sys.boot_completed") -eq "1") { break }; Start-Sleep 4 }
Log $log "back: $new boot_completed=$(Sh $new 'getprop sys.boot_completed')"
Pause-Exit "The TV restarted and finished starting up. Run check.bat for the after-snapshot."
