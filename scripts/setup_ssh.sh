#!/usr/bin/env bash
# ============================================================================
#  scripts/setup_ssh.sh — Configuração de permissões SSH
#  Chamado pelo install.sh (source). NÃO execute diretamente.
# ============================================================================

SSH_DIR="${HOME}/.ssh"

setup_ssh_dir() {
    if [[ ! -d "${SSH_DIR}" ]]; then
        log_info "Criando diretório ${SSH_DIR}..."
        mkdir -p "${SSH_DIR}"
    fi
    chmod 700 "${SSH_DIR}"
    log_success "Permissões do diretório SSH: 700"
}

fix_ssh_permissions() {
    for key in "${SSH_DIR}"/id_*; do
        if [[ -f "${key}" && "${key}" != *.pub ]]; then
            chmod 600 "${key}"
            log_success "Permissão 600: $(basename "${key}")"
        fi
    done

    for pub in "${SSH_DIR}"/*.pub; do
        if [[ -f "${pub}" ]]; then
            chmod 644 "${pub}"
            log_success "Permissão 644: $(basename "${pub}")"
        fi
    done

    [[ -f "${SSH_DIR}/authorized_keys" ]] && chmod 600 "${SSH_DIR}/authorized_keys"
    [[ -f "${SSH_DIR}/known_hosts" ]]     && chmod 644 "${SSH_DIR}/known_hosts"
    [[ -f "${SSH_DIR}/config" ]]          && chmod 600 "${SSH_DIR}/config"
}

link_ssh_config() {
    local src="${DOTFILES_DIR}/dotfiles/.ssh/config"
    if [[ -f "${src}" ]]; then
        if [[ -f "${SSH_DIR}/config" && ! -L "${SSH_DIR}/config" ]]; then
            mv "${SSH_DIR}/config" "${SSH_DIR}/config.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        ln -sf "${src}" "${SSH_DIR}/config"
        chmod 600 "${SSH_DIR}/config"
        log_success "SSH config linkado."
    fi
}

setup_ssh_dir
fix_ssh_permissions
link_ssh_config

log_info "Configuração do SSH finalizada."
