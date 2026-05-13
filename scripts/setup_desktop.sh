#!/usr/bin/env bash
# ============================================================================
#  scripts/setup_desktop.sh — Desktop Environment (Polybar, Rofi, i3, etc.)
#  Chamado pelo install.sh (source). NÃO execute diretamente.
#
#  EXEMPLO: Este script demonstra como adicionar novos módulos de Desktop.
#  Descomente e adapte conforme seu setup.
# ============================================================================

DOTFILES_SRC="${DOTFILES_DIR}/dotfiles"

# ── Pacotes de Desktop por distro ───────────────────────────────────────────
DESKTOP_ARCH_PKGS=(
    # polybar
    # rofi
    # i3-wm
    # picom
    # dunst
    # feh
    # nitrogen
)

DESKTOP_DEBIAN_PKGS=(
    # polybar
    # rofi
    # i3
    # picom
    # dunst
    # feh
    # nitrogen
)

# ── Instalar pacotes de Desktop ─────────────────────────────────────────────
install_desktop_pkgs() {
    local -a pkgs=()

    case "${DISTRO}" in
        arch)   pkgs=("${DESKTOP_ARCH_PKGS[@]}") ;;
        debian) pkgs=("${DESKTOP_DEBIAN_PKGS[@]}") ;;
    esac

    if [[ ${#pkgs[@]} -eq 0 ]]; then
        log_info "Nenhum pacote de Desktop configurado. Edite setup_desktop.sh."
        return 0
    fi

    for pkg in "${pkgs[@]}"; do
        eval "${PKG_INSTALL} ${pkg}" || log_warn "Falha: ${pkg}"
    done
}

# ── Links de configuração do Desktop ────────────────────────────────────────
setup_desktop_links() {
    # Descomente conforme for adicionando configs ao repo:

    # Polybar
    # safe_link "${DOTFILES_SRC}/.config/polybar" "${HOME}/.config/polybar"

    # Rofi
    # safe_link "${DOTFILES_SRC}/.config/rofi" "${HOME}/.config/rofi"

    # i3
    # safe_link "${DOTFILES_SRC}/.config/i3" "${HOME}/.config/i3"

    # Picom
    # safe_link "${DOTFILES_SRC}/.config/picom" "${HOME}/.config/picom"

    # Dunst
    # safe_link "${DOTFILES_SRC}/.config/dunst" "${HOME}/.config/dunst"

    log_info "Links de Desktop processados (verifique se há configs no repo)."
}

# ── Executar ────────────────────────────────────────────────────────────────
install_desktop_pkgs
setup_desktop_links

log_info "Configuração do Desktop Environment finalizada."
