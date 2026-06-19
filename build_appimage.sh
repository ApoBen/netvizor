#!/bin/bash
set -e

echo "=========================================="
echo "    NetVizör AppImage & Binary Builder    "
echo "=========================================="

# Ensure we are in the project root
cd "$(dirname "$0")"

# 1. Install PyInstaller inside the virtual environment
echo "[+] PyInstaller kuruluyor..."
./venv/bin/pip install pyinstaller

# 2. Build the standalone binary using PyInstaller
echo "[+] PyInstaller ile tekil çalıstırılabilir dosya derleniyor..."
./venv/bin/pyinstaller --clean --onefile --name netvizor \
    --add-data "frontend:frontend" \
    main_entry.py

echo "[+] Derleme tamamlandı! Dosya: dist/netvizor"

# 3. Create AppImage structure
echo "[+] AppImage yapısı (AppDir) hazırlanıyor..."
rm -rf AppDir
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps

# Copy the executable
cp dist/netvizor AppDir/usr/bin/netvizor

# Create AppRun launcher
cat << 'EOF' > AppDir/AppRun
#!/bin/sh
SELF=$(readlink -f "$0")
HERE=$(dirname "$SELF")
exec "$HERE/usr/bin/netvizor" "$@"
EOF
chmod +x AppDir/AppRun

# Copy desktop file
cp NetVizor.desktop AppDir/NetVizor.desktop
cp NetVizor.desktop AppDir/usr/share/applications/NetVizor.desktop

# AppImage requires a default icon in the AppDir root.
# We will copy a standard system monitor icon from the system if available,
# or create a basic 1x1 fallback to prevent appimagetool from failing.
ICON_FOUND=false
ICON_PATHS=(
    "/usr/share/icons/hicolor/256x256/apps/utilities-system-monitor.png"
    "/usr/share/icons/hicolor/scalable/apps/utilities-system-monitor.svg"
    "/usr/share/icons/Adwaita/256x256/apps/utilities-system-monitor.png"
    "/usr/share/icons/hicolor/48x48/apps/utilities-system-monitor.png"
)

for path in "${ICON_PATHS[@]}"; do
    if [ -f "$path" ]; then
        cp "$path" AppDir/utilities-system-monitor.png || cp "$path" AppDir/utilities-system-monitor.svg
        cp "$path" AppDir/usr/share/icons/hicolor/256x256/apps/utilities-system-monitor.png || true
        ICON_FOUND=true
        break
    fi
done

if [ "$ICON_FOUND" = false ]; then
    echo "[!] Sistem ikonu bulunamadı, bos bir ikon dosyası olusturuluyor..."
    touch AppDir/utilities-system-monitor.png
fi

# Symlink default icon name
cd AppDir
ln -sf utilities-system-monitor.png netvizor.png || ln -sf utilities-system-monitor.svg netvizor.svg
ln -sf utilities-system-monitor.png .DirIcon || ln -sf utilities-system-monitor.svg .DirIcon
cd ..

# 4. Download and run appimagetool
echo "[+] appimagetool indiriliyor..."
if [ ! -f "appimagetool" ]; then
    curl -H "Cache-Control: no-cache" -L -o appimagetool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x appimagetool
fi

echo "[+] AppImage paketi olusturuluyor..."
# Bypass FUSE dependency if running inside docker/headless containers
export APPIMAGE_EXTRACT_AND_RUN=1
./appimagetool AppDir dist/NetVizor-x86_64.AppImage

echo ""
echo "=========================================="
echo " Başarılı! 🎉"
echo " Tekil çalıştırılabilir dosya: dist/netvizor"
echo " AppImage paketi: dist/NetVizor-x86_64.AppImage"
echo "=========================================="
