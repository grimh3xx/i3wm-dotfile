# ═══════════════════════════════════════════════════════════════
#  UNDERGROUND // zsh
# ═══════════════════════════════════════════════════════════════

# ── history ────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_reduce_blanks
setopt extended_history       # salva data/duração de cada comando
setopt hist_ignore_space      # comando começando com espaço não vai pro histórico
setopt hist_verify            # !! / !$ mostram o comando antes de rodar
setopt autocd interactive_comments
setopt auto_pushd pushd_ignore_dups pushd_silent   # cd -<Tab> lista pastas recentes
setopt no_beep

# ── env ────────────────────────────────────────────────────────
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export LESS='-R --mouse -i'   # cores, scroll com mouse, busca case-insensitive

# ── cores (ls / eza / completions) ─────────────────────────────
command -v dircolors >/dev/null && eval "$(dircolors -b)"
# pastas=ciano · exec=verde forte · aviso (world-writable/setuid/sticky)=amarelo · erro (link quebrado)=vermelho
export LS_COLORS="${LS_COLORS}:di=1;36:ex=1;92:or=1;31:mi=1;31:su=1;33:sg=1;33:ca=1;33:ow=1;33:tw=1;33:st=1;33:pi=1;33:so=1;33:bd=1;33:cd=1;33"
# eza: pastas ciano · erro=vermelho · especiais/setuid=amarelo (aviso); bits de exec (x) nas permissões em cinza
export EZA_COLORS="di=1;36:or=1;31:su=1;33:sg=1;33:pi=1;33:so=1;33:bd=1;33:cd=1;33:ux=1;90:gx=1;90:tx=1;90:ue=1;90"

# ── completion ─────────────────────────────────────────────────
autoload -Uz compinit
# só reconstrói o cache de completions 1x por dia (shell abre mais rápido)
if [[ -n ~/.zcompdump(N.mh+24) || ! -f ~/.zcompdump ]]; then compinit; else compinit -C; fi
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}nada encontrado%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── keybinds ───────────────────────────────────────────────────
bindkey -e
# ↑/↓ buscam no histórico pelo que já foi digitado (cursor vai pro fim)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
# Home / End / Delete
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char
# Ctrl+←/→ pula palavra · Ctrl+Backspace / Ctrl+Del apagam palavra
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^H'      backward-kill-word
bindkey '^[[3;5~' kill-word
# Ctrl+X Ctrl+E abre o comando atual no nano
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey '^X^E' edit-command-line

# ── aliases ────────────────────────────────────────────────────
if command -v eza >/dev/null; then
    alias ls='eza --icons=auto --group-directories-first'
    alias ll='eza -lah --icons=auto --group-directories-first'
    alias la='eza -a --icons=auto --group-directories-first'
    alias lt='eza --tree --icons=auto --level=2'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lah'
    alias la='ls -A'
fi
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
command -v bat >/dev/null && alias cat='bat --style=plain --paging=never'
alias open='xdg-open'
alias ff="~/.config/fastfetch/logo.sh"
alias cfg='cd ~/.config'
alias please='sudo $(fc -ln -1)'          # rerun last cmd with sudo
alias reload='exec zsh'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='ss -tulpn'
alias myip='curl -s ifconfig.me; echo'

# ── funções ────────────────────────────────────────────────────
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }   # cria pasta e entra

# `sudo nano arquivo` vira `sudoedit arquivo`: usa TUA config do nano
# (roda o nano como teu usuário e só grava como root no final)
sudo() {
    if [[ $1 == nano && $# -gt 1 ]]; then
        shift
        command sudoedit "$@"
    else
        command sudo "$@"
    fi
}

# extract <arquivo> — descompacta qualquer formato comum
extract() {
    [[ -f $1 ]] || { echo "extract: '$1' não é um arquivo"; return 1; }
    case $1 in
        *.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst|*.tar) tar xvf "$1" ;;
        *.gz)  gunzip "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.xz)  unxz "$1" ;;
        *.zst) unzstd "$1" ;;
        *.zip) unzip "$1" ;;
        *.7z)  7z x "$1" ;;
        *.rar) unrar x "$1" ;;
        *)     echo "extract: formato desconhecido: $1"; return 1 ;;
    esac
}

# pacman / yay shortcuts
alias pacin='sudo pacman -S'
alias pacup='sudo pacman -Syu'
alias pacrm='sudo pacman -Rns'
alias pacss='pacman -Ss'

# git shortcuts
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'

# ── tools: fzf + zoxide ────────────────────────────────────────
# (sem zsh-autosuggestions de propósito — nada aparece enquanto você digita)

# fzf — Ctrl+R (histórico) · Ctrl+T (arquivos) · Alt+C (cd). Só filtra quando você chama.
if command -v fzf >/dev/null; then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    else
        [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
        [ -f /usr/share/fzf/completion.zsh ]  && source /usr/share/fzf/completion.zsh
    fi
fi

# zoxide — cd inteligente: `z <pasta>` pula pras pastas mais usadas
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ── greeting ───────────────────────────────────────────────────
command -v fastfetch >/dev/null && ~/.config/fastfetch/logo.sh

# ── prompt ─────────────────────────────────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
command -v starship >/dev/null && eval "$(starship init zsh)"

# ── syntax highlighting (precisa ser a ÚLTIMA coisa carregada) ──
# colore o comando enquanto digita: verde = existe, vermelho = não existe
SYN="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$SYN" ] && source "$SYN"
