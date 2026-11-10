<div align="center">

<img src="docs/banner.svg" alt="UndergroundI3" width="100%">

**Rice de i3wm underground pro Arch Linux, instalado com um script**
i3 puro · st suckless com patches · rofi · i3blocks · bash puro, sem dependências

[![build](https://img.shields.io/github/actions/workflow/status/grimh3xx/UndergroundI3/build.yml?branch=main&style=flat-square&labelColor=111826&label=build)](https://github.com/grimh3xx/UndergroundI3/actions)
[![release](https://img.shields.io/github/v/release/grimh3xx/UndergroundI3?style=flat-square&labelColor=111826&color=3B82F6)](https://github.com/grimh3xx/UndergroundI3/releases/latest)
[![license](https://img.shields.io/github/license/grimh3xx/UndergroundI3?style=flat-square&labelColor=111826&color=22D3EE)](LICENSE)
![platform](https://img.shields.io/badge/platform-Arch%20Linux-3B82F6?style=flat-square&labelColor=111826)
![wm](https://img.shields.io/badge/wm-i3-22D3EE?style=flat-square&labelColor=111826)
![bash](https://img.shields.io/badge/bash-shellcheck%20clean-3B82F6?style=flat-square&labelColor=111826)

`grimh3xx` · [github.com/grimh3xx](https://github.com/grimh3xx)

</div>

<p align="center"><img src="docs/demo.svg" alt="underground-i3 demo" width="100%"></p>

---

Um setup de i3 **sem frescura**: sem polybar, sem blur, sem animação, sem canto arredondado. Fundo quase preto, azul Arch, borda fina e tudo no terminal.
Um script em bash instala tudo. Você escolhe os componentes com **espaço** e confirma com **enter**. Ele mostra o plano antes de mexer, faz **backup de tudo que substitui** e desfaz qualquer execução.

## O que vem

- **i3**: Alt como mod, teclas do vim, gaps pequenos que somem com uma janela só, workspaces em kanji 一 二 三, apps fixos por workspace e janelas sem foco escurecidas pelo picom.
- **st (suckless)**: compilado do código com 8 patches: scrollback (com mouse), boxdraw, ícones largos de Nerd Font, cores do Xresources com reload, clipboard, `Ctrl+Shift+Enter` (terminal novo na mesma pasta) e `Ctrl+Shift+U` (abrir links). Vai pro `~/.local`, sem root.
- **Barra (i3blocks)**:
  - frase do Anonymous (2011) rodando
  - música tocando, rede, disco, RAM
  - CPU (uso e temperatura), GPU NVIDIA (uso, temperatura e VRAM)
  - caffeine, microfone, CAPS/NUM
  - volume (scroll e clique) e relógio (clique abre o calendário)
- **Dropdowns**: uma tecla mostra/esconde um app de terminal flutuando: Claude Code, btop, notas, lf, ncspot (Spotify), cava, weechat (IRC), newsboat (RSS).
- **rofi**:
  - busca única de apps, janelas abertas e comandos
  - calculadora, emoji, histórico do clipboard (greenclip)
  - busca na web com prefixos
  - seletor de wallpaper com miniatura
  - menu de energia, saída de áudio e lista de atalhos pesquisável
- **Lock**: print pixelado com *expect us.* Trava sozinho aos 8 min e apaga a tela aos 10.
- **fastfetch**: layout em árvore com logo sorteado (máscara do Anonymous / Linus / fsociety) em blocos Unicode via chafa, que funciona no st.
- **Shell**: zsh com prompt starship de uma linha (`user@host ~ $`), fzf, zoxide, eza e bat.
- **Tudo com a mesma paleta**: dunst, rofi, tmux, zathura, newsboat, ncspot, cava, mpv, lf e weechat usam `#101014` · `#1793d1` · `#22c7d8` · `#e06c75`.
- **Hardware**:
  - detecta a resolução nativa e a maior taxa do monitor
  - liga o G-Sync compatível na NVIDIA
  - acha o sensor da CPU sozinho (k10temp / zenpower / coretemp)

## Segurança do instalador

- `--dry-run` mostra cada pacote, arquivo e comando **sem mudar nada**.
- Todo arquivo substituído vai antes pra `~/.local/state/underground-i3/backups/<execução>/`. O `restore` desfaz a execução inteira, inclusive apagando o que ela criou.
- Idempotente: rodar de novo só mexe no que falta ou mudou.
- Nunca roda como root: o `sudo` é só pro `pacman`, e o AUR compila como o seu usuário.
- Log em `~/.local/state/underground-i3/underground-i3.log`.

## Instalar

```bash
sudo pacman -S --needed git
git clone https://github.com/grimh3xx/UndergroundI3 && cd UndergroundI3

./underground-i3 --dry-run    # mostra o plano, não muda nada
./underground-i3              # instalador interativo
```

| Tela | Teclas |
|------|--------|
| **Componentes** | `↑ ↓` / `j k` mover · `espaço` marcar · `a` todos · `↵` confirmar · `q` sair |
| **Dotfiles** | `↑ ↓` escolher entre **symlink** (o `git pull` atualiza tudo) e **cópia** · `↵` |
| **Plano** | `↵` instalar · `q` cancelar |

Depois é só sair da sessão e escolher **i3** no SDDM/LightDM/ly, ou colocar `exec i3` no `~/.xinitrc` e rodar `startx`.

### Sem menu (scripts / CI)

```text
underground-i3 [opções] [comando]

  install [minimal|full]     minimal = core + st + dotfiles + wallpaper
                             full    = minimal + apps de terminal + AUR + logos
  packages [SET...]          core apps aur nvidia | all
  dotfiles                   só as configs (symlink ou cópia, com backup)
  st                         compila e instala o st com os patches
  assets                     logos do fastfetch + wallpaper padrão
  doctor                     confere a instalação (só leitura)
  restore [ID|latest]        desfaz uma execução   (restore --list lista)

  -n, --dry-run   -y, --yes   -c, --copy   --no-color   -V   -h
```

`make install` coloca o comando no `PATH` (`~/.local/bin/underground-i3`).

## Atalhos

`Alt` é o mod. **`Alt+/`** abre a lista de todos os atalhos, e o `↵` executa o escolhido.

| Teclas | Ação |
|------|--------|
| `Alt+↵` | st · `Alt+Shift+↵` kitty · `Alt+Ctrl+↵` st + tmux |
| `Alt+d` | busca apps, janelas e comandos |
| `Alt+o` | busca na web (`g` google · `aw` arch wiki · `aur` · `yt` · `gh` · `w` wikipedia · sem prefixo = duckduckgo) |
| `Alt+=` | calculadora (`10 usd to brl`, `5 km to mi`…) · `Alt+.` emoji |
| `Alt+v` | histórico do clipboard · `Alt+Shift+v` limpa |
| `Alt+c` · `t` · `n` | dropdown: Claude Code · btop · notas |
| `Alt+e` · `m` · `Shift+m` | dropdown: lf · ncspot · cava |
| `Alt+i` · `Shift+n` | dropdown: weechat · newsboat |
| `Alt+p` | saída de áudio (fone, caixa, HDMI…) · `Alt+Shift+a` muta o mic |
| `Alt+Shift+s` | print com anotação (flameshot) · `Print` tela inteira · `Shift+Print` área |
| `Alt+Shift+w` | seletor de wallpaper |
| `Alt+Esc` | trava · `Alt+Shift+e` menu de energia |
| `Alt+Shift+Tab` | primeiro workspace vazio (`Alt+Ctrl+Tab` leva a janela junto) |
| `Alt+h j k l` | foco · `+Shift` move · `Alt+r` modo resize |
| `Alt+b` · `Alt+Shift+b` | split horizontal · vertical · `Alt+s` pilha · `Alt+w` abas · `Alt+x` alterna |
| `Alt+f` · `Alt+Espaço` · `Alt+g` | tela cheia · flutuar · gaps |
| `Alt+1..0` | workspace · `+Shift` move a janela |
| `Alt+Shift+x` · `Alt+Shift+r` | recarrega · reinicia o i3 |

Workspaces: **1** terminal · **2** navegador · **3** chat · **4** arquivos · **5** jogos · **6** Spotify.

> Com Alt de mod, o i3 "rouba" o `Alt+tecla` dos apps (ex.: `Alt+1..9` do weechat; lá use `Ctrl+n`/`Ctrl+p`).
> Prefere o Super? Troque `set $mod Mod1` por `Mod4` no `~/.config/i3/config`.

## Estrutura

```
underground-i3        script principal (instalador interativo + comandos)
lib/
  common.sh           cores, log, dry-run, perguntas
  tui.sh              cards interativos (checklist / radio) em bash puro
  backup.sh           backup por execução + restore
  dotfiles.sh         symlink ou cópia, arquivo por arquivo
  packages.sh         pacman + paru/yay (AUR como usuário)
  st.sh               baixa o st 0.9.2, aplica o patch, compila em ~/.local
  assets.sh           logos do fastfetch + wallpaper gerado
  doctor.sh           checagem da instalação
packages/             core.txt · apps.txt · aur.txt · nvidia.txt
dotfiles/             espelho do $HOME (.config/i3, i3blocks, rofi, dunst-i3, picom-i3, fastfetch…)
st/                   st-underground-0.9.2.diff (todos os patches) · config.h · st-urls
assets/               logo.ans (grimh3xx em pixel art) · logos/anon.png (CC BY-SA 4.0)
tools/
  gen_logo.py         gera o assets/logo.ans a partir do logo_grid.png
  gen_banner.py       gera o docs/banner.svg
  record_demo.py      grava o docs/demo.svg rodando o instalador de verdade
tests/run.sh          testes num $HOME descartável
```

## Notas

- **Spotify** (`Alt+m`) usa o [ncspot](https://github.com/hrkfdn/ncspot), que precisa de **Spotify Premium**. Sem Premium, instale o `spotify-launcher`, que abre no workspace 6.
- **Claude Code** (`Alt+c`) precisa do `claude` no `PATH`.
- **Logos do Linus e do fsociety** têm direitos autorais e **não estão no repo**. O `underground-i3 assets` pergunta antes de baixar, pra uso pessoal. Veja [assets/logos/CREDITS.md](assets/logos/CREDITS.md).
- **Monitor:** pra forçar, use `UG_OUTPUT=DP-2` e/ou `UG_MODE=2560x1440` no `~/.xprofile`.

## Desenvolvimento

```sh
make lint       # shellcheck em tudo
make test       # instala/restaura num $HOME temporário (35+ checagens)
make dry-run    # o que o "install full" faria
```

Pra regravar o demo: `pip install pyte fonttools brotli && python3 tools/record_demo.py docs/demo.svg`.

## Créditos

[i3](https://i3wm.org) · [st](https://st.suckless.org) e os autores dos patches · [rofi](https://github.com/davatorium/rofi) · [i3blocks](https://github.com/vivien/i3blocks) · [fastfetch](https://github.com/fastfetch-cli/fastfetch) · [chafa](https://hpjansson.org/chafa/) · máscara por nacreouss ([CC BY-SA 4.0](https://commons.wikimedia.org/wiki/File:Guy_fawkes_mask_by_nacreouss-d462juf.png)).

Licença [MIT](LICENSE). O st e os patches mantêm a licença MIT/X deles.

---

<div align="center">
<sub><code>[anon]</code> we do not forgive. we do not forget. <b>expect us.</b></sub><br>
<sub>© grimh3xx — <a href="https://github.com/grimh3xx">github.com/grimh3xx</a></sub>
</div>
