{
  description = "MEOW!";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    impermanence.url = "github:nix-community/impermanence";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = inputs @ {
    self,
    nix-cachyos-kernel,
    zen-browser,
    nixpkgs-stable,
    nixpkgs,
    impermanence,
    home-manager,
  }: {
    nixosConfigurations.kups = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs; };

      modules = [
        ./general-configs/system.nix # importa as configs do sistema
        ./general-configs/filesystem.nix # importa as configurações padrões de particionamento
        ./general-configs/interfaces.nix # importa as interfaces
        ./general-configs/packages/packages.nix # importa os pacotes
        ./general-configs/packages/special-pkgs.nix # importa pacotes especiais

        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = [
              nix-cachyos-kernel.overlays.pinned
            ];
          }
        )

        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs.flake-inputs = inputs;
          home-manager.users.nixkup = import ./home-manager/home.nix;
        }
      ];
    };
  };
}
