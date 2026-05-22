# macOS nix config

Declarative macOS setup: nix-darwin + home-manager + Homebrew casks via flakes.

## Prerequisites

Install **before** running any `darwin-rebuild` from this repo. Nix cannot install
these for you on macOS, so they go first.

| Tool | Why |
|------|-----|
| Homebrew | nix-darwin's `homebrew` module **manages** an existing brew install (generates a Brewfile, runs `brew bundle`). It does not install brew itself. Casks are how Mac ships signed GUI apps (Firefox, Zed, Ghostty, etc.) — nixpkgs does not build them on macOS. |
| Determinate Nix | Provides the `nix` daemon. nix-darwin runs on top of it. |

## Bootstrap on a fresh Mac

```bash
# 1. Homebrew (must come BEFORE nix-darwin)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Determinate Nix
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 3. Clone repo
git clone <repo-url> ~/Developer/nix
cd ~/Developer/nix

# 4. Identity setup (local emails — see section below)
mkdir -p ~/.config/git
cat > ~/.config/git/identity <<'EOF'
[user]
  email = YOUR_PERSONAL_EMAIL@example.com

[includeIf "gitdir:~/Developer/YOUR_WORK_FOLDER/"]
  path = ~/.config/git/work-identity
EOF
cat > ~/.config/git/work-identity <<'EOF'
[user]
  email = YOUR_WORK_EMAIL@company.com
EOF

# 5. First switch
nix run nix-darwin/master#darwin-rebuild -- switch --flake .#meccin

# 6. Reopen the terminal so fish takes effect as login shell
```

> **Username**: defined in `flake.nix` as `let username = "meccin"`. Change it there and every module follows.

> ⚠️ **brew cleanup = "zap"**: the first switch removes every brew formula/cask **not listed** in `darwin/default.nix`. Add anything you still want to the `brews`/`casks` lists before running it, or change `cleanup` to `"none"` temporarily.

## Post-switch setup (one-time)

Things Nix cannot do declaratively — run after the first `darwin-rebuild switch`.

```bash
# Tide prompt (interactive wizard, writes ~/.config/fish/fish_variables)
tide configure

# Node — install LTS once, then fnm auto-switches via .node-version
fnm install --lts
fnm use --lts

# Rust toolchain
rustup default stable

# Verify git identity is loaded from ~/.config/git/identity
git config --get user.email                                  # personal (default)
cd ~/Developer/YOUR_WORK_FOLDER && git config --get user.email   # work (per includeIf)
```

Fonts: **JetBrainsMono Nerd Font** is already wired into Ghostty + Zed via `home/default.nix` (no manual selection in app preferences).

## App configs managed by Nix

- **Ghostty** (`~/.config/ghostty/config`) — theme `Gruvbox Dark Hard`, JetBrainsMono Nerd Font.
- **Zed** — three files managed:
  - `~/.config/zed/settings.json` — Gruvbox light/dark by system, Catppuccin icons, vim_mode on, telemetry off, AI panel disabled, panels arranged.
  - `~/.config/zed/keymap.json` — `alt-shift-c` spawns the `claude` task.
  - `~/.config/zed/tasks.json` — `claude` task: runs `claude` in fish at the worktree root, new terminal, center.

Zed extensions required for the icon themes (install once via Zed extensions panel):
- `Catppuccin Icons` (for the `Catppuccin Latte`/`Catppuccin Mocha` icon themes)

> Both are **read-only symlinks** to the Nix store. To change a setting, edit `home/default.nix` and run `darwin-rebuild switch`. Changes made inside Zed's settings UI will silently fail to write.

## Identity setup (emails + work folder outside the repo)

Emails and the work-folder path live in `~/.config/git/identity` (and `work-identity`), **outside** the Nix repo. `programs.git` only points to `~/.config/git/identity` via `include.path`. The conditional include for work email is defined there, not in Nix — so the company folder name never appears in this repo.

Files:

```ini
# ~/.config/git/identity
[user]
  email = your-personal@example.com

[includeIf "gitdir:~/Developer/YOUR_WORK_FOLDER/"]
  path = ~/.config/git/work-identity

# ~/.config/git/work-identity
[user]
  email = you@company.com
```

Verify:
```bash
git config --get user.email                                       # personal
cd ~/Developer/YOUR_WORK_FOLDER && git config --get user.email    # work
```

> **Why this way**: the name (`Marcelo Pecin`) is already visible in every public commit — no point hiding it. Emails are what you don't want indexed alongside the config. This keeps the repo clean without bringing in sops/agenix.

## Daily updates

```bash
cd ~/Developer/nix
nix flake update                          # bump input versions (optional)
darwin-rebuild switch --flake .#meccin    # apply
```

## Layout

| Path | Role |
|------|------|
| `flake.nix` | inputs + `let username` + darwinConfigurations |
| `darwin/default.nix` | system: macOS defaults, casks, fish login shell |
| `home/default.nix` | user: CLI packages, git, fish + tide + aliases, fzf, direnv, colima launchd agent, ghostty + zed configs |
| `.gitignore` | `result/`, `.direnv/` |

## Containers (colima)

Manual start by default — the launchd agent is declared but disabled.

```bash
colima start                # start the VM
docker run hello-world
colima stop                 # stop when not in use
```

Auto-start on login: flip `launchd.agents.colima.enable` to `true` in `home/default.nix`, then `darwin-rebuild switch`. Logs at `~/.cache/colima/launchd.{out,err}.log`.

## Languages

- **Node**: `fnm install --lts` once, then `.node-version` triggers auto-switch via fish init.
- **Python**: `python3` from nixpkgs.
- **Rust**: `rustup default stable` once; afterwards `rustup` manages toolchains per project (`rust-toolchain.toml`).
- **PHP**: handled by the **Herd** app.

## Notes

- `nix.enable = false` in the darwin module because **Determinate Nix** owns the daemon.
- Config name is `meccin` (user-based). Always run with `--flake .#meccin`.
- `flake.lock` is committed — pinned versions. `nix flake update` rewrites it.
