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
    bat
    tmux
    kitty
    curl
    zsh
    vim
    neovim
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
    firefox
)

DEBIAN_PKGS=(
    build-essential
    xclip
    fd-find
    fonts-noto
    fonts-noto-color-emoji
    qemu-kvm
    libvirt-daemon-system
    libvirt-clients
    bridge-utils
    virt-manager
    firefox-esr
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

# ── Apps Externos ───────────────────────────────────────────────────────────
install_vscode() {
    if command -v code &>/dev/null; then
        log_success "Visual Studio Code já instalado."
        return 0
    fi

    log_info "Instalando Visual Studio Code..."
    if [[ "${DISTRO}" == "arch" ]]; then
        yay -S --noconfirm visual-studio-code-bin
    elif [[ "${DISTRO}" == "debian" ]]; then
        local tmp_deb
        tmp_deb="$(mktemp -d)/vscode.deb"
        log_info "Baixando VS Code (.deb)..."
        curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o "${tmp_deb}"
        sudo dpkg -i "${tmp_deb}" || sudo apt-get install -f -y
        rm -rf "$(dirname "${tmp_deb}")"
    fi
}

install_discord() {
    if command -v discord &>/dev/null; then
        log_success "Discord já instalado."
        return 0
    fi

    log_info "Instalando Discord..."
    if [[ "${DISTRO}" == "arch" ]]; then
        yay -S --noconfirm discord
    elif [[ "${DISTRO}" == "debian" ]]; then
        local tmp_deb
        tmp_deb="$(mktemp -d)/discord.deb"
        log_info "Baixando Discord (.deb)..."
        curl -L "https://discord.com/api/download?platform=linux&format=deb" -o "${tmp_deb}"
        sudo dpkg -i "${tmp_deb}" || sudo apt-get install -f -y
        rm -rf "$(dirname "${tmp_deb}")"
    fi
}

# ── Executar ────────────────────────────────────────────────────────────────
install_packages
install_yay
install_vscode
install_discord

log_info "Instalação de pacotes finalizada."
