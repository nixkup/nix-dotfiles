{ config, lib, pkgs, inputs, ... }: {

# -------- SYSTEM --------

  environment.systemPackages = with pkgs; [
    # coisas úteis
    usbutils
    wget
    gparted
    haguichi
    cryptsetup

    # desenvolvimento
    pipenv
    python314
    rustc
    nodejs
    devspace
    javaPackages.compiler.openjdk25
    docker-compose

    # WMs - geral
    alacritty
    wl-clipboard
    swaybg
    waybar
    labwc
    xdg-utils
    wlr-randr
    wofi
    xwayland-satellite

    # hyprland
    hyprshot
    hyprpaper

    # gnome
    #gnome-extension-manager
    #gnome-tweaks
    #gnome-disk-utility

    # kde plasma
    kdePackages.qtstyleplugin-kvantum

    # fonts
    adwaita-fonts

    # kubernetes
    kompose
    kubectl
    kubernetes
    cfssl

    # cria um binário "sudo" para o doas
    (pkgs.writeScriptBin "sudo" ''
        #!${pkgs.stdenv.shell}
        exec doas "$@"
    '')

    # inputs
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".default
  ];
}
