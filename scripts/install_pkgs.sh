#!/usr/bin/env bash
# ============================================================================
#  scripts/install_pkgs.sh — Instalação de pacotes do sistema
#  Chamado pelo install.sh (source). NÃO execute diretamente.
# ============================================================================

# ── Pacotes comuns (nomes iguais em Arch e Debian) ──────────────────────────
COMMON_PKGS=(
    git
    curl
    wget
    unzip
    btop
    fastfetch
    tree
    ripgrep
    fd-find
    bat
    tmux
    kitty
    zsh
    vim
    neovim
    firefox-esr
)

# ── Pacotes específicos por distro ──────────────────────────────────────────
ARCH_PKGS=(
    base-devel
    lazygit
    github-cli
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
    xclip
    virt-manager
    qemu-desktop
    libvirt
    dnsmasq
    iptables-nft
    openbsd-netcat
)

DEBIAN_PKGS=(
    build-essential
    xclip
    fonts-noto
    fonts-noto-color-emoji
    software-properties-common
    qemu-kvm
    libvirt-daemon-system
    libvirt-clients
    bridge-utils
    virt-manager
)

# ── Função de instalação ────────────────────────────────────────────────────
install_packages() {
    local -a pkgs=("${COMMON_PKGS[@]}")

    case "${DISTRO}" in
        arch)
            pkgs+=("${ARCH_PKGS[@]}")
            log_info "Atualizando mirrors e sistema (pacman)..."
            eval "${PKG_UPDATE}"
            ;;
        debian)
            pkgs+=("${DEBIAN_PKGS[@]}")
            log_info "Atualizando repositórios (apt)..."
            eval "${PKG_UPDATE}"
            ;;
    esac

    log_info "Instalando ${#pkgs[@]} pacotes..."
    for pkg in "${pkgs[@]}"; do
        if command -v "${pkg}" &>/dev/null || dpkg -l "${pkg}" &>/dev/null 2>&1 || pacman -Qi "${pkg}" &>/dev/null 2>&1; then
            log_success "Já instalado: ${pkg}"
        else
            log_info "Instalando: ${pkg}"
            eval "${PKG_INSTALL} ${pkg}" || log_warn "Falha ao instalar: ${pkg}"
        fi
    done
}

# ── AUR Helper (apenas Arch) ────────────────────────────────────────────────
install_yay() {
    if [[ "${DISTRO}" != "arch" ]]; then
        return 0
    fi

    if command -v yay &>/dev/null; then
        log_success "yay já instalado."
        return 0
    fi

    log_info "Instalando yay (AUR Helper)..."
    local yay_dir
    yay_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "${yay_dir}"
    (cd "${yay_dir}" && makepkg -si --noconfirm)
    rm -rf "${yay_dir}"
    log_success "yay instalado com sucesso."
}

# ── Executar ────────────────────────────────────────────────────────────────
install_packages
install_yay

log_info "Instalação de pacotes finalizada."
