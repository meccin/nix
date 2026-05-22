{ pkgs, username, ... }: {
  # Determinate Nix manages the daemon; don't let nix-darwin touch it.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required by `system.defaults` on macOS Sequoia+.
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  # Enables fish at /etc/shells so it can be a login shell.
  programs.fish.enable = true;

  # Homebrew casks (requires brew already installed at /opt/homebrew).
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    brews = [
      "rtk"
    ];
    casks = [
      "cleanshot"
      "firefox"
      "ghostty"
      "zed"
      "tablepro"
      "handy"
      "herd"
      "font-jetbrains-mono-nerd-font"
    ];
  };

  system.defaults = {
    finder = {
      ShowPathbar = true;
    };
    dock = {
      autohide = true;
      show-recents = false;
    };
  };

  system.stateVersion = 7;
}
