#!/usr/bin/env bash
# ============================================================================
#  scripts/setup_vscode.sh — Configuração do VS Code
#  Chamado pelo install.sh (source). NÃO execute diretamente.
# ============================================================================

# ── Caminhos do VS Code no Linux ────────────────────────────────────────────
# VS Code (normal):   ~/.config/Code/User/
# VS Code (Insiders):  ~/.config/Code - Insiders/User/
# VSCodium:            ~/.config/VSCodium/User/

VSCODE_SRC="${DOTFILES_DIR}/dotfiles/.config/Code/User"
VSCODE_DEST="${HOME}/.config/Code/User"

# ── Função para linkar configs do VS Code ───────────────────────────────────
setup_vscode_config() {
    local src_dir="$1"
    local dest_dir="$2"

    if [[ ! -d "${src_dir}" ]]; then
        log_warn "Pasta de configs VS Code não encontrada no repo: ${src_dir}"
        log_info "Crie seus arquivos em: ${src_dir}"
        return 0
    fi

    mkdir -p "${dest_dir}"

    # Lista de arquivos para linkar
    local config_files=("settings.json" "keybindings.json" "snippets")

    for item in "${config_files[@]}"; do
        local src="${src_dir}/${item}"
        local dest="${dest_dir}/${item}"

        if [[ ! -e "${src}" ]]; then
            log_warn "Arquivo não encontrado no repo: ${item}. Pulando."
            continue
        fi

        # Backup se já existe e não é symlink
        if [[ -e "${dest}" && ! -L "${dest}" ]]; then
            local backup="${dest}.bak.$(date +%Y%m%d_%H%M%S)"
            log_warn "Backup: ${dest} → ${backup}"
            mv "${dest}" "${backup}"
        fi

        ln -sf "${src}" "${dest}"
        log_success "VS Code link: ${dest} → ${src}"
    done
}

# ── Instalar extensões do VS Code (opcional) ────────────────────────────────
install_vscode_extensions() {
    local extensions_file="${DOTFILES_DIR}/dotfiles/.config/Code/extensions.txt"

    if [[ ! -f "${extensions_file}" ]]; then
        log_info "Nenhum arquivo de extensões encontrado (${extensions_file}). Pulando."
        return 0
    fi

    if ! command -v code &>/dev/null; then
        log_warn "'code' não encontrado no PATH. Instale o VS Code primeiro."
        return 0
    fi

    log_info "Instalando extensões do VS Code..."
    while IFS= read -r ext; do
        # Ignora linhas vazias e comentários
        [[ -z "${ext}" || "${ext}" =~ ^# ]] && continue

        if code --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
            log_success "Extensão já instalada: ${ext}"
        else
            log_info "Instalando extensão: ${ext}"
            code --install-extension "${ext}" --force 2>/dev/null || log_warn "Falha: ${ext}"
        fi
    done < "${extensions_file}"
}

# ── Executar ────────────────────────────────────────────────────────────────
setup_vscode_config "${VSCODE_SRC}" "${VSCODE_DEST}"
install_vscode_extensions

log_info "Configuração do VS Code finalizada."
