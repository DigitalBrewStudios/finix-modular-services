{
  config,
  lib,
  pkgs,
  ...
}:

let
  portable-lib = lib.services;
  modularServiceConfiguration = portable-lib.configure {
    baseModules = [
      (lib.modules.importApply "${pkgs.path}/lib/services/service.nix" { inherit pkgs; })
    ];
    extraRootModules = [
      ./finit/service.nix
    ];
  };

  makeServices =
    prefixes: service:
    lib.concatMapAttrs (
      name: module:
      let
        label = if name == "" then prefixes else prefixes ++ [ name ];
      in
      {
        "${lib.concatStringsSep "-" label}" =
          { ... }:
          {
            imports = [ module ];
          };
      }
    ) service.finit.services
    // lib.concatMapAttrs (
      subServiceName: subService: makeServices (prefixes ++ [ subServiceName ]) subService
    ) service.services;
in
{

  options = {
    system.services = lib.mkOption {
      type = lib.types.attrsOf modularServiceConfiguration.serviceSubmodule;
      default = { };
      description = ''
        A collection of modular services.
      '';
      visible = "shallow";
    };
  };

  # Assert Finit services for those defined in isolation to the system.
  config = {
    finit.services = lib.concatMapAttrs (
      topLevelName: topLevelService: makeServices [ topLevelName ] topLevelService
    ) config.system.services;

    assertions = lib.concatLists (
      lib.mapAttrsToList (
        name: cfg: portable-lib.getAssertions (config.system.services.loc ++ [ name ]) cfg
      ) config.system.services
    );

    warnings = lib.concatLists (
      lib.mapAttrsToList (
        name: cfg: portable-lib.getWarnings (config.system.services.loc ++ [ name ]) cfg
      ) config.system.services
    );
  };
}
