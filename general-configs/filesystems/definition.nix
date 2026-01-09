{ config, lib, pkgs, ... }:

# =========================
#        IMMUTABLE
#         ARCHIVE
# =========================

let  
  # btrfs | zfs | tmpfs | common
  fsBackend = "";

  # non-common
  zfsH   = false; # home zfs
  tmpfsH = false; # home tmpfs

  # common
  fsRoot = ""; # root fs
  fsHome = ""; # home fs

  users = [ "" ];

  # =========================
  #         Devices
  # =========================
  homeDevice =
    if zfsH then "home/user"
    else if tmpfsH then "none"
    else "/dev/disk/by-label/home";

  rootDevice = "/dev/disk/by-label/nixos";

  # =========================
  #        (merge)
  # =========================
  baseFileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    "/" = {
      neededForBoot = true;
    };
  };

  # =========================
  #         Backends
  # =========================
  backends = {
    btrfs = {
      "/" = {
        device  = rootDevice;
        fsType  = "btrfs";
        options = [ "noatime" "subvol=root" ];
      };

      "/nix" = {
        device  = rootDevice;
        fsType  = "btrfs";
        options = [ "noatime" "subvol=nix" ];
      };

      "/safe" = {
        device  = rootDevice;
        fsType  = "btrfs";
        neededForBoot = true;
        options = [ "noatime" "subvol=safe" ];
      };
    };

    zfs = {
      "/" = {
        device  = "nixos/system/root";
        fsType  = "zfs";
      };

      "/nix" = {
        device  = "nixos/system/nix";
        fsType  = "zfs";
      };

      "/safe" = {
        device  = "nixos/system/safe";
        fsType  = "zfs";
        neededForBoot = true;
      };
    };

    tmpfs = {
      "/" = {
        device  = "none";
        fsType  = "tmpfs";
        options = [ "defaults" "size=25%" "mode=755" ];
      };

      "/nix" = {
        device  = rootDevice;
        fsType  = "btrfs";
        options = [ "noatime" "subvol=nix" ];
      };
      
      "/safe" = {
        device  = rootDevice;
        fsType  = "btrfs";
        neededForBoot = true;
        options = [ "noatime" "subvol=safe" ];
      };
    };

    common = {
      "/" = {
        device  = rootDevice;
        fsType  = fsRoot;
        options = [ "noatime" ];
      };
    };
  };

  # =========================
  #       final merge
  # =========================
  fileSystemsConfig =
    lib.recursiveUpdate baseFileSystems backends.${fsBackend};

in
{ 
  fileSystems = fileSystemsConfig;

  # addons
  imports = [
    
    
  ];

  # filesystems
  boot = {
    supportedFilesystems = [ 
      "zfs" 
      "ext4" 
      "xfs" 
      "ntfs" 
      "btrfs"
      "f2fs"
    ];
    # protect zfs
    zfs.removeLinuxDRM = true;
  };

  # =========================
  #     Specialisations
  # =========================
  specialisation = {
    Home = {
      inheritParentConfig = true;

      configuration = {
        system.nixos.tags = [ "Home" ];

        fileSystems."/home" = {
          device  = homeDevice;
          fsType  = fsHome;
          options = [ "mode=0755" "noatime" "nofail" "x-systemd.device-timeout=5" ];
        };
      };
    };

    TempHome = {
      inheritParentConfig = true;

      configuration = {
        system.nixos.tags = [ "TempHome" ];

        fileSystems."/home" = {
          device  = "none";
          fsType  = "tmpfs";
          options = [ "size=8G" "mode=0755" ];
        };

      systemd.tmpfiles.settings = lib.genAttrs 
        (map (user: "10-home-${user}") users)
        (name: 
          let 
            user = lib.removePrefix "10-home-" name;
          in {
            "/home/${user}".d = {
              mode = "0755";
              user = user;
              group = "users";
            };
          }
        );
      };
    };
  };
}