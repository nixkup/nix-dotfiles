{ config, pkgs, inputs, ... }: {

  home = {
    username = "nixkup";
    homeDirectory = "/home/nixkup";
    stateVersion = "26.05";

    packages = with pkgs; [
      # fetch
      fastfetch
      hyfetch

      # coisas úteis
      tree
      mission-center
      prismlauncher
      gnome-secrets
      protonvpn-gui
      obs-studio
      lutris

      # desenvolvimento
      sqlitebrowser
      jetbrains.idea
      zed-editor

      # non-free
      vesktop
      unrar
    ];
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "nixkup";
      user.email = "nixkup@proton.me";
    };
  };

  # não estou usando mais
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "network" "pulseaudio" "tray" ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 50;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        battery = {
          format = "{capacity}% {icon}";
          format-icons = [ "" "" "" "" "" ];
        };

        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          format-disconnected = "Disconnected ⚠";
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrains Mono", "Font Awesome 6 Free";
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(191, 14, 235, 0);
        border-bottom: 2px solid rgba(255, 0, 85, 0);
      }

      #workspaces button {
        padding: 0 10px;
        color: #cdd6f4;
      }

      #workspaces button.active {
        background-color: rgba(163, 6, 211, 0.53);
        color: rgba(255, 255, 255, 1);
      }

      #clock, #network {
        padding: 0 10px;
      }
    '';
  };
}
