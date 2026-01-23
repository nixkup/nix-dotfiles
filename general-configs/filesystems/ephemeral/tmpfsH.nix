{ config, lib, pkgs, ... }: {

  environment.persistence."/safe" = {
    enable = true;
    hideMounts = true;

    users = {
      nixkup = {
        directories = [
          ".cache"
          ".ssh"
          "Desktop"
          "Pictures"
          "Projects"
          "Videos"
          ".config"
          ".local/share"
          ".var"
          ".nix-defexpr"
          ".pki"
          ".vscode-oss"
          ".mozilla"
          ".zen"
          ".themes"
          ".icons"
          ".npm"
        ];
        files = [ 
          ".zshenv"
          ".z"
        ];
      };
    };
  };
}