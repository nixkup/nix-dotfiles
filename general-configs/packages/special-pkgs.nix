{ config, lib, vars, inputs, pkgs, ... }:
let
#  kubeMasterIP = "127.0.0.1";
#  kubeMasterHostname = "api.kube";
#  kubeMasterAPIServerPort = 6443;
in
{

# -------- DOCKER --------

  virtualisation.docker = {
    enable = true;

    daemon.settings = {
      experimental = true;

      default-address-pools = [
        {
        base = "172.30.0.0/16"; # define os ips dos containers
        size = 24; # pode ser dividido em 24 ips
        }
      ];
    };
  };

# -------- SERVICES --------

  services = {
    #opensnitch.enable = true;
    flatpak.enable = true;
    logmein-hamachi.enable = true;

    openssh = {
      enable = true;
      ports = [ 22 ]; # porta do servidor ssh

      settings = {
        PasswordAuthentication = true; # permite login por senha
        KbdInteractiveAuthentication = false; # login interativo
        PermitRootLogin = "no"; # login no root
        AllowUsers = [ "${vars.user}" ];
      };
    };

    pipewire = {
      enable = true;
      pulse.enable = true; # ativa compatibilidade com pulseaudio
      jack.enable = true; # ativa compatibilidade com o jack
    };

    #kubernetes = {
    #  masterAddress = kubeMasterHostname;
    #  apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    #  easyCerts = true;
    #  addons.dns.enable = true;
    #  kubelet.extraOpts = "--fail-swap-on=false";

    #  apiserver = {
    #    securePort = kubeMasterAPIServerPort;
    #    advertiseAddress = kubeMasterIP;
    #  };

    #  roles = [
    #    "master"
    #    "node"
    #  ];

    #  pki = {
    #    enable = true;
    #    etcClusterAdminKubeconfig = "kubernetes/cluster-admin.kubeconfig";
    #  };
    #};
  };

# -------- PROGRAMS --------

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        # general
        u         = "cd ..";
        l         = "ls -l";
        la        = "ls -la";
        c         = "clear";

        # filesystem
        zfreeze   = "doas zfs snapshot";
        bfreeze   = "doas btrfs subvolume snapshot";
        lfreeze   = "doas lvcreate -L 1G -s -n";
        lusage    = "doas lvs -a -o +lv_size,data_percent";
        ladd      = "doas lvresize -L";
        reflink   = "cp --reflink=always";

        # nixos - meu NH caseiro
        pkg       = "nix shell";
        switch    = "doas nixos-rebuild switch --flake --specialisation TempHome";
        update    = "switch --upgrade";
        fupdate   = "nix flake update";
        allupdate = "fupdate && update";
        mypc = "fastfetch";
      };

      ohMyZsh = {
        enable = true;
        plugins = [ "git" "z" ];
        theme = "robbyrussell";
      };

      histSize = 10000;
      histFile = "$HOME/.zsh_history";

      setOptions = [
        "HIST_IGNORE_ALL_DUPS"
      ];
    };

    nh = {
      enable = true;
      clean.enable = true; # faz o trabalho do cg
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${vars.user}/config"; # localização da minha flake
    };
  };
}
