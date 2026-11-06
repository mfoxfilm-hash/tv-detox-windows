# TV Detox for Windows

Clean up a slow Android TV or Google TV from a Windows PC: **no Git Bash, no WSL**. Just double-click.

This is an unofficial Windows companion to **[Ansub/tv-detox](https://github.com/Ansub/tv-detox)**. That project's
`install.sh` and `undo.sh` are shell scripts; these are plain `.bat` + PowerShell scripts that do the same safe
subset on Windows. The home screen itself is tv-detox's, downloaded from its official releases.

> **Read this first.** This turns off system apps on your TV. That carries some risk: some people who did this
> ended up with a TV that sat at the logo or kept restarting. Apps are only *turned off*, never deleted, and
> `undo.bat` turns everything back on, but it needs the TV on your network with debugging on.
> If you're not sure what an app does, leave it on.

## What it does

| Script | What happens | Changes the TV? |
|---|---|---|
| `1-setup-adb.bat` | Downloads Google's Platform Tools (adb) into this folder | No |
| `2-connect-and-scan.bat` | Pairs over Wireless debugging, saves a snapshot: model, app lists, memory, settings | No |
| `3-turn-off-apps.bat` | Turns off the apps in `apps-to-turn-off.txt`, one at a time, checking each | Yes |
| `4-install-home.bat` | Installs the [tv-detox](https://github.com/Ansub/tv-detox) home screen with the apps in `apps-on-home.txt` | Yes |
| `5-settings-and-restart.bat` | Applies `settings.txt` (animations off, sleep, screensaver), restarts once, checks it comes back | Yes |
| `check.bat` | Shows what's off, the settings, and free memory before/after | No |
| `undo.bat` | Turns the apps back on, restores old settings, removes the home screen | Yes (puts it back) |

Every change is written to the `undo` folder **as it happens**, so `undo.bat` always matches what was really changed.
Each script that changes something lists the changes and asks you to type `yes` first.

## Safety rules built in

- Apps are turned off with `pm disable-user`, never uninstalled.
- Never turned off, even if you list them: Google Play services, Play Store, Settings, System UI, setup apps,
  keyboards, Bluetooth, remote services, HDMI/TV input and tuner apps, and the TV's own home screen
  (including Google TV's `com.google.android.apps.tv.launcherx`).
- On Google TV, the Home button keeps opening Google TV's home screen. TV Detox is installed as an app you open
  from the Apps row. Turning Google TV's home off is what has left some TVs stuck restarting, so these scripts won't.

## Steps

1. **On the TV:** Settings → System/Device Preferences → About → press **Build** 7 times. Then in **Developer options**
   turn on **USB debugging** and **Wireless debugging**. The PC and TV must be on the **same network**
   (a guest Wi-Fi or a different router won't work).
2. Run `1-setup-adb.bat`, then `2-connect-and-scan.bat` (it walks you through the pairing code).
3. Edit `apps-to-turn-off.txt`, `apps-on-home.txt` and `settings.txt`, then run 3, 4 and 5.
4. Run `check.bat`.
5. **Turn Wireless debugging and USB debugging off again** (or Developer options). Left on, other devices on your
   network can ask to control the TV. Turn them back on only for `undo.bat` or updates.

## Tested on

- Anker Nebula Capsule 3 Laser (D2426), Google TV, Android 14, Windows 11. One device; yours may differ.

## Notes

- After the restart the screen may stay dark: the TV is often just in standby. Press Power on the remote.
- Wireless debugging often switches itself off after a restart, and its port changes. The scripts find the new
  port automatically once you turn it back on.
- Free memory right after a restart isn't a fair comparison. Check again after an hour.

## Credits and license

Home screen, approach and the list of safe defaults: [Ansub/tv-detox](https://github.com/Ansub/tv-detox) (MIT).
These Windows scripts: MIT, see [LICENSE](LICENSE). Not affiliated with Anker, Google, or the tv-detox project.
