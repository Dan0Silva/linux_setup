#!/usr/bin/env bash
# ============================================================================
#  scripts/setup_zsh.sh — Configuração do Zsh + Oh-My-Zsh + Plugins
#  Chamado pelo install.sh (source). NÃO execute diretamente.
# ============================================================================

ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"

# ── Instalar Oh-My-Zsh ─────────────────────────────────────────────────────
install_oh_my_zsh() {
    # Verifica se o OMZ está realmente instalado (oh-my-zsh.sh é o indicador real,
    # não apenas a existência de ~/.oh-my-zsh que pode ser criada parcialmente
    # por clone_plugin ou link_zsh_custom)
    if [[ -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        log_success "Oh-My-Zsh já instalado."
        return 0
    fi

    log_info "Instalando Oh-My-Zsh..."

    # KEEP_ZSHRC=yes evita que o instalador do OMZ sobrescreva o .zshrc
    # gerenciado pelos dotfiles (que pode já ser um symlink de setup_links.sh)
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    log_success "Oh-My-Zsh instalado."

    # Restaura o symlink do .zshrc caso tenha sido movido/sobrescrito
    _restore_zshrc_link
}

# ── Clonar plugin (idempotente) ─────────────────────────────────────────────
clone_plugin() {
    local repo="$1"
    local name="$2"
    local dest="${ZSH_CUSTOM}/plugins/${name}"

    if [[ -d "${dest}" ]]; then
        log_success "Plugin já existe: ${name}"
        # Atualiza se possível
        (cd "${dest}" && git pull --quiet 2>/dev/null) || true
        return 0
    fi

    log_info "Clonando plugin: ${name}..."
    git clone --depth=1 "${repo}" "${dest}"
    log_success "Plugin '${name}' instalado."
}

# ── Restaurar symlink do .zshrc ────────────────────────────────────────────
# Se o instalador do OMZ criou/sobrescreveu .zshrc, restaura o link do dotfiles.
_restore_zshrc_link() {
    local zshrc_src="${DOTFILES_DIR}/dotfiles/.zshrc"
    local zshrc_dest="${HOME}/.zshrc"

    if [[ ! -f "${zshrc_src}" ]]; then
        return 0
    fi

    # Se já é o symlink correto, nada a fazer
    if [[ -L "${zshrc_dest}" && "$(readlink -f "${zshrc_dest}")" == "$(readlink -f "${zshrc_src}")" ]]; then
        return 0
    fi

    # Backup do .zshrc gerado pelo OMZ (se existir)
    if [[ -e "${zshrc_dest}" ]]; then
        local backup="${zshrc_dest}.bak.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backup do .zshrc sobrescrito pelo OMZ: ${backup}"
        mv "${zshrc_dest}" "${backup}"
    fi

    ln -sf "${zshrc_src}" "${zshrc_dest}"
    log_success "Symlink do .zshrc restaurado: ${zshrc_dest} → ${zshrc_src}"
}

# ── Instalar tema Archcraft (symlink) ───────────────────────────────────────
install_archcraft_theme() {
    local src="${DOTFILES_DIR}/modules/zsh/custom/themes/archcraft.zsh-theme"
    local dest_dir="${ZSH_CUSTOM}/themes"
    local dest="${dest_dir}/archcraft.zsh-theme"

    if [[ ! -f "${src}" ]]; then
        log_warn "Tema archcraft não encontrado em: ${src}"
        return 0
    fi

    mkdir -p "${dest_dir}"

    # Se já é o symlink correto, pula
    if [[ -L "${dest}" && "$(readlink -f "${dest}")" == "$(readlink -f "${src}")" ]]; then
        log_success "Tema archcraft já linkado corretamente."
        return 0
    fi

    # Backup se existir arquivo real
    if [[ -e "${dest}" && ! -L "${dest}" ]]; then
        local backup="${dest}.bak.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backup do tema existente: ${backup}"
        mv "${dest}" "${backup}"
    fi

    ln -sf "${src}" "${dest}"
    log_success "Tema archcraft linkado: ${dest} → ${src}"
}

# ── Definir Zsh como shell padrão ───────────────────────────────────────────
set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ "${SHELL}" == "${zsh_path}" ]]; then
        log_success "Zsh já é o shell padrão."
        return 0
    fi

    log_info "Definindo Zsh como shell padrão..."
    chsh -s "${zsh_path}" || log_warn "Falha ao mudar shell. Execute manualmente: chsh -s ${zsh_path}"
}

# ── Linkar pasta custom do repo → ~/.oh-my-zsh/custom ──────────────────────
# Linka cada item de modules/zsh/custom/ (themes, aliases, etc.) dentro de
# $ZSH_CUSTOM, preservando a subpasta plugins/ que é gerenciada por clone_plugin().
link_zsh_custom() {
    local custom_src="${DOTFILES_DIR}/modules/zsh/custom"

    if [[ ! -d "${custom_src}" ]]; then
        log_warn "Diretório de customizações não encontrado: ${custom_src}"
        return 0
    fi

    log_info "Linkando customizações de ${custom_src} → ${ZSH_CUSTOM}..."

    for item in "${custom_src}"/*; do
        local name
        name="$(basename "${item}")"

        # Pula .gitkeep
        [[ "${name}" == ".gitkeep" ]] && continue

        # Pula a pasta plugins — gerenciada por clone_plugin()
        [[ "${name}" == "plugins" ]] && continue

        local dest="${ZSH_CUSTOM}/${name}"

        # Se já é o symlink correto, pula
        if [[ -L "${dest}" && "$(readlink -f "${dest}")" == "$(readlink -f "${item}")" ]]; then
            log_success "Já linkado: ${name}"
            continue
        fi

        # Backup se existir arquivo/pasta real (não symlink)
        if [[ -e "${dest}" && ! -L "${dest}" ]]; then
            local backup="${dest}.bak.$(date +%Y%m%d_%H%M%S)"
            log_warn "Backup: ${dest} → ${backup}"
            mv "${dest}" "${backup}"
        fi

        ln -sf "${item}" "${dest}"
        log_success "Custom linkado: ${dest} → ${item}"
    done
}

# ── Executar ────────────────────────────────────────────────────────────────
install_oh_my_zsh

clone_plugin "https://github.com/zsh-users/zsh-autosuggestions.git"    "zsh-autosuggestions"
clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "zsh-syntax-highlighting"
clone_plugin "https://github.com/zsh-users/zsh-completions.git"        "zsh-completions"

install_archcraft_theme
set_default_shell
link_zsh_custom

log_info "Configuração do Zsh finalizada."
