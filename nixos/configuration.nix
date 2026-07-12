# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./neovim.nix
    ./modules/home-assistant.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.networkmanager.enable = true;
  networking.hostName = "dolomite";

  time.timeZone = "Australia/Melbourne";

  i18n.defaultLocale = "en_AU.UTF-8";

  users.users.tom = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [
      vim
      tree
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGumOqP9Fp+Ozt4aNyj6CMOdxdcs+LbhZACc4DdgD6U2 tomaghan@gmail.com"
    ];
  };

  programs = {
    # System-level fish just makes it a valid login shell and installs vendor
    # completions; the user-facing config (abbrs, functions, plugins, prompt)
    # is managed by home-manager (./home.nix → ../modules/shell.nix). atuin,
    # starship, tmux, direnv, git, … are likewise handled by home-manager now.
    fish.enable = true;
  };
  environment.shells = [pkgs.fish];
  users.defaultUserShell = "/run/current-system/sw/bin/fish";

  # Home-manager user config: `tom` gets the shared shell/CLI tooling used by
  # all three machines (fish, starship, atuin, tmux, git, …).
  home-manager.users.tom = import ./home.nix;

  environment.systemPackages = with pkgs; [
    git
  ];

  services = {
    matter-server = {
      enable = true;
      openFirewall = true;
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "ha.dolomite.lan".locations."/" = {
          proxyPass = "http://localhost:8123";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
