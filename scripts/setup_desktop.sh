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

# ── Configurando Fontes ─────────────────────────────────────────────────────
# Versão do Nerd Fonts (atualize aqui quando sair nova release)
NERD_FONTS_VERSION="v3.4.0"
NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"
FONTS_DIR="${HOME}/.local/share/fonts"

# Fontes Nerd a serem instaladas (nome do .zip no GitHub Releases)
NERD_FONTS=(
    "CascadiaCode"
    "DepartureMono"
    "FiraCode"
    "JetBrainsMono"
)

# Baixa e instala UMA Nerd Font (idempotente)
# Uso: install_nerd_font "JetBrainsMono"
install_nerd_font() {
    local font_name="$1"
    local font_dest="${FONTS_DIR}/${font_name}"
    local zip_url="${NERD_FONTS_BASE_URL}/${font_name}.zip"

    # Se a pasta da fonte já existe e contém .ttf, pula
    if [[ -d "${font_dest}" ]] && ls "${font_dest}"/*.ttf &>/dev/null; then
        log_success "Fonte já instalada: ${font_name}"
        return 0
    fi

    log_info "Baixando ${font_name} (${NERD_FONTS_VERSION})..."

    local tmp_zip
    tmp_zip="$(mktemp /tmp/nerd-font-XXXXXX.zip)"

    if ! curl -fsSL -o "${tmp_zip}" "${zip_url}"; then
        log_warn "Falha ao baixar: ${zip_url}"
        rm -f "${tmp_zip}"
        return 1
    fi

    mkdir -p "${font_dest}"

    # Extrai apenas arquivos .ttf (ignora variáveis/Windows)
    unzip -o -j "${tmp_zip}" '*.ttf' -d "${font_dest}" -x '*Windows*' &>/dev/null || \
        unzip -o -j "${tmp_zip}" '*.ttf' -d "${font_dest}" &>/dev/null

    rm -f "${tmp_zip}"
    log_success "Fonte instalada: ${font_name} → ${font_dest}"
}

# Instala todas as Nerd Fonts configuradas e atualiza o cache
setup_nerd_fonts() {
    log_info "Instalando Nerd Fonts (${#NERD_FONTS[@]} fontes)..."

    mkdir -p "${FONTS_DIR}"

    for font in "${NERD_FONTS[@]}"; do
        install_nerd_font "${font}"
    done

    # Atualiza o cache de fontes do sistema
    if command -v fc-cache &>/dev/null; then
        log_info "Atualizando cache de fontes (fc-cache)..."
        fc-cache -fv "${FONTS_DIR}" &>/dev/null
        log_success "Cache de fontes atualizado."
    else
        log_warn "fc-cache não encontrado. Instale fontconfig para atualizar o cache."
    fi
}

# ── Configurando Wallpaper ──────────────────────────────────────────────────
# (Placeholder — adicione lógica de wallpaper futuramente)

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
setup_nerd_fonts
setup_desktop_links

log_info "Configuração do Desktop Environment finalizada."
