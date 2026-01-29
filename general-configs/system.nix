{ config, lib, vars, pkgs, modulesPath, ... }:
let
  #kubeMasterIP = "127.0.0.1";
  #kubeMasterHostname = "api.kube";
in
{

# -------- NIXOS --------

  # define e configura options do boot
  boot = {
    loader.systemd-boot.enable = true;
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-lts-lto;
    zfs.package = config.boot.kernelPackages.zfs_cachyos;

    kernelModules = [ # modulos do kernel
      "kvm-amd"
      "hid_playstation"
      "hid_sony"
      "uinput"
    ];

    kernelParams = [
      "idle=poll" # pode reduzir latencia
      "amd_pstate=active" # o hardware controla
      # "isolcpus=<cpus>" # isola cores.
    ];

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];

      kernelModules = [
        "dm-snapshot"
      ];
    };
  };

  # options do networking
  networking = {
    hostName = "kups"; # configura o hostname
    hostId = "8bec9fba"; # configura o hostId para o zfs
    networkmanager.enable = true; # usa o networkmanager
    useDHCP = lib.mkDefault true; # usa o DHCP
    #extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

    firewall = {
      enable = false;

      allowedUDPPortRanges = [
        { from = 4220; to = 19132; }
      ];

      allowedTCPPortRanges = [
        { from = 22; to = 9090; }
        { from = 4580; to = 80; }
      ];
    };
  };

  nix = {
    optimise = { # otimiza o /nix/store trocando arquivos duplicados por hardlinks
      automatic = true;
      dates = [ "daily" ]; # otimiza diariamente
    };

    gc = { # chama o caminhão de lixo pro nix
      automatic = false;
      dates = [ "weekly" ]; # chama semanalmente
    };

    settings = { # configura o uso de várias threads
      max-jobs = "auto"; # usa todos os cores
      cores = 0; # distribui a carga
      experimental-features = [ "nix-command" "flakes" ]; # experimental
      #substituters = [ "https://attic.xuyh0120.win/lantian" ];
      #trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
    };
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux"; # faz o nixpkgs seguir a arch da CPU
    config.allowUnfree = true; # permite pacotes unfree
  };

  # timezone
  time = {
    timeZone = "America/Sao_Paulo";
  };

  # versão no qual a primeira build foi feita!
  system = {
    stateVersion = "26.05";
  };

# -------- USERS --------

  users.users = {
    ${vars.user} = {
      isNormalUser = true;
      createHome = true;
      home = "/home/${vars.user}";
      hashedPasswordFile = "/nix/passwords/${vars.user}";
      shell = pkgs.zsh;

      extraGroups = [
        "wheel"
        "networkmanager"
        "vboxusers"
        "docker"
      ];
    };
  };

# -------- SECURITY --------

  security = {
    sudo.enable = false;
    rtkit.enable = false;

    doas = {
      enable = true;
      extraRules = [{
        users = [ vars.user ];
        keepEnv = true;
        persist = true;
      }];
    };
  };

# -------- HARDWARE --------

  # define o perfil de energia como performace
  powerManagement = {
    cpuFreqGovernor = "performance";
  };

  # habilita zram
  zramSwap = {
    enable = true;
    memoryPercent = 75;
    algorithm = "lz4";
    priority = 5; # preferencia pela zram
  };

  hardware = {
    amdgpu.opencl.enable = true;

    cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true; # inicia o bluetooth no boot

      settings.General = {
        ControllerMode = "bredr";
        Experimental = true; # mostra mais informações sobre o dispositivo
      };
    };
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix") # importa configurações de hardware não detectadas
  ];
}
