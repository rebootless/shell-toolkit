#!/bin/bash

set -euo pipefail

echo "[*] Stopping browsers (if running)..."
pkill firefox || true
pkill chrome || true
pkill chromium || true
pkill brave || true
pkill msedge || true
pkill opera || true
pkill vivaldi || true

echo "[*] Starting cleanup..."

echo
echo "[Firefox] Cleaning..."

FIREFOX_DIR="$HOME/.mozilla/firefox"

if [[ -d "$FIREFOX_DIR" ]]; then
    find "$FIREFOX_DIR" -type f \( \
        -name "places.sqlite" \
        -o -name "cookies.sqlite" \
        -o -name "favicons.sqlite" \
    \) -delete

    rm -rf "$HOME/.cache/mozilla/firefox"/*
fi

echo
echo "[Google Chrome] Cleaning..."

CHROME_DIR="$HOME/.config/google-chrome"

if [[ -d "$CHROME_DIR" ]]; then
    find "$CHROME_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links" \
        -o -name "History-journal" \
        -o -name "History-wal" \
    \) -delete

    rm -rf "$HOME/.cache/google-chrome"/*
fi

echo
echo "[Chromium] Cleaning..."

CHROMIUM_DIR="$HOME/.config/chromium"

if [[ -d "$CHROMIUM_DIR" ]]; then
    find "$CHROMIUM_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links" \
    \) -delete

    rm -rf "$HOME/.cache/chromium"/*
fi

echo
echo "[Brave] Cleaning..."

BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser"

if [[ -d "$BRAVE_DIR" ]]; then
    find "$BRAVE_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links" \
        -o -name "History-journal" \
        -o -name "History-wal" \
    \) -delete

    rm -rf "$HOME/.cache/BraveSoftware/Brave-Browser"/*
fi

echo
echo "[Edge] Cleaning..."

EDGE_DIR="$HOME/.config/microsoft-edge"

if [[ -d "$EDGE_DIR" ]]; then
    find "$EDGE_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links" \
    \) -delete

    rm -rf "$HOME/.cache/microsoft-edge"/*
fi

echo
echo "[Opera] Cleaning..."

OPERA_DIR="$HOME/.config/opera"

if [[ -d "$OPERA_DIR" ]]; then
    find "$OPERA_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Visited Links" \
    \) -delete

    rm -rf "$HOME/.cache/opera"/*
fi

echo
echo "[Vivaldi] Cleaning..."

VIVALDI_DIR="$HOME/.config/vivaldi"

if [[ -d "$VIVALDI_DIR" ]]; then
    find "$VIVALDI_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links" \
    \) -delete

    rm -rf "$HOME/.cache/vivaldi"/*
fi

echo "[+] Done. Browser cleanup completed."
