#!/usr/bin/env bash
# ============================================================================
#  scripts/setup_links.sh — Criação de links simbólicos
#  Chamado pelo install.sh (source). NÃO execute diretamente.
#
#  Lógica: Se o destino já existe e NÃO é um symlink, renomeia para .bak.
#          Depois cria o symlink com ln -sf.
# ============================================================================

# ── Função para criar link simbólico seguro ─────────────────────────────────
safe_link() {
    local src="$1"    # Arquivo/pasta de origem (dentro de dotfiles/)
    local dest="$2"   # Destino no $HOME

    # Garante que o diretório pai existe
    mkdir -p "$(dirname "${dest}")"

    # Se o destino já é o symlink correto, pula
    if [[ -L "${dest}" ]]; then
        local current_target
        current_target="$(readlink -f "${dest}")"
        if [[ "${current_target}" == "$(readlink -f "${src}")" ]]; then
            log_success "Link já existe: ${dest} → ${src}"
            return 0
        else
            log_warn "Symlink existente aponta para outro alvo. Recriando..."
            rm -f "${dest}"
        fi
    fi

    # Se existe um arquivo/pasta real (não symlink), faz backup
    if [[ -e "${dest}" ]]; then
        local backup="${dest}.bak.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backup: ${dest} → ${backup}"
        mv "${dest}" "${backup}"
    fi

    # Cria o symlink
    ln -sf "${src}" "${dest}"
    log_success "Link criado: ${dest} → ${src}"
}

# ── Mapeamento de links ────────────────────────────────────────────────────
# Formato: safe_link "<origem_no_repo>" "<destino_no_HOME>"
#
# Adicione novas entradas aqui para expandir seus dotfiles.
# ──────────────────────────────────────────────────────────────────────────────

DOTFILES_SRC="${DOTFILES_DIR}/dotfiles"

# ── Shell ───────────────────────────────────────────────────────────────────
safe_link "${DOTFILES_SRC}/.zshrc"      "${HOME}/.zshrc"
safe_link "${DOTFILES_SRC}/.zshenv"     "${HOME}/.zshenv"
safe_link "${DOTFILES_SRC}/.aliases"    "${HOME}/.aliases"

# ── Git ─────────────────────────────────────────────────────────────────────
safe_link "${DOTFILES_SRC}/.gitconfig"  "${HOME}/.gitconfig"

# ── Tmux ────────────────────────────────────────────────────────────────────
safe_link "${DOTFILES_SRC}/.tmux.conf"  "${HOME}/.tmux.conf"

# ── Neovim ──────────────────────────────────────────────────────────────────
safe_link "${DOTFILES_SRC}/.config/nvim" "${HOME}/.config/nvim"

# ── Kitty ───────────────────────────────────────────────────────────────────
safe_link "${DOTFILES_SRC}/.config/kitty" "${HOME}/.config/kitty"

# ── Btop ────────────────────────────────────────────────────────────────────
safe_link "${DOTFILES_SRC}/.config/btop" "${HOME}/.config/btop"

# ── VS Code ─────────────────────────────────────────────────────────────────
safe_link "${DOTFILES_SRC}/.config/Code" "${HOME}/.config/Code"

log_info "Todos os links simbólicos foram processados."
