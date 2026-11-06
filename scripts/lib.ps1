# Shared helpers. Dot-sourced by the other scripts.
$ErrorActionPreference = "Continue"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root
$Adb = Join-Path $Root "platform-tools\adb.exe"
$LogDir = Join-Path $Root "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Log($file, $text) { $text | Out-File (Join-Path $LogDir $file) -Append -Encoding utf8 }

function Pause-Exit($msg) { Write-Host ""; Write-Host $msg; Read-Host "Press Enter to close" | Out-Null; exit }

if (-not (Test-Path $Adb)) { Pause-Exit "ADB isn't set up yet. Run 1-setup-adb.bat first." }

function Get-SavedAddress {
  $f = Join-Path $Root "tv-address.txt"
  if (Test-Path $f) { return (Get-Content $f -Raw).Trim() } else { return $null }
}
function Save-Address($a) { $a | Out-File (Join-Path $Root "tv-address.txt") -Encoding ascii }

function Get-Mdns {
  $out = @{ connect = @(); pairing = @(); legacy = @() }
  foreach ($line in (Adb mdns services)) {
    if ($line -match '_adb-tls-connect\._tcp\.?\s+(\S+:\d+)') { $out.connect += $Matches[1] }
    elseif ($line -match '_adb-tls-pairing\._tcp\.?\s+(\S+:\d+)') { $out.pairing += $Matches[1] }
    elseif ($line -match '_adb\._tcp\.?\s+(\S+:\d+)') { $out.legacy += $Matches[1] }
  }
  return $out
}

function Test-Device($a) {
  if (-not $a) { return $false }
  Adb connect $a | Out-Null
  return (((Adb -s $a get-state) | Out-String).Trim() -eq "device")
}

# Finds the TV: saved address, then the TV's current Wireless debugging port (it changes),
# then the old port 5555. Returns the address, or $null.
function Find-TV {
  $saved = Get-SavedAddress
  $ip = if ($saved) { $saved.Split(":")[0] } else { $null }
  if (Test-Device $saved) { return $saved }
  for ($i = 0; $i -lt 5; $i++) {
    $m = Get-Mdns
    $cands = @($m.connect) + @($m.legacy)
    if ($ip) { $cands = @($cands | Where-Object { $_.StartsWith("$ip`:") }) + @($cands | Where-Object { -not $_.StartsWith("$ip`:") }) }
    foreach ($c in $cands) { if (Test-Device $c) { Save-Address $c; return $c } }
    Start-Sleep 2
  }
  if ($ip -and (Test-Device "$ip`:5555")) { Save-Address "$ip`:5555"; return "$ip`:5555" }
  return $null
}

function Require-TV {
  $tv = Find-TV
  if (-not $tv) { Pause-Exit "Can't reach the TV. Check it's on, on the same network as this PC, and Wireless debugging (or USB debugging) is on. Nothing was changed. If it's never been connected, run 2-connect-and-scan.bat." }
  return $tv
}

# Runs adb and returns its output as plain text. Warnings adb prints are kept as text, so
# Windows PowerShell doesn't show them as red errors.
function Adb { $ErrorActionPreference = "SilentlyContinue"; & $Adb @args 2>&1 | ForEach-Object { "$_" } }
function Sh($tv, $cmd) { return ((Adb -s $tv shell $cmd) | Out-String).Trim() }

function Is-Off($tv, $pkg) {
  $o = Adb -s $tv shell pm list packages -d $pkg
  return [bool]($o | Where-Object { $_.Trim() -eq "package:$pkg" })
}
function Is-Installed($tv, $pkg) {
  $o = Adb -s $tv shell pm list packages $pkg
  return [bool]($o | Where-Object { $_.Trim() -eq "package:$pkg" })
}

function Read-List($file) {
  if (-not (Test-Path $file)) { return @() }
  return @(Get-Content $file | ForEach-Object { ($_ -replace '#.*$','').Trim() } | Where-Object { $_ })
}

# Never turned off by these scripts, whatever the list says.
$NeverTouch = @(
  "android","com.google.android.gms","com.google.android.gsf","com.android.vending",
  "com.android.tv.settings","com.android.settings","com.android.systemui","com.android.providers.settings",
  "com.android.shell","com.android.packageinstaller","com.google.android.packageinstaller",
  "com.google.android.permissioncontroller","com.android.bluetooth","com.android.providers.tv",
  "com.google.android.inputmethod.latin","com.android.inputmethod.latin","com.google.android.leanback.ime",
  "com.google.android.apps.tv.launcherx","com.google.android.tvlauncher","com.google.android.tungsten.setupwraith",
  "com.android.provision","com.google.android.tv.remote.service","com.android.networkstack","com.android.wifi.resources"
)
# Protected: the never-touch list, plus any SYSTEM app whose name suggests setup, input,
# HDMI/tuner, keyboard, Bluetooth, remote, framework or home screen. Apps you installed
# yourself can always be turned off.
function Is-Protected($tv, $pkg) {
  if ($NeverTouch -contains $pkg) { return $true }
  $sys = Adb -s $tv shell pm list packages -s $pkg
  $isSystem = [bool]($sys | Where-Object { $_.Trim() -eq "package:$pkg" })
  if (-not $isSystem) { return $false }
  return ($pkg -match 'setup|wizard|provision|systemui|tvinput|tv\.input|tvcenter|tuner|hdmi|inputmethod|keyboard|\.ime$|bluetooth|remote|framework|launcher')
}
