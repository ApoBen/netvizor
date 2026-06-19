#!/usr/bin/env bash
# NetVizör Global Installer
# Kullanım: bash <(curl -fsSL https://raw.githubusercontent.com/ApoBen/netvizor/main/install.sh)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}     🌐 NetVizör Kurulum Sihirbazı   ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Python kontrolü
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[!] python3 bulunamadı. Lütfen yükleyin: sudo apt install python3${NC}"
    exit 1
fi

INSTALL_DIR="$HOME/.netvizor"

# İndirme: Git varsa clone/pull, yoksa ZIP ile indir
if command -v git &> /dev/null; then
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "${GREEN}[+] Mevcut kurulum güncelleniyor (git pull)...${NC}"
        git -C "$INSTALL_DIR" pull origin main
    else
        echo -e "${GREEN}[+] NetVizör indiriliyor (git clone)...${NC}"
        git clone https://github.com/ApoBen/netvizor.git "$INSTALL_DIR"
    fi
else
    echo -e "${YELLOW}[!] Git bulunamadı. ZIP arşivi ile indiriliyor...${NC}"
    if command -v curl &> /dev/null; then
        curl -fsSL https://github.com/ApoBen/netvizor/archive/refs/heads/main.zip -o /tmp/netvizor.zip
    elif command -v wget &> /dev/null; then
        wget -q https://github.com/ApoBen/netvizor/archive/refs/heads/main.zip -O /tmp/netvizor.zip
    else
        echo -e "${RED}[!] curl veya wget bulunamadı. Lütfen birini yükleyin.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] Arşiv açılıyor...${NC}"
    rm -rf /tmp/netvizor-main "$INSTALL_DIR"
    unzip -q /tmp/netvizor.zip -d /tmp/
    mv /tmp/netvizor-main "$INSTALL_DIR"
    rm -f /tmp/netvizor.zip
fi

cd "$INSTALL_DIR"

# Sanal ortam ve bağımlılıklar
echo -e "${GREEN}[+] Sanal ortam oluşturuluyor ve bağımlılıklar yükleniyor...${NC}"
python3 -m venv venv
./venv/bin/pip install --upgrade pip --quiet
./venv/bin/pip install -r requirements.txt --quiet

# 'netvizor' komutunu kur
echo -e "${GREEN}[+] 'netvizor' komutu kurulumu yapılıyor...${NC}"

WRAPPER_CONTENT="#!/usr/bin/env bash
# NetVizör Başlatıcı
cd \"$INSTALL_DIR\"
exec ./run.sh \"\$@\"
"

# Önce kullanıcı dizinine koy (sudo gerektirmez)
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
echo "$WRAPPER_CONTENT" > "$LOCAL_BIN/netvizor"
chmod +x "$LOCAL_BIN/netvizor"

# /usr/local/bin'e de koy (sudo varsa)
if sudo -n true 2>/dev/null; then
    echo "$WRAPPER_CONTENT" | sudo tee /usr/local/bin/netvizor > /dev/null
    sudo chmod +x /usr/local/bin/netvizor
    echo -e "${GREEN}[+] /usr/local/bin/netvizor kuruldu (sistem geneli).${NC}"
else
    echo -e "${YELLOW}[!] Sistem geneli kurulum için sudo gerekli, atlanıyor.${NC}"
    echo -e "${GREEN}[+] $LOCAL_BIN/netvizor kuruldu (sadece bu kullanıcı).${NC}"
fi

# PATH kontrolü ve .bashrc/.zshrc güncelleme
add_to_path() {
    local SHELL_RC="$1"
    if [ -f "$SHELL_RC" ] && ! grep -q 'HOME/.local/bin' "$SHELL_RC"; then
        echo '' >> "$SHELL_RC"
        echo '# NetVizör - kullanıcı bin dizini' >> "$SHELL_RC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo -e "${GREEN}[+] PATH güncellendi: $SHELL_RC${NC}"
    fi
}

add_to_path "$HOME/.bashrc"
add_to_path "$HOME/.zshrc"

# Mevcut shell'e de uygula
export PATH="$HOME/.local/bin:$PATH"

echo ""
echo -e "${GREEN}✅ Kurulum tamamlandı!${NC}"
echo ""
echo -e "  Terminale ${BLUE}netvizor${NC} yazarak uygulamayı başlatabilirsiniz."
echo -e "  Değişikliklerin geçerli olması için terminali yeniden başlatın veya:"
echo -e "    ${YELLOW}source ~/.bashrc${NC}  (bash kullanıyorsanız)"
echo -e "    ${YELLOW}source ~/.zshrc${NC}   (zsh kullanıyorsanız)"
echo ""
