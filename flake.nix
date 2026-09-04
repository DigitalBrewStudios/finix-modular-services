{
  description = "Support for Modular services in finix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    finix.url = "github:finix-community/finix";
  };

  outputs =
    {
      self,
      nixpkgs,
      finix,
    }:
    let
      finixSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllFinixSystems =
        f:
        nixpkgs.lib.genAttrs finixSystems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          f pkgs system
        );
    in
    {
      nixosModules.default = import ./modules/service.nix;

      checks = forAllFinixSystems (
        pkgs: system: {
          default = pkgs.testers.modularServiceCompliance {
            callReload = path: "initctl reload ${path}";
            sharedDir = ".finix-test";
            evalConfig =
              { services, ... }:
              let
                machine = finix.lib.finixSystem {
                  inherit (pkgs) lib;
                  modules = [
                    {
                      nixpkgs.pkgs = nixpkgs.lib.mkDefault pkgs;
                    }
                    {
                      system.services = services;
                    }
                    self.nixosModules.default
                  ];
                };
              in
              {
                config = machine.config.system.services;
                checkDrv = machine.config.system.build.toplevel;
              };
            mkTest =
              {
                name,
                services,
                testExe,
              }:
              finix.lib.mkTest {
                inherit name;
                nodes.machine = {
                  imports = [ self.nixosModules.default ];
                  system.services = services;
                };
                testScript = ''
                  machine.wait_for_condition("service/syslogd/ready")
                  machine.succeed("${testExe}")
                '';
              };
          };
        }
      );
    };
}
