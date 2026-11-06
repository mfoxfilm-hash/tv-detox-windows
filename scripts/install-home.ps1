# Installs the TV Detox home screen (github.com/Ansub/tv-detox) with the apps in apps-on-home.txt.
# Never turns off the TV's own home screen. On Google TV the Home button keeps opening
# Google TV's home; TV Detox is then an app you open from the Apps row.
. "$PSScriptRoot\lib.ps1"
$tv = Require-TV
$log = "home.log"
Log $log "=== $(Get-Date) on $tv ==="
$apk = Join-Path $Root "tvhome.apk"
if (-not (Test-Path $apk)) {
  Write-Host "Downloading tvhome.apk from github.com/Ansub/tv-detox (latest release)..."
  curl.exe -fsSL -o $apk https://github.com/Ansub/tv-detox/releases/latest/download/tvhome.apk
  if (-not (Test-Path $apk)) { Pause-Exit "Download failed. Nothing changed." }
}
$apps = (Read-List (Join-Path $Root "apps-on-home.txt")) -join ","
Write-Host "Installing... If the TV shows a Google Play Protect message, read it before allowing."
$o = Adb -s $tv install -r $apk | Out-String
Log $log "install: $o"
if ($o -notmatch "Success") { Pause-Exit "Install didn't succeed: $o" }
New-Item -ItemType Directory -Force -Path (Join-Path $Root "undo") | Out-Null
"com.ansub.tvhome" | Out-File (Join-Path $Root "undo\apps-installed.txt") -Append -Encoding ascii
$before = Sh $tv "cmd role get-role-holders --user 0 android.app.role.HOME"
if ($before) { "android.app.role.HOME $before" | Out-File (Join-Path $Root "undo\home-role.txt") -Encoding ascii }
$stamp = [int][double]::Parse((Get-Date -UFormat %s))
$extra = if ($apps) { "--es apps '$apps'" } else { "" }
Log $log (Sh $tv "am start -n com.ansub.tvhome/.MainActivity --es stamp $stamp $extra")
Start-Sleep 3
Log $log (Sh $tv "cmd role add-role-holder --user 0 android.app.role.HOME com.ansub.tvhome")
Log $log (Sh $tv "cmd package set-home-activity com.ansub.tvhome/.MainActivity")
Start-Sleep 2
$homeNow = Sh $tv "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"
Log $log "home now: $homeNow"
Sh $tv "input keyevent KEYCODE_HOME" | Out-Null
if ($homeNow -match "com.ansub.tvhome") { Pause-Exit "Done. Home now opens TV Detox." }
Pause-Exit "Installed. Your TV's own home screen still answers the Home button (normal on Google TV). Open TV Detox from the Apps row."
