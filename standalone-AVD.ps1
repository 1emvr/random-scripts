$SDK = "C:\Users\lemur\AppData\Local\Android\Sdk"
$adb = Join-Path $SDK "platform-tools\adb.exe"
$emulator = Join-Path $SDK "emulator\emulator.exe"

& $adb version
& $emulator -version
& $emulator -list-avds

# restart adb server from the SDK copy
taskkill /F /IM adb.exe /T 2>$null
Start-Sleep -Seconds 1
& $adb start-server
Start-Sleep -Seconds 1
& $adb devices -l

# start emulator (foreground so you can see boot messages)
$AVD = "Pixel_9_Pro"    # put the name reported by -list-avds
& $emulator -avd "$AVD" -no-snapshot-load
