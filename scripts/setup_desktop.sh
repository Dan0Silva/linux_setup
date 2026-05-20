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

    # Se a pasta da fonte já existe e contém .ttf ou .otf, pula
    if [[ -d "${font_dest}" ]] && compgen -G "${font_dest}"/*.{ttf,otf} &>/dev/null; then
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

    # Extrai arquivos .ttf e .otf (ignora variáveis/Windows)
    # Algumas fontes (ex: DepartureMono) distribuem .otf ao invés de .ttf
    local extracted=false

    for ext in ttf otf; do
        if unzip -o -j "${tmp_zip}" "*.${ext}" -d "${font_dest}" -x '*Windows*' &>/dev/null || \
           unzip -o -j "${tmp_zip}" "*.${ext}" -d "${font_dest}" &>/dev/null; then
            extracted=true
        fi
    done

    if [[ "${extracted}" != true ]]; then
        log_warn "Nenhum arquivo .ttf ou .otf encontrado em: ${font_name}.zip"
        rm -f "${tmp_zip}"
        return 1
    fi

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
if [[ "${DISTRO}" == "arch" ]]; then
    WALLPAPER_SRC="${DOTFILES_DIR}/assets/wallpapers/default_archlinux.jpg"
elif [[ "${DISTRO}" == "debian" ]]; then
    WALLPAPER_SRC="${DOTFILES_DIR}/assets/wallpapers/default_debian.png"
else
    WALLPAPER_SRC="${DOTFILES_DIR}/assets/wallpapers/default.png"
fi

# Detecta o DE/WM ativo e aplica o wallpaper com a ferramenta correta.
# Suporte: GNOME, KDE Plasma, XFCE, Cinnamon, MATE, Sway, Hyprland, feh, nitrogen.
setup_wallpaper() {
    if [[ ! -f "${WALLPAPER_SRC}" ]]; then
        log_warn "Wallpaper não encontrado: ${WALLPAPER_SRC}"
        return 0
    fi

    local wallpaper
    wallpaper="$(readlink -f "${WALLPAPER_SRC}")"

    local desktop="${XDG_CURRENT_DESKTOP:-unknown}"
    local session="${XDG_SESSION_TYPE:-x11}"

    log_info "Configurando wallpaper (DE: ${desktop}, session: ${session})..."

    # Normaliza para minúsculas
    desktop="${desktop,,}"

    case "${desktop}" in
        *gnome*|*ubuntu*)
            if command -v gsettings &>/dev/null; then
                gsettings set org.gnome.desktop.background picture-uri "file://${wallpaper}"
                gsettings set org.gnome.desktop.background picture-uri-dark "file://${wallpaper}"
                gsettings set org.gnome.desktop.background picture-options "zoom"
                log_success "Wallpaper configurado (GNOME/gsettings)."
            else
                log_warn "gsettings não encontrado. Instale gnome-settings-daemon."
            fi
            ;;

        *kde*|*plasma*)
            if command -v plasma-apply-wallpaperimage &>/dev/null; then
                plasma-apply-wallpaperimage "${wallpaper}" &>/dev/null
                log_success "Wallpaper configurado (KDE Plasma)."
            else
                log_warn "plasma-apply-wallpaperimage não encontrado."
            fi
            ;;

        *xfce*)
            if command -v xfconf-query &>/dev/null; then
                # Aplica em todos os monitores conhecidos
                for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "last-image$"); do
                    xfconf-query -c xfce4-desktop -p "${prop}" -s "${wallpaper}" 2>/dev/null
                done
                log_success "Wallpaper configurado (XFCE)."
            else
                log_warn "xfconf-query não encontrado."
            fi
            ;;

        *cinnamon*)
            if command -v gsettings &>/dev/null; then
                gsettings set org.cinnamon.desktop.background picture-uri "file://${wallpaper}"
                gsettings set org.cinnamon.desktop.background picture-options "zoom"
                log_success "Wallpaper configurado (Cinnamon)."
            else
                log_warn "gsettings não encontrado."
            fi
            ;;

        *mate*)
            if command -v gsettings &>/dev/null; then
                gsettings set org.mate.background picture-filename "${wallpaper}"
                gsettings set org.mate.background picture-options "zoom"
                log_success "Wallpaper configurado (MATE)."
            else
                log_warn "gsettings não encontrado."
            fi
            ;;

        *sway*)
            if command -v swaymsg &>/dev/null; then
                swaymsg output "*" bg "${wallpaper}" fill &>/dev/null
                log_success "Wallpaper configurado (Sway)."
            else
                log_warn "swaymsg não encontrado."
            fi
            ;;

        *hyprland*)
            if command -v hyprctl &>/dev/null; then
                hyprctl hyprpaper wallpaper ",${wallpaper}" &>/dev/null || \
                    log_info "Configure hyprpaper.conf manualmente com: wallpaper = ,${wallpaper}"
                log_success "Wallpaper configurado (Hyprland)."
            else
                log_warn "hyprctl não encontrado."
            fi
            ;;

        *)
            # Fallback para WMs minimalistas (i3, bspwm, openbox, etc.)
            if command -v feh &>/dev/null; then
                feh --bg-fill "${wallpaper}" &>/dev/null
                log_success "Wallpaper configurado (feh)."
            elif command -v nitrogen &>/dev/null; then
                nitrogen --set-zoom-fill --save "${wallpaper}" &>/dev/null
                log_success "Wallpaper configurado (nitrogen)."
            else
                log_warn "Nenhuma ferramenta de wallpaper encontrada (feh, nitrogen)."
                log_info "Instale feh ou nitrogen, ou configure manualmente."
            fi
            ;;
    esac
}

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
setup_wallpaper
setup_desktop_links

log_info "Configuração do Desktop Environment finalizada."
