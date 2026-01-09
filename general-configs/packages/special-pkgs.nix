{ config, lib, inputs, pkgs, ... }: {

# -------- DOCKER --------

# irei adicionar mais coisas em breve :)

  virtualisation.docker = {
    enable = false;
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

  # SSH
  services = {
    openssh = {
      enable = true;
      ports = [ 4080 ]; # porta do servidor ssh
      settings = {
        PasswordAuthentication = true; # permite login por senha
        KbdInteractiveAuthentication = false; # login interativo
        PermitRootLogin = "no"; # login no root
        AllowUsers = [ "nixkup" ];
      };
    };
    logmein-hamachi.enable = true; # hamachi
    # pipewire
    pipewire = {
      enable = true;
      pulse.enable = true; # ativa compatibilidade com pulseaudio
      jack.enable = true; # ativa compatibilidade com o jack
    };
  };

# -------- NH --------

  # habilita o nh
  programs.nh = {
    enable = true;
    clean.enable = true; # faz o trabalho do cg
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/persist/"; # localização da minha flake
  };
}