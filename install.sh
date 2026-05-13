#!/usr/bin/env bash
# ============================================================================
#  install.sh — Orquestrador principal do dotfiles
#  Uso: ./install.sh [--all | --links | --pkgs | --zsh | --vscode | --ssh | --desktop]
#
#  Pode ser executado múltiplas vezes sem efeitos colaterais (idempotente).
#  Suporte: Arch Linux e Debian/Ubuntu.
# ============================================================================
set -euo pipefail

# ── Diretórios ──────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${DOTFILES_DIR}/scripts"

# ── Variáveis de configuração (flags de módulos) ───────────────────────────
# Edite aqui para habilitar/desabilitar módulos individuais.
# Também pode ser sobrescrito via flags de linha de comando.
ENABLE_PKGS=false
ENABLE_LINKS=false
ENABLE_ZSH=false
ENABLE_VSCODE=false
ENABLE_VIRT=false
ENABLE_DESKTOP=false   # Ex: Polybar, Rofi, i3, Hyprland...

# ── Cores para output ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Funções de log ──────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}      $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $*"; }
log_header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${NC}"; \
                echo -e "${BOLD}${CYAN}  $*${NC}"; \
                echo -e "${BOLD}${CYAN}══════════════════════════════════════════${NC}\n"; }

# ── Detecção de distro ──────────────────────────────────────────────────────
detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID}" in
            arch|manjaro|endeavouros|garuda)
                DISTRO="arch"
                PKG_MANAGER="pacman"
                PKG_INSTALL="sudo pacman -S --noconfirm --needed"
                PKG_UPDATE="sudo pacman -Syu --noconfirm"
                ;;
            debian|ubuntu|linuxmint|pop|elementary|zorin)
                DISTRO="debian"
                PKG_MANAGER="apt"
                PKG_INSTALL="sudo apt install -y"
                PKG_UPDATE="sudo apt update && sudo apt upgrade -y"
                ;;
            *)
                log_error "Distro '${ID}' não suportada. Suportadas: Arch, Debian/Ubuntu."
                exit 1
                ;;
        esac
    else
        log_error "Arquivo /etc/os-release não encontrado. Distro não identificada."
        exit 1
    fi

    export DISTRO PKG_MANAGER PKG_INSTALL PKG_UPDATE
    log_success "Distro detectada: ${BOLD}${ID}${NC} (família: ${DISTRO}, pkg: ${PKG_MANAGER})"
}

# ── Parse de argumentos ────────────────────────────────────────────────────
parse_args() {
    # Sem argumentos = interativo (mostra ajuda)
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    for arg in "$@"; do
        case "${arg}" in
            --all)
                ENABLE_PKGS=true
                ENABLE_LINKS=true
                ENABLE_ZSH=true
                ENABLE_VSCODE=true
                ENABLE_VIRT=true
                ENABLE_DESKTOP=true
                ;;
            --pkgs)     ENABLE_PKGS=true ;;
            --links)    ENABLE_LINKS=true ;;
            --zsh)      ENABLE_ZSH=true ;;
            --vscode)   ENABLE_VSCODE=true ;;
            --virt)     ENABLE_VIRT=true ;;
            --desktop)  ENABLE_DESKTOP=true ;;
            --help|-h)  show_help; exit 0 ;;
            *)
                log_error "Flag desconhecida: ${arg}"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo -e "${BOLD}Uso:${NC} ./install.sh [FLAGS]"
    echo ""
    echo -e "${BOLD}Flags disponíveis:${NC}"
    echo "  --all       Executa TODOS os módulos"
    echo "  --pkgs      Instala pacotes do sistema"
    echo "  --links     Cria links simbólicos dos dotfiles"
    echo "  --zsh       Configura Zsh + Oh-My-Zsh + plugins"
    echo "  --vscode    Configura VS Code (settings.json)"
    echo "  --virt      Configura Virtualização (KVM, QEMU, virt-manager)"
    echo "  --desktop   Configura Desktop Environment (Polybar, Rofi, etc.)"
    echo "  --help, -h  Mostra esta ajuda"
    echo ""
    echo -e "${BOLD}Exemplos:${NC}"
    echo "  ./install.sh --all"
    echo "  ./install.sh --links --zsh"
    echo "  ./install.sh --pkgs"
}

# ── Execução dos módulos ───────────────────────────────────────────────────
run_module() {
    local module_name="$1"
    local script_path="$2"

    if [[ ! -f "${script_path}" ]]; then
        log_warn "Script '${script_path}' não encontrado. Pulando módulo '${module_name}'."
        return 0
    fi

    log_header "Módulo: ${module_name}"
    # shellcheck source=/dev/null
    source "${script_path}"
    log_success "Módulo '${module_name}' concluído."
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
    log_header "Dotfiles Installer — v0rtx"

    parse_args "$@"
    detect_distro

    # Exportar variáveis globais para os sub-scripts
    export DOTFILES_DIR SCRIPTS_DIR DISTRO PKG_MANAGER PKG_INSTALL PKG_UPDATE

    # ── Módulos ─────────────────────────────────────────────────────────────
    [[ "${ENABLE_PKGS}"    == true ]] && run_module "Pacotes do Sistema"   "${SCRIPTS_DIR}/install_pkgs.sh"
    [[ "${ENABLE_LINKS}"   == true ]] && run_module "Links Simbólicos"     "${SCRIPTS_DIR}/setup_links.sh"
    [[ "${ENABLE_ZSH}"     == true ]] && run_module "Zsh + Oh-My-Zsh"     "${SCRIPTS_DIR}/setup_zsh.sh"
    [[ "${ENABLE_VSCODE}"  == true ]] && run_module "VS Code"             "${SCRIPTS_DIR}/setup_vscode.sh"
    [[ "${ENABLE_VIRT}"    == true ]] && run_module "Virtualização"       "${SCRIPTS_DIR}/setup_virt.sh"
    [[ "${ENABLE_DESKTOP}" == true ]] && run_module "Desktop Environment" "${SCRIPTS_DIR}/setup_desktop.sh"

    echo ""
    log_header "Instalação concluída!"
    log_info "Reinicie o terminal ou execute: ${BOLD}source ~/.zshrc${NC}"
}

main "$@"
