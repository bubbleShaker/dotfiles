#!/usr/bin/env bash
# dotfiles セットアップ (Ubuntu / WSL)
#   ./install.sh               パッケージ・ツールのインストール + 設定の反映
#   ./install.sh --links-only  設定の反映 (シンボリックリンク・dconf・Claude 設定) のみ
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"

log() { printf '\033[36m==> %s\033[0m\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

case "$(uname -m)" in
  x86_64)        ARCH_GO=amd64; ARCH_RS=x86_64 ;;
  aarch64|arm64) ARCH_GO=arm64; ARCH_RS=aarch64 ;;
  *) echo "未対応のアーキテクチャ: $(uname -m)" >&2; exit 1 ;;
esac

# GitHub の最新リリースのタグ (v 付き) を返す
latest_tag() {
  curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/##'
}

install_packages() {
  log "apt パッケージ"
  local pkgs=(zsh git gh curl unzip python3 pulseaudio-utils)
  is_wsl || pkgs+=(ibus-mozc)
  sudo apt update
  sudo apt install -y "${pkgs[@]}"
}

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  local plugins="$HOME/.oh-my-zsh/custom/plugins"
  for p in zsh-autosuggestions zsh-syntax-highlighting; do
    [ -d "$plugins/$p" ] || git clone --depth 1 "https://github.com/zsh-users/$p" "$plugins/$p"
  done
}

install_tools() {
  mkdir -p "$BIN"
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  if ! has fzf; then
    log "fzf"
    local v; v="$(latest_tag junegunn/fzf)"
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/$v/fzf-${v#v}-linux_$ARCH_GO.tar.gz" | tar -xz -C "$BIN" fzf
  fi
  if ! has ghq; then
    log "ghq"
    curl -fsSLo "$tmp/ghq.zip" "https://github.com/x-motemen/ghq/releases/latest/download/ghq_linux_$ARCH_GO.zip"
    unzip -qo "$tmp/ghq.zip" -d "$tmp"
    install -m 755 "$tmp/ghq_linux_$ARCH_GO/ghq" "$BIN/ghq"
  fi
  if ! has gitui; then
    log "gitui"
    curl -fsSL "https://github.com/gitui-org/gitui/releases/latest/download/gitui-linux-$ARCH_RS.tar.gz" | tar -xz -C "$BIN" ./gitui
  fi
  if ! has claude; then
    log "Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  if ! has herdr; then
    log "herdr"
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
}

# $1 (リポジトリ内) を $2 にシンボリックリンク。既存ファイルは $BACKUP に退避
link() {
  local src="$DOTFILES/$1" dst="$2"
  [ "$(readlink "$dst" 2>/dev/null)" = "$src" ] && return
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/"
    echo "  退避: $dst -> $BACKUP/"
  fi
  ln -s "$src" "$dst"
  echo "  リンク: $dst"
}

apply_configs() {
  log "設定ファイルのリンク"
  link home/.zshrc              "$HOME/.zshrc"
  link home/.bashrc             "$HOME/.bashrc"
  link home/.gitconfig          "$HOME/.gitconfig"
  link config/herdr/config.toml "$HOME/.config/herdr/config.toml"
  link claude/statusline.py     "$HOME/.claude/statusline.py"
  if ! is_wsl; then
    link config/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css"
  fi

  # Claude Code は settings.json を自分で書き換えるので、リンクではなく初回のみコピー
  if [ ! -e "$HOME/.claude/settings.json" ]; then
    log "Claude Code の設定"
    cp "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
  fi
  if has herdr; then
    herdr integration install claude || true
  fi

  if ! is_wsl && has dconf; then
    log "Ptyxis の設定 (dconf)"
    dconf load /org/gnome/Ptyxis/ < "$DOTFILES/dconf/ptyxis.ini"
  fi
}

set_login_shell() {
  if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
    log "ログインシェルを zsh に変更"
    chsh -s "$(command -v zsh)"
  fi
}

export PATH="$BIN:$PATH"
if [ "${1:-}" != "--links-only" ]; then
  install_packages
  install_oh_my_zsh
  install_tools
fi
apply_configs
[ "${1:-}" = "--links-only" ] || set_login_shell
log "完了。ターミナルを開き直してください"
