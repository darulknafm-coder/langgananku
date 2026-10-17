#!/usr/bin/env bash
# Membuat kunci upload Android (sekali saja) — macOS / Linux.
set -e
OUT="$HOME/langgananku-upload-keystore.jks"
keytool -genkeypair -v -keystore "$OUT" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 < "$OUT" | tr -d '\n' > "$HOME/langgananku-keystore-base64.txt"
echo
echo "SELESAI. Simpan baik-baik:"
echo "  Keystore : $OUT"
echo "  Base64   : $HOME/langgananku-keystore-base64.txt  -> secret KEYSTORE_BASE64 di GitHub"
echo "  KEY_ALIAS = upload"
