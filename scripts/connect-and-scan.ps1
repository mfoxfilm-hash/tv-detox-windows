# Pairs with the TV (first time only), then saves a read-only snapshot: model, app lists,
# memory and current settings. Changes nothing on the TV.
. "$PSScriptRoot\lib.ps1"
$log = "connect.log"
Log $log "=== $(Get-Date) ==="
Adb start-server | Out-Null

$tv = Find-TV
if (-not $tv) {
  Write-Host ""
  Write-Host "Pairing (first time only)."
  Write-Host "On the TV: Settings > System (or Device Preferences) > Developer options > Wireless debugging > 'Pair device with pairing code'."
  Read-Host "Leave that box open on the TV and press Enter here" | Out-Null
  $pair = $null
  for ($i = 0; $i -lt 10 -and -not $pair; $i++) { $m = Get-Mdns; if ($m.pairing.Count) { $pair = $m.pairing[0] } else { Start-Sleep 2 } }
  if (-not $pair) { $pair = Read-Host "Couldn't find it automatically. Type the IP address:port shown in the pairing box" }
  $code = Read-Host "Type the 6-digit code shown on the TV"
  $r = Adb pair $pair $code | Out-String
  Log $log "pair $pair : $r"
  Write-Host $r
  if ($r -notmatch "Successfully paired") { Pause-Exit "Pairing didn't work. Check the PC and TV are on the same network, then try again with a fresh code." }
  Save-Address ($pair.Split(":")[0] + ":0")
  Start-Sleep 2
  $tv = Find-TV
  if (-not $tv) {
    $p = Read-Host "Type the PORT shown under 'IP address & Port' on the main Wireless debugging screen"
    $tv = $pair.Split(":")[0] + ":" + $p
    if (-not (Test-Device $tv)) { Pause-Exit "Paired, but couldn't connect to $tv." }
    Save-Address $tv
  }
}
Write-Host "Connected to $tv"
Log $log "connected $tv"

$snap = Join-Path $Root "snapshot-before"
New-Item -ItemType Directory -Force -Path $snap | Out-Null
if (Test-Path (Join-Path $snap "meminfo.txt")) {
  $snap = Join-Path $Root ("snapshot-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
  New-Item -ItemType Directory -Force -Path $snap | Out-Null
}
Write-Host "Reading the TV (read-only)..."
function Save($cmd, $name) { Adb -s $tv shell $cmd | Out-File (Join-Path $snap $name) -Encoding utf8 }
Save "getprop ro.product.manufacturer; getprop ro.product.model; getprop ro.product.name; getprop ro.build.version.release" "model.txt"
Save "pm list packages -s" "apps-system.txt"
Save "pm list packages -3" "apps-installed-by-you.txt"
Save "pm list packages -d" "apps-already-off.txt"
Save "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME" "home-screen.txt"
Save "cat /proc/meminfo" "meminfo.txt"
Save "settings list global" "settings-global.txt"
Save "settings list secure" "settings-secure.txt"
Save "settings list system" "settings-system.txt"

$model = (Get-Content (Join-Path $snap "model.txt")) -join " "
$avail = (Get-Content (Join-Path $snap "meminfo.txt") | Where-Object { $_ -match "^MemAvailable" }) -replace '\s+',' '
$gtv = Is-Installed $tv "com.google.android.apps.tv.launcherx"
Write-Host ""
Write-Host "TV:     $model"
Write-Host "Memory: $avail"
if ($gtv) { Write-Host "This is a Google TV. Its home screen (launcherx) is never turned off by these scripts." }
Write-Host "Snapshot saved in $snap"
Pause-Exit "Next: write the apps you want turned off into apps-to-turn-off.txt, then run 3-turn-off-apps.bat"
