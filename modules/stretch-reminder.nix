{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.services.stretch-reminder;
in
{
  # Declare configurable options for the stretch reminder service
  options.services.stretch-reminder = {
    enable = mkEnableOption "Stretch reminder service";

    intervalMinutes = mkOption {
      type = types.int;
      default = 30;
      description = "Interval between stretch reminders in minutes";
    };
  };

  # Define the service configuration when enabled
  config = mkIf cfg.enable {
    launchd.daemons.stretch-reminder = {
      script = ''
        # Use osascript to display a macOS notification
        /usr/bin/osascript -e 'display notification "Time to stretch fatty!" with title "nix-darwin reminder" sound name "Frog"'
      '';

      serviceConfig = {
        Label = "org.nixos.stretch-reminder";
        StartInterval = cfg.intervalMinutes * 60; # Convert minutes to seconds
        RunAtLoad = true;
        KeepAlive = false;
        StandardErrorPath = "/tmp/stretch-reminder-error.log";
        StandardOutPath = "/tmp/stretch-reminder-output.log";
      };
    };
  };
}
