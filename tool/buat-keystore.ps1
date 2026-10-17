# Membuat kunci upload Android (sekali saja) — Windows PowerShell.
# keytool ikut terpasang bersama Android Studio / Java.
# Jalankan:  powershell -ExecutionPolicy Bypass -File tool\buat-keystore.ps1
$keytool = "keytool"
$jbr = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
if (-not (Get-Command keytool -ErrorAction SilentlyContinue) -and (Test-Path $jbr)) { $keytool = $jbr }

$out = "$HOME\langgananku-upload-keystore.jks"
& $keytool -genkeypair -v -keystore $out -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
if (-not (Test-Path $out)) { Write-Host "Gagal membuat keystore."; exit 1 }

$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($out))
Set-Content -Path "$HOME\langgananku-keystore-base64.txt" -Value $b64
Write-Host ""
Write-Host "SELESAI. Simpan baik-baik (cadangkan ke Google Drive/flashdisk):"
Write-Host "  Keystore : $out"
Write-Host "  Base64   : $HOME\langgananku-keystore-base64.txt  -> isi secret KEYSTORE_BASE64 di GitHub"
Write-Host "  KEY_ALIAS = upload"
