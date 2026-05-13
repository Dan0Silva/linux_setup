#!/usr/bin/env bash
# ============================================================================
#  scripts/setup_virt.sh — Configuração de Virtualização (KVM/QEMU/virt-manager)
#  Chamado pelo install.sh (source). NÃO execute diretamente.
# ============================================================================

setup_virtualization() {
    # 1. Verificar suporte a virtualização de hardware
    local virt_support
    virt_support=$(grep -E -c '(vmx|svm)' /proc/cpuinfo || true)
    
    if [[ "${virt_support}" -eq 0 ]]; then
        log_warn "O suporte a virtualização de hardware (VT-x/AMD-V) não foi detectado ou está desativado na BIOS/UEFI."
        log_warn "A virtualização via KVM não funcionará ou será muito lenta."
    else
        log_success "Suporte a virtualização de hardware detectado."
    fi

    # 2. Habilitar e iniciar o serviço libvirtd
    if command -v systemctl &>/dev/null; then
        log_info "Habilitando e iniciando o serviço libvirtd..."
        sudo systemctl enable --now libvirtd || log_warn "Falha ao habilitar libvirtd."
    else
        log_warn "systemd não detectado, inicie o libvirtd manualmente."
    fi

    # 3. Adicionar o usuário aos grupos necessários
    local user="${USER}"
    log_info "Adicionando o usuário ${user} aos grupos libvirt e kvm..."
    
    # O grupo libvirt pode ser libvirt-qemu em algumas distros (Debian antigo), mas libvirt é o padrão
    for group in libvirt kvm; do
        if getent group "${group}" >/dev/null; then
            sudo usermod -aG "${group}" "${user}"
            log_success "Usuário adicionado ao grupo ${group}."
        else
            log_warn "Grupo ${group} não encontrado no sistema."
        fi
    done

    # 4. Iniciar e habilitar a rede padrão do KVM (virsh default network)
    if command -v virsh &>/dev/null; then
        log_info "Configurando rede padrão do KVM..."
        
        # A rede default pode não existir logo após a instalação antes do libvirtd estar pronto,
        # portanto ignoramos erros aqui
        sudo virsh net-autostart default &>/dev/null || true
        sudo virsh net-start default &>/dev/null || true
        
        # Em algumas distros/instalações é preciso garantir que o usuário faça o virsh funcionar localmente
        virsh net-autostart default &>/dev/null || true
    else
        log_warn "Comando virsh não encontrado."
    fi

    log_warn "Você precisará reiniciar a sessão (fazer logoff/login) ou o sistema para que as mudanças de grupo entrem em vigor."
}

# ── Executar ────────────────────────────────────────────────────────────────
setup_virtualization

log_info "Configuração de Virtualização finalizada."
