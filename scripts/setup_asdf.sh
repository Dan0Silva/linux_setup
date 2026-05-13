#!/usr/bin/env bash
# ============================================================================
#  scripts/setup_asdf.sh — Instalação do asdf version manager (Binário)
#  Chamado pelo install.sh (source). NÃO execute diretamente.
# ============================================================================

ASDF_VERSION="v0.19.0"
LOCAL_BIN="${HOME}/.local/bin"
ASDF_BIN="${LOCAL_BIN}/asdf"

setup_asdf() {
    if [[ -x "${ASDF_BIN}" ]]; then
        local current_version
        current_version=$("${ASDF_BIN}" --version 2>/dev/null | awk '{print $1}')
        if [[ "${current_version}" == "${ASDF_VERSION}" ]]; then
            log_success "asdf ${ASDF_VERSION} já está instalado em ${ASDF_BIN}"
            return 0
        fi
    fi

    log_info "Instalando asdf (${ASDF_VERSION}) via binário pré-compilado..."
    
    mkdir -p "${LOCAL_BIN}"

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local tarball="asdf-${ASDF_VERSION}-linux-amd64.tar.gz"
    local download_url="https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/${tarball}"

    if ! curl -fsSL -o "${tmp_dir}/${tarball}" "${download_url}"; then
        log_warn "Falha ao baixar o asdf de ${download_url}"
        rm -rf "${tmp_dir}"
        return 1
    fi

    tar -xzf "${tmp_dir}/${tarball}" -C "${tmp_dir}" asdf
    mv "${tmp_dir}/asdf" "${ASDF_BIN}"
    chmod +x "${ASDF_BIN}"
    rm -rf "${tmp_dir}"

    log_success "asdf instalado com sucesso em ${ASDF_BIN}."
}

# ── Executar ────────────────────────────────────────────────────────────────
setup_asdf

log_info "Configuração do asdf finalizada."
