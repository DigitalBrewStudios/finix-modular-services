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

		finit.reload = mkOption {
			type = types.nullOr types.str;
			default = if config.process.reloadCommand != null then config.process.reloadCommand else null;
			defaultText = lib.literalExpression "config.process.reloadCommand";
			description = ''
				Reload Command for finix.

				This option sets the primary reload entry, and is the way to extend the
				command line derived from {option}`process.reloadCommand`.

				By default, it is set to {option}`process.reloadCommand`. Because
				{option}`process.reloadCommand` is already a command line (not an argument
				list), it is used verbatim so that references like `$MAINPID` are preserved.
				When {option}`process.reloadCommand` is unset, this option is `null` and no
				`finit.reload` is emitted; a service may then set
				`finit.reload` itself.

				To extend {option}`process.reloadCommand`, you can append
				to the command line:
				```nix
				finit.reload =
					config.process.reloadCommand + "<example>";
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
      conditions = [ "service/syslogd/ready" ];
      command = config.finit.command;
      reload = config.finit.reload;
      notify =
        if config.notificationProtocol.systemd then
          "systemd"
        else if config.notificationProtocol.s6 then
          "s6"
        else
          null;
    };

  };
}
