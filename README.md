# 🏠 Dotfiles — v0rtx

Repositório modular de dotfiles com instalação automatizada, idempotente e compatível com **Arch Linux** e **Debian/Ubuntu**.

O objetivo é ter um único comando para configurar uma máquina nova do zero — ou atualizar uma já existente sem quebrar nada.

---

## ⚡ Início Rápido

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/dotfiles.git ~/Workbench/dotfiles
cd ~/Workbench/dotfiles

# 2. Dê permissão de execução
chmod +x install.sh scripts/*.sh

# 3. Execute tudo de uma vez
./install.sh --all

# Ou apenas módulos específicos
./install.sh --links --zsh
```

### Flags Disponíveis

| Flag | Descrição |
|---|---|
| `--all` | Executa **todos** os módulos |
| `--pkgs` | Instala pacotes do sistema (`pacman` ou `apt`) |
| `--links` | Cria links simbólicos dos dotfiles para o `$HOME` |
| `--zsh` | Instala Oh-My-Zsh, plugins e o tema Archcraft |
| `--vscode` | Configura VS Code (settings, keybindings, extensões) |
| `--desktop` | Configura Desktop Environment (Polybar, Rofi, etc.) |
| `--help` | Mostra a ajuda |

> O script é **idempotente** — pode ser rodado várias vezes sem efeitos colaterais. Arquivos existentes são renomeados para `.bak` antes de serem substituídos.

---

## 📁 Estrutura do Projeto

```
dotfiles/
├── install.sh                        # Orquestrador principal
│
├── scripts/                          # Módulos de instalação
│   ├── install_pkgs.sh               #   → Pacotes do sistema (Arch/Debian)
│   ├── setup_links.sh                #   → Links simbólicos
│   ├── setup_zsh.sh                  #   → Zsh + Oh-My-Zsh + plugins + tema
│   ├── setup_vscode.sh               #   → VS Code (settings + extensões)
│   └── setup_desktop.sh              #   → Desktop (Polybar, Rofi, i3...)
│
├── dotfiles/                         # Arquivos de configuração (espelha o $HOME)
│   ├── .zshrc                        #   → Config principal do Zsh
│   ├── .zshenv                       #   → Variáveis de ambiente (XDG)
│   ├── .aliases                      #   → Aliases compartilhados
│   ├── .gitconfig                    #   → Configuração do Git
│   ├── .tmux.conf                    #   → Configuração do Tmux
│   └── .config/
│       ├── Code/
│       │   ├── User/settings.json    #   → Settings do VS Code
│       │   └── extensions.txt        #   → Lista de extensões
│       ├── nvim/                     #   → Neovim (adicione seu init.lua)
│       └── kitty/                    #   → Kitty terminal
│
├── modules/                          # Configurações complexas
│   └── zsh/
│       └── custom/                   # Linkado em ~/.oh-my-zsh/custom/
│           └── themes/
│               └── archcraft.zsh-theme
│
└── assets/                           # Recursos estáticos
    ├── fonts/                        #   → Fontes (.ttf, .otf)
    └── wallpapers/                   #   → Wallpapers
```

### Como cada pasta funciona

| Pasta | Função |
|---|---|
| `scripts/` | Cada arquivo é um **módulo** independente, chamado pelo `install.sh` via `source`. Nunca execute diretamente. |
| `dotfiles/` | Espelha a estrutura do `$HOME`. Os arquivos aqui são linkados simbolicamente para seus destinos. |
| `modules/` | Configurações que não são simples links — ex: a pasta `modules/zsh/custom/` é linkada por inteiro dentro de `~/.oh-my-zsh/custom/`. |
| `assets/` | Fontes e wallpapers. Podem ser copiados para os diretórios do sistema por scripts futuros. |

---

## 🔧 Como Adicionar Novas Configurações

### 1. Adicionar um arquivo de configuração simples

Coloque o arquivo dentro de `dotfiles/` espelhando o caminho do `$HOME`, e registre o link em `scripts/setup_links.sh`:

```bash
# Exemplo: adicionar configuração do Starship

# 1. Crie o arquivo no repo
mkdir -p dotfiles/.config
cp ~/.config/starship.toml dotfiles/.config/starship.toml

# 2. Adicione a linha em scripts/setup_links.sh
safe_link "${DOTFILES_SRC}/.config/starship.toml" "${HOME}/.config/starship.toml"
```

A função `safe_link` já cuida de:
- Criar diretórios pai se não existirem
- Fazer backup (`.bak`) se já existir um arquivo real
- Pular se o symlink já estiver correto

### 2. Adicionar customizações do Oh-My-Zsh

Qualquer arquivo ou pasta adicionado em `modules/zsh/custom/` é automaticamente linkado em `~/.oh-my-zsh/custom/` pelo `setup_zsh.sh`.

```bash
# Exemplo: adicionar um tema customizado
cp meu-tema.zsh-theme modules/zsh/custom/themes/

# Exemplo: adicionar aliases do Oh-My-Zsh
echo 'alias k="kubectl"' > modules/zsh/custom/kubectl.zsh
```

> A pasta `plugins/` dentro de `~/.oh-my-zsh/custom/` é preservada — os plugins são gerenciados por `clone_plugin()` no script.

### 3. Adicionar pacotes ao sistema

Edite os arrays em `scripts/install_pkgs.sh`:

```bash
# Pacotes comuns (funcionam em Arch e Debian)
COMMON_PKGS=(
    git
    curl
    seu-pacote-aqui    # ← adicione aqui
)

# Pacotes específicos por distro
ARCH_PKGS=(
    pacote-arch
)

DEBIAN_PKGS=(
    pacote-debian
)
```

### 4. Adicionar configuração de Desktop Environment

O script `scripts/setup_desktop.sh` já vem com um template preparado. Descomente e adapte:

```bash
# 1. Descomente os pacotes em setup_desktop.sh
DESKTOP_ARCH_PKGS=(
    polybar
    rofi
    picom
)

# 2. Adicione o config no repo
cp -r ~/.config/polybar dotfiles/.config/polybar

# 3. Descomente o link em setup_desktop.sh
safe_link "${DOTFILES_SRC}/.config/polybar" "${HOME}/.config/polybar"
```

Para ativar o módulo, passe `--desktop` ou `--all` na execução.

### 5. Criar um módulo totalmente novo

```bash
# 1. Crie o script em scripts/
cat > scripts/setup_docker.sh << 'EOF'
#!/usr/bin/env bash
# Chamado pelo install.sh (source). NÃO execute diretamente.

log_info "Configurando Docker..."

# Sua lógica aqui

log_info "Docker configurado."
EOF

chmod +x scripts/setup_docker.sh
```

```bash
# 2. Registre no install.sh — adicione a flag e o módulo:

# Na seção de variáveis:
ENABLE_DOCKER=false

# No parse_args:
--docker) ENABLE_DOCKER=true ;;

# Na seção de módulos:
[[ "${ENABLE_DOCKER}" == true ]] && run_module "Docker" "${SCRIPTS_DIR}/setup_docker.sh"
```

---

## 🔒 Segurança

- O script detecta a distro automaticamente via `/etc/os-release`
- Arquivos existentes são sempre renomeados para `.bak` antes de serem sobrescritos

---

## 📋 Distros Suportadas

| Família | Distros |
|---|---|
| **Arch** | Arch Linux, Manjaro, EndeavourOS, Garuda |
| **Debian** | Debian, Ubuntu, Linux Mint, Pop!\_OS, Elementary, Zorin |

---

## 📄 Licença

MIT — use, modifique e distribua livremente.
