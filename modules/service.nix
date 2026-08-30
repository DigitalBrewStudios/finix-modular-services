{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ (lib.mkAliasOptionModule [ "finit" "service" ] [ "finit" "services" "" ]) ];

  options = {
    finit.services = lib.mkOption {
      type = with lib.types; lazyAttrsOf deferredModule;
      default = { };
      description = ''
        This module configures Finit services.
      '';
    };

	finit.command = mkOption {
		type = types.str;
		default = lib.escapeShellArgs config.process.argv;
		defaultText = lib.literalExpression "lib.escapeShellArgs config.process.argv";
		description = ''
				Starting Command for finix.

				This option sets the primary starting entry, and is the way to extend the
				command line derived from {option}`process.argv`.

				By default, it is set to `lib.escapeShellArgs {option}process.argv`. Because
				{option}`process.argv` is already a command line (not an argument
				list), it is used verbatim so that references like `$MAINPID` are preserved.
				When {option}`process.argv` is unset, this option is `null` and no
				`finit.command` is emitted; a service may then set
				`finit.command` itself.

				To extend {option}`process.argv`, you can append
				to the command line:
				```nix
				finit.command =
					config.process.argv + "<example>";
				```
			'';
		};

    # Import this logic into sub-services also.
    # Extends the portable `services` option.
    services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          class = "service";
          modules = [
            ./service.nix
          ];
        }
      );
    };
  };

  config = {
    finit.services."" = {
      command = config.finit.command;
    };

  };
}
