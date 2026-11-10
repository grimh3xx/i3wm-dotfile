# ~/.local/bin on PATH in every session (st and the i3wm-dotfile scripts live there)
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"
