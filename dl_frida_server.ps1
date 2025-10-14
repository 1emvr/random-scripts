
# ---- BEGIN: automated frida-server download + push ----
# Adjust this path if your SDK is elsewhere
$adb = "C:\Users\lemur\AppData\Local\Android\Sdk\platform-tools\adb.exe"

# ensure venv active or frida on PATH
Write-Host "[*] frida client version (host):"
frida --version

# find emulator serial (pick first emulator device)
$devList = & $adb devices | Select-String -Pattern "emulator" -SimpleMatch
if (-not $devList) {
    Write-Error "No emulator found by adb. Start your AVD and re-run."
    exit 1
}
$serial = ($devList -split "`n")[0] -split "`t" | Select-Object -First 1
Write-Host "[*] Using emulator serial: $serial"

# determine ABI
$abi = (& $adb -s $serial shell getprop ro.product.cpu.abilist) -join ""
if ([string]::IsNullOrWhiteSpace($abi)) { $abi = (& $adb -s $serial shell getprop ro.product.cpu.abi) -join "" }
$abi = $abi.Trim()
Write-Host "[*] Device ABI reported: $abi"

# map ABI to frida-server arch token
if ($abi -match "x86_64") { $arch = "android-x86_64" }
elseif ($abi -match "x86") { $arch = "android-x86" }
elseif ($abi -match "arm64|aarch64|arm64-v8a") { $arch = "android-arm64" }
else { $arch = "android-arm" }
Write-Host "[*] Will download frida-server for: $arch"

# get frida client version
$ver = frida --version
if (-not $ver) {
    Write-Error "frida client not found. Activate your venv or install frida in it first."
    exit 1
}
Write-Host "[*] frida client version: $ver"

# build filename & URL
$fname = "frida-server-$ver-$arch.xz"
$url = "https://github.com/frida/frida/releases/download/$ver/$fname"
Write-Host "[*] Download URL: $url"

# download file (overwrite if exists)
try {
    Invoke-WebRequest -Uri $url -OutFile $fname -UseBasicParsing -ErrorAction Stop
    Write-Host "[*] Downloaded $fname"
} catch {
    Write-Error "Failed to download $url. If the release name doesn't exist, manually download the matching frida-server from GitHub releases and place it here."
    exit 1
}

# try to extract using 7-zip if present, otherwise try WSL tar
$extracted = $null
$sevenZip = "C:\Program Files\7-Zip\7z.exe"
if (Test-Path $sevenZip) {
    Write-Host "[*] Extracting with 7-Zip..."
    & $sevenZip x $fname -y
    # expected output filename without .xz suffix
    $candidate = "frida-server-$ver-$arch"
    if (Test-Path $candidate) { $extracted = $candidate }
} else {
    # fallback to WSL tar - requires WSL installed
    Write-Host "[*] 7-Zip not found, trying WSL tar..."
    try {
        wsl tar -xJf $fname
        $candidate = "frida-server-$ver-$arch"
        if (Test-Path $candidate) { $extracted = $candidate }
    } catch {
        Write-Error "Could not extract ${fname}: neither 7-Zip nor WSL tar worked. Install 7-Zip or extract the .xz manually."
        exit 1
    }
}

if (-not $extracted) {
    Write-Error "Extraction completed but expected binary not found. Look for a file named frida-server-<version>-<arch> in this folder."
    exit 1
}

# normalize filename to frida-server.exe-less (we push the binary as-is)
$localServer = $extracted
# ensure it's executable on device; Windows doesn't need chmod here
Write-Host "[*] Found frida-server binary: $localServer"

# push to device and run
Write-Host "[*] Pushing to device and starting frida-server..."
& $adb -s $serial push $localServer /data/local/tmp/frida-server
& $adb -s $serial shell "chmod 755 /data/local/tmp/frida-server; /data/local/tmp/frida-server &" 

Start-Sleep -Seconds 1

# verify frida-server is running
Write-Host "[*] Verifying frida-server process on device..."
& $adb -s $serial shell "ps | grep frida || ps -A | grep frida"

# verify frida client can see processes
Write-Host "[*] Listing processes via frida-ps -U (host)"
frida-ps -U
# ---- END
