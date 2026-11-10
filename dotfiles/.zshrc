# ═══════════════════════════════════════════════════════════════
#  UNDERGROUND // zsh
# ═══════════════════════════════════════════════════════════════

# ── history ────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_reduce_blanks
setopt extended_history       # store date/duration of each command
setopt hist_ignore_space      # commands starting with a space stay out of history
setopt hist_verify            # !! / !$ show the command before running it
setopt autocd interactive_comments
setopt auto_pushd pushd_ignore_dups pushd_silent   # cd -<Tab> lists recent dirs
setopt no_beep

# ── env ────────────────────────────────────────────────────────
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export LESS='-R --mouse -i'   # colors, mouse scroll, case-insensitive search

# ── colors (ls / eza / completions) ────────────────────────────
command -v dircolors >/dev/null && eval "$(dircolors -b)"
# dirs=cyan · exec=bright green · warnings (world-writable/setuid/sticky)=yellow · errors (broken link)=red
export LS_COLORS="${LS_COLORS}:di=1;36:ex=1;92:or=1;31:mi=1;31:su=1;33:sg=1;33:ca=1;33:ow=1;33:tw=1;33:st=1;33:pi=1;33:so=1;33:bd=1;33:cd=1;33"
# eza: dirs cyan · errors red · special/setuid yellow (warning); exec bits (x) in gray
export EZA_COLORS="di=1;36:or=1;31:su=1;33:sg=1;33:pi=1;33:so=1;33:bd=1;33:cd=1;33:ux=1;90:gx=1;90:tx=1;90:ue=1;90"

# ── completion ─────────────────────────────────────────────────
autoload -Uz compinit
# rebuild the completion cache once a day (faster shell startup)
if [[ -n ~/.zcompdump(N.mh+24) || ! -f ~/.zcompdump ]]; then compinit; else compinit -C; fi
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── keybinds ───────────────────────────────────────────────────
bindkey -e
# ↑/↓ search history for what you typed so far (cursor goes to the end)
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
# Ctrl+←/→ jump word · Ctrl+Backspace / Ctrl+Del delete word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^H'      backward-kill-word
bindkey '^[[3;5~' kill-word
# Ctrl+X Ctrl+E edits the current command in nano
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

# ── functions ──────────────────────────────────────────────────
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }   # create dir and cd into it

# `sudo nano file` becomes `sudoedit file`: uses YOUR nano config
# (nano runs as your user, only the final write happens as root)
sudo() {
    if [[ $1 == nano && $# -gt 1 ]]; then
        shift
        command sudoedit "$@"
    else
        command sudo "$@"
    fi
}

# extract <file> — unpacks any common archive format
extract() {
    [[ -f $1 ]] || { echo "extract: '$1' is not a file"; return 1; }
    case $1 in
        *.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst|*.tar) tar xvf "$1" ;;
        *.gz)  gunzip "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.xz)  unxz "$1" ;;
        *.zst) unzstd "$1" ;;
        *.zip) unzip "$1" ;;
        *.7z)  7z x "$1" ;;
        *.rar) unrar x "$1" ;;
        *)     echo "extract: unknown format: $1"; return 1 ;;
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
# (no zsh-autosuggestions on purpose — nothing pops up while you type)

# fzf — Ctrl+R (history) · Ctrl+T (files) · Alt+C (cd). Only filters when you ask.
if command -v fzf >/dev/null; then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    else
        [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
        [ -f /usr/share/fzf/completion.zsh ]  && source /usr/share/fzf/completion.zsh
    fi
fi

# zoxide — smart cd: `z <dir>` jumps to your most used dirs
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ── greeting ───────────────────────────────────────────────────
command -v fastfetch >/dev/null && ~/.config/fastfetch/logo.sh

# ── prompt ─────────────────────────────────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
command -v starship >/dev/null && eval "$(starship init zsh)"

# ── syntax highlighting (must be the LAST thing loaded) ──
# colors the command while you type: green = exists, red = does not
SYN="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$SYN" ] && source "$SYN"
