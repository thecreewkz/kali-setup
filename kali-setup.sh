#!/usr/bin/env bash
# =============================================================================
# kali-setup.sh - Atualizacao do Kali Linux + instalacao de ferramentas
# Uso: sudo ./kali-setup.sh [OPCAO]
# =============================================================================

set -uo pipefail

# --- Cores para a saida ------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # sem cor

LOG_FILE="/var/log/kali-setup.log"

# Escolhe um local gravavel para o log (/var/log exige root)
definir_log() {
    local dir="/var/log"
    if [ ! -d "$dir" ] || [ ! -w "$dir" ]; then
        dir="${HOME:-/tmp}"
    fi
    LOG_FILE="${dir}/kali-setup.log"
    touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/dev/null"
}

# Grava no log sem nunca quebrar o script por erro de permissao
gravar_log() {
    { echo "[$(date '+%F %T')] $1" >>"$LOG_FILE"; } 2>/dev/null || true
}

# --- Catalogo de ferramentas por categoria -----------------------------------
declare -A CATEGORIAS=(
    [recon]="nmap masscan rustscan amap theharvester recon-ng whois dnsutils traceroute net-tools"
    [web]="gobuster dirb wfuzz sqlmap nikto whatweb ffuf wpscan joomscan"
    [wireless]="aircrack-ng reaver wifite hcxdumptool hostapd-dnsmasq"
    [exploit]="metasploit-framework searchsploit exploitdb"
    [sniff]="wireshark tshark tcpdump responder ettercap-graphical"
    [passwords]="hydra john hashcat seclists wordlists cewl fcrackzip"
    [forensics]="binwalk foremost testdisk scalpel steghide exiftool"
    [misc]="git curl wget vim tmux python3 pipx jq gobuster"
)

TODAS_CATEGORIAS="${!CATEGORIAS[@]}"

# --- Funcoes utilitarias -----------------------------------------------------
log() {
    echo -e "${CYAN}[*]${NC} $1"
    gravar_log "$1"
}

ok() {
    echo -e "${GREEN}[+]${NC} $1"
    gravar_log "OK: $1"
}

aviso() {
    echo -e "${YELLOW}[!]${NC} $1"
    gravar_log "AVISO: $1"
}

erro() {
    echo -e "${RED}[-]${NC} $1" >&2
    gravar_log "ERRO: $1"
}

# Executa um comando com sudo se nao for root
com_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        erro "Root ou sudo necessario para: $*"
        return 1
    fi
}

# --- Ajuda -------------------------------------------------------------------
ajuda() {
    cat <<EOF

$(basename "$0") - Atualiza o Kali Linux e instala ferramentas por categoria.

Uso: sudo ./$(basename "$0") [OPCAO]

Opcoes:
  (nenhuma)        Atualiza o sistema + instala categorias essenciais (recon, web, passwords, misc)
  --full           Atualiza o sistema + instala TODAS as categorias
  --only CATS      Instala apenas as categorias informadas (separadas por virgula)
  --upgrade        Somente atualiza o sistema, nao instala ferramentas
  --list           Mostra as categorias e ferramentas disponiveis
  -h, --help       Mostra esta ajuda

Categorias disponiveis: $TODAS_CATEGORIAS

Exemplos:
  sudo ./$(basename "$0")
  sudo ./$(basename "$0") --full
  sudo ./$(basename "$0") --only recon,sniff
  sudo ./$(basename "$0") --list

EOF
}

listar() {
    echo
    echo "Categorias e ferramentas disponiveis:"
    echo "-------------------------------------"
    for cat in $(echo "${!CATEGORIAS[@]}" | tr ' ' '\n' | sort); do
        printf "  %-12s -> %s\n" "$cat" "${CATEGORIAS[$cat]}"
    done
    echo
}

# --- Atualizacao do sistema --------------------------------------------------
atualizar_sistema() {
    log "Atualizando listas de pacotes (apt update)..."
    if ! com_sudo apt-get update -y; then
        erro "Falha no apt update."
        return 1
    fi

    log "Atualizando pacotes instalados (apt upgrade)..."
    DEBIAN_FRONTEND=noninteractive com_sudo apt-get upgrade -y

    log "Atualizacao profunda (apt dist-upgrade)..."
    DEBIAN_FRONTEND=noninteractive com_sudo apt-get dist-upgrade -y

    log "Removendo pacotes obsoletos..."
    DEBIAN_FRONTEND=noninteractive com_sudo apt-get autoremove -y
    com_sudo apt-get autoclean

    ok "Sistema atualizado."
}

# --- Instalacao de categorias ------------------------------------------------
instalar_ferramentas() {
    local categorias=("$@")
    local total=${#categorias[@]}

    if [ "$total" -eq 0 ]; then
        aviso "Nenhuma categoria selecionada."
        return 0
    fi

    local idx=0
    for cat in "${categorias[@]}"; do
        idx=$((idx + 1))

        # Verifica se a categoria existe
        if [ -z "${CATEGORIAS[$cat]+x}" ]; then
            aviso "Categoria desconhecida ignorada: '$cat'"
            continue
        fi

        log "[$idx/$total] Instalando categoria: $cat"
        local pacotes=(${CATEGORIAS[$cat]})

        if ! DEBIAN_FRONTEND=noninteractive com_sudo apt-get install -y "${pacotes[@]}"; then
            aviso "Alguns pacotes da categoria '$cat' falharam. Tentando um por um..."
            for p in "${pacotes[@]}"; do
                if DEBIAN_FRONTEND=noninteractive com_sudo apt-get install -y "$p"; then
                    ok "  $p"
                else
                    aviso "  Falhou: $p (pode nao existir neste Kali)"
                fi
            done
        else
            ok "Categoria '$cat' instalada."
        fi
    done
}

# --- Verificacoes iniciais ---------------------------------------------------
verificar_ambiente() {
    if ! command -v apt-get >/dev/null 2>&1; then
        erro "apt-get nao encontrado. Este script roda apenas em Debian/Kali Linux."
        exit 1
    fi

    if ! grep -qiE 'kali|debian|ubuntu' /etc/os-release 2>/dev/null; then
        aviso "Sistema nao identificado como Kali/Debian. Continuando mesmo assim..."
    fi

    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
        erro "Execute como root: sudo ./$(basename "$0")"
        exit 1
    fi
}

# --- Argumentos --------------------------------------------------------------
definir_log

CATEGORIAS_SELECIONADAS=()
SOMENTE_ATUALIZAR=false
INSTALAR=true

if [ $# -eq 0 ]; then
    CATEGORIAS_SELECIONADAS=(recon web passwords misc)
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --full)
            CATEGORIAS_SELECIONADAS=(${!CATEGORIAS[@]})
            ;;
        --only)
            shift
            if [ $# -eq 0 ]; then
                erro "--only exige uma lista de categorias."
                exit 1
            fi
            IFS=',' read -ra CATEGORIAS_SELECIONADAS <<<"$1"
            ;;
        --upgrade)
            SOMENTE_ATUALIZAR=true
            INSTALAR=false
            ;;
        --list)
            listar
            exit 0
            ;;
        -h|--help)
            ajuda
            exit 0
            ;;
        *)
            erro "Opcao desconhecida: $1 (use --help)"
            exit 1
            ;;
    esac
    shift
done

# --- Execucao ----------------------------------------------------------------
echo
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   Kali Setup - $(date '+%d/%m/%Y %H:%M')${NC}"
echo -e "${GREEN}=============================================${NC}"
echo

verificar_ambiente
atualizar_sistema || exit 1

if [ "$INSTALAR" = true ] && [ "$SOMENTE_ATUALIZAR" = false ]; then
    echo
    instalar_ferramentas "${CATEGORIAS_SELECIONADAS[@]}"
fi

echo
ok "Concluido! Log salvo em: $LOG_FILE"
echo -e "${CYAN}Dica:${NC} rode 'sudo reboot' se o kernel foi atualizado."
echo
