# ~/.local/bin no PATH em qualquer sessão (st e scripts do UndergroundI3 moram lá)
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"
