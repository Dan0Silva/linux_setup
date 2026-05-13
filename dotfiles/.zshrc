# ============================================================================
#  .zshrc — Configuração principal do Zsh
#  Gerenciado pelos dotfiles. NÃO edite diretamente no $HOME.
# ============================================================================

# ── Oh-My-Zsh ──────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

# Tema (descomente UM):
ZSH_THEME="archcraft"
# ZSH_THEME="robbyrussell"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# ── Variáveis de ambiente ──────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export LANG="pt_BR.UTF-8"
export LC_ALL="pt_BR.UTF-8"

# ── Path ────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

# ── Aliases ─────────────────────────────────────────────────────────────────
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ── ASDF ────────────────────────────────────────────────────────────────────
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

if command -v asdf >/dev/null 2>&1; then
  if asdf where golang >/dev/null 2>&1; then
    export GOROOT="$(asdf where golang)/go"
    export PATH="$PATH:$GOROOT/bin"
  fi
fi
