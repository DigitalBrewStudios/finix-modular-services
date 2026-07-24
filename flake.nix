{
  description = "Support for Modular services in finix";

  outputs = _: {
    nixosModules.default = import ./modules/service.nix;
  };
}
