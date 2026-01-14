{ config, pkgs, inputs, ... }: {

  home = {
    username = "nixkup";
    homeDirectory = "/home/nixkup";
    stateVersion = "26.05";
    packages = with pkgs; [
      tree
      vesktop
      mission-center
      prismlauncher
      vscodium
      gnome-secrets
      jetbrains.idea
      protonvpn-gui
      obs-studio
    ];
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "nixkup";
      user.email = "nixkup@proton.me";
    };
  };
}
