{ pkgs, username, config, ... }: {
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    ripgrep
    fd
    eza
    jq
    gh
    glab
    fnm
    colima
    docker
    docker-compose
    python3
    rustup
  ];

  programs.git = {
    enable = true;
    # Email + per-dir overrides live in ~/.config/git/identity (outside the repo).
    # See README "Identity setup" for the per-machine setup.
    settings = {
      user.name = "Marcelo Pecin";
      include.path = "~/.config/git/identity";
    };
  };

  programs.fish = {
    enable = true;
    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
    ];
    interactiveShellInit = ''
      fnm env --use-on-cd | source
    '';
    shellAliases = {
      ll = "eza -l --icons --color=always";
      ls = "eza -la --icons --color=always";
      ":q" = "exit";
      glog = "git reflog";
      gtree = "git log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)' --all";
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  home.sessionVariables = {
    EDITOR = "zed";
  };

  # Ghostty config (cask install, config managed here).
  xdg.configFile."ghostty/config".text = ''
    theme = "Gruvbox Dark Hard"
    font-family = "JetBrainsMono Nerd Font"
  '';

  # Zed config (cask install, settings managed here).
  # Read-only symlink — change requires editing this file + darwin-rebuild switch.
  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    cli_default_open_behavior = "new_window";
    restore_on_startup = "launchpad";

    edit_predictions = {
      provider = "zed";
    };
    agent = {
      flexible = false;
      dock = "bottom";
      button = false;
      sidebar_side = "right";
      enabled = false;
    };

    git_panel = {
      dock = "left";
    };
    project_panel = {
      dock = "right";
    };
    collaboration_panel = {
      button = false;
    };
    outline_panel = {
      dock = "right";
    };

    telemetry = {
      metrics = false;
      diagnostics = false;
    };

    auto_indent_on_paste = true;

    vim_mode = true;
    ui_font_size = 16;
    buffer_font_size = 16;

    terminal = {
      font_fallbacks = [ "JetBrainsMono Nerd Font Mono" ];
    };

    icon_theme = {
      mode = "system";
      light = "Catppuccin Latte";
      dark = "Catppuccin Mocha";
    };

    theme = {
      mode = "system";
      light = "Gruvbox Light Hard";
      dark = "Gruvbox Dark Hard";
    };
  };

  xdg.configFile."zed/keymap.json".text = builtins.toJSON [
    {
      context = "Workspace";
      bindings = {
        "alt-shift-c" = [ "task::Spawn" { task_name = "claude"; } ];
      };
    }
  ];

  xdg.configFile."zed/tasks.json".text = builtins.toJSON [
    {
      label = "claude";
      command = "claude";
      cwd = "\${ZED_WORKTREE_ROOT}";
      hide = "on_success";
      use_new_terminal = true;
      allow_concurrent_runs = true;
      reveal = "always";
      reveal_target = "center";
      shell = {
        program = "fish";
      };
      show_summary = false;
      show_command = false;
      tags = [ "claude" ];
    }
  ];

  programs.home-manager.enable = true;

  # Start Colima on login (launchd agent).
  # Toggle `enable` to true when you want auto-start on login.
  # `--foreground` lets launchd track the process and restart it if it dies.
  launchd.agents.colima = {
    enable = false;
    config = {
      ProgramArguments = [ "${pkgs.colima}/bin/colima" "start" "--foreground" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/.cache/colima/launchd.out.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/colima/launchd.err.log";
    };
  };
}
