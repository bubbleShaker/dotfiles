# dotfiles

Ubuntu / WSL 用の設定ファイル。

## セットアップ

```bash
sudo apt update && sudo apt install -y git curl
git clone https://github.com/bubbleShaker/dotfiles ~/ghq/github.com/bubbleShaker/dotfiles
~/ghq/github.com/bubbleShaker/dotfiles/install.sh
```

設定だけ反映し直すときは `./install.sh --links-only`。既存のファイルは `~/.dotfiles-backup/<日時>/` に退避されます。

## 中身

| ファイル | 反映先 | 内容 |
|---|---|---|
| `home/.zshrc` | `~/.zshrc` | Oh My Zsh、プロンプト、`gitcd` (ghq + fzf) |
| `home/.bashrc` | `~/.bashrc` | Ubuntu 標準 + `gitcd` |
| `home/.gitconfig` | `~/.gitconfig` | gh 認証、ghq の root、コミット用の名前とメール |
| `config/herdr/config.toml` | `~/.config/herdr/config.toml` | herdr (テーマ dracula、既定シェル zsh) |
| `config/gtk-4.0/gtk.css` | `~/.config/gtk-4.0/gtk.css` | ターミナルの余白 35px (WSL では使わない) |
| `config/Code/User/settings.json` | `~/.config/Code/User/settings.json` | VS Code (フォント Ubuntu Mono) (WSL では使わない) |
| `dconf/ptyxis.ini` | dconf `/org/gnome/Ptyxis/` | Ptyxis の不透明度 0.9 など (WSL では使わない) |
| `claude/statusline.py` | `~/.claude/statusline.py` | Claude Code のステータスライン |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code の設定 (無いときだけコピー) |

`install.sh` はさらに zsh, gh, Oh My Zsh とプラグイン, fzf, ghq, gitui, Claude Code, herdr をインストールします (入っているものはスキップ)。

## 設定を変えたとき

- 普通のファイル: リンクなのでそのまま `git commit` するだけ
- Ptyxis: `dconf dump /org/gnome/Ptyxis/ | grep -v '^window-size=' > dconf/ptyxis.ini`
- Claude Code: `~/.claude/settings.json` の変更を `claude/settings.json` に手で反映 (`hooks` は herdr が生成するので含めない)

## 別途必要なこと

- `gh auth login`
