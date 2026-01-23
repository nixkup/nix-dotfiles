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

    # WMs - geral
    alacritty
    wl-clipboard
    swaybg
    waybar
    labwc

    # hyprland
    hyprshot
    hyprpaper

    # gnome
    #gnome-extension-manager
    #gnome-tweaks
    #gnome-disk-utility

    # kde plasma
    kdePackages.dolphin
    kdePackages.qtstyleplugin-kvantum

    # fonts
    adwaita-fonts

    # inputs
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".default
  ];
}
