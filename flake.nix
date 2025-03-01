{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            vim
            ripgrep
            bat
            lf
            nixfmt-rfc-style
          ];

          # Got an error when trying to switch so using this...
          # Think it's because I had an old version of nix installed?
          # Seems like more recent versions have switched to using 350 instead.
          ids.gids.nixbld = 30000;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Got this from https://nixcademy.com/posts/nix-on-macos/
          # Enables building linux packages on darwin.
          nix.linux-builder.enable = true;

          # Allow touch ID authentication for sudo.
          security.pam.services.sudo_local.touchIdAuth = true;

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Example from https://nixcademy.com/posts/nix-on-macos/
          system.defaults = {
            dock.autohide = true;
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Import modules that we created
          imports = [
            ./modules/stretch-reminder.nix
          ];
          # Enable the hello service with a custom greeter
          services.stretch-reminder.enable = true;
          services.stretch-reminder.intervalMinutes = 30;
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Samuels-MacBook-Pro
      darwinConfigurations."Samuels-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };

      # Add a default package that runs a zsh shell
      # TODO: not sure if this is correct....
      packages.aarch64-darwin.default =
        let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        in
        pkgs.writeShellScriptBin "zsh-shell" ''
          ${pkgs.zsh}/bin/zsh
        '';

      # Add formatter for `nix fmt` command: see https://github.com/NixOS/nixfmt
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
    };
}
