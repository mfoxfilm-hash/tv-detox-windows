# Puts everything back: turns the apps back on, restores the old settings, removes what was installed.
. "$PSScriptRoot\lib.ps1"
$tv = Require-TV
$log = "undo.log"
Log $log "=== $(Get-Date) on $tv ==="
$u = Join-Path $Root "undo"
foreach ($p in (Read-List "$u\apps-turned-off.txt")) {
  Write-Host "Turning on $p"; Log $log "enable $p : $(Sh $tv "pm enable $p")"
  if ($p -eq "com.google.android.apps.tv.launcherx") { Sh $tv "cmd notification allow_listener com.google.android.apps.tv.launcherx/.coreservices.notificationlistener.TvNotificationListenerService" | Out-Null }
}
foreach ($l in (Read-List "$u\settings-old-values.txt")) {
  $ns, $k, $old = $l -split '\s+', 3
  if ($old -eq "null" -or -not $old) { Write-Host "Clearing $ns $k"; Log $log (Sh $tv "settings delete $ns $k") }
  else { Write-Host "Restoring $ns $k = $old"; Log $log (Sh $tv "settings put $ns $k $old") }
}
if (Test-Path "$u\home-role.txt") {
  foreach ($l in (Read-List "$u\home-role.txt")) { $role, $holder = $l -split '\s+', 2; Log $log (Sh $tv "cmd role add-role-holder --user 0 $role $holder") }
}
foreach ($p in (Read-List "$u\apps-installed.txt")) { Write-Host "Removing $p"; Log $log "uninstall $p : $(Adb -s $tv uninstall $p)" }
Sh $tv "input keyevent KEYCODE_HOME" | Out-Null
Write-Host ""
Write-Host "Undo finished. The lists in the undo folder are kept; delete them yourself once you've checked the TV."
Pause-Exit "Remember to turn debugging back off."
