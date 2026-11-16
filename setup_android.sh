#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter belum ditemukan di PATH. Pastikan flutter --version berhasil terlebih dahulu."
  exit 1
fi

if [[ ! -d android ]]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  echo "Membuat Android runner menggunakan Flutter SDK yang terpasang..."
  flutter create --platforms=android --org id.rooveylearn --project-name rooveylearn "$tmp_dir/rooveylearn"
  cp -a "$tmp_dir/rooveylearn/android" ./android
  if [[ ! -f .metadata && -f "$tmp_dir/rooveylearn/.metadata" ]]; then
    cp "$tmp_dir/rooveylearn/.metadata" ./.metadata
  fi
  if [[ ! -f .gitignore && -f "$tmp_dir/rooveylearn/.gitignore" ]]; then
    cp "$tmp_dir/rooveylearn/.gitignore" ./.gitignore
  fi
  echo "Android runner berhasil dibuat."
else
  echo "Folder android/ sudah ada; menggunakan folder yang tersedia."
fi

flutter pub get
cat <<'MSG'

Selesai.
Berikutnya:
  1. Buka folder project ini di Android Studio.
  2. Jalankan emulator atau hubungkan perangkat Android dengan USB debugging.
  3. Jalankan: flutter run

Untuk membuat APK debug:
  flutter build apk --debug
MSG
