#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
EXPORT_DIR="$ROOT_DIR/signing_export"
KEYSTORE_PATH="$ANDROID_DIR/upload-keystore.jks"
EXPORT_KEYSTORE_PATH="$EXPORT_DIR/genesis-upload-keystore.jks"
BASE64_PATH="$EXPORT_DIR/CM_KEYSTORE_BASE64.txt"
KEY_PROPERTIES_PATH="$ANDROID_DIR/key.properties"

mkdir -p "$EXPORT_DIR"

read -r -p "Key alias [upload]: " KEY_ALIAS
KEY_ALIAS="${KEY_ALIAS:-upload}"

read -r -s -p "Keystore password: " STORE_PASSWORD
echo
read -r -s -p "Confirm keystore password: " STORE_PASSWORD_CONFIRM
echo
if [[ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]]; then
  echo "Passwords do not match."
  exit 1
fi

read -r -s -p "Key password (press Enter to reuse keystore password): " KEY_PASSWORD
echo
KEY_PASSWORD="${KEY_PASSWORD:-$STORE_PASSWORD}"

read -r -p "Your name (CN) [Kwabena Nketa Samuel]: " CN
CN="${CN:-Kwabena Nketa Samuel}"
read -r -p "Organization unit (OU) [Mobile]: " OU
OU="${OU:-Mobile}"
read -r -p "Organization (O) [Genesis Holdings]: " O
O="${O:-Genesis Holdings}"
read -r -p "City (L) [California]: " L
L="${L:-California}"
read -r -p "State (ST) [California]: " ST
ST="${ST:-California}"
read -r -p "Country code (C) [US]: " C
C="${C:-US}"

DNAME="CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"

rm -f "$KEYSTORE_PATH" "$EXPORT_KEYSTORE_PATH" "$BASE64_PATH"

keytool -genkeypair \
  -v \
  -storetype JKS \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "$STORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "$DNAME"

cat > "$KEY_PROPERTIES_PATH" <<EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=../upload-keystore.jks
EOF

cp "$KEYSTORE_PATH" "$EXPORT_KEYSTORE_PATH"
base64 -w 0 "$EXPORT_KEYSTORE_PATH" > "$BASE64_PATH"

echo
echo "Done. Generated files:"
echo "- $KEYSTORE_PATH"
echo "- $KEY_PROPERTIES_PATH"
echo "- $EXPORT_KEYSTORE_PATH"
echo "- $BASE64_PATH"
echo
echo "Use these Codemagic variables:"
echo "CM_KEY_ALIAS=$KEY_ALIAS"
echo "CM_KEYSTORE_PASSWORD=<your keystore password>"
echo "CM_KEY_PASSWORD=<your key password>"
echo "CM_KEYSTORE_BASE64=<contents of $BASE64_PATH>"
