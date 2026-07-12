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

  # Work around a matter-server startup crash loop. The DCL occasionally serves
  # a malformed PAA root certificate; the strict Rust ASN.1 parser in our (very
  # new) `cryptography` throws ValueError, and python-matter-server doesn't guard
  # the parse, so `MatterServer.start()` dies BEFORE binding TCP 5580 — the
  # service just restart-loops and HA's Matter integration can never connect.
  # The patch skips the bad cert. It touches only the pure-Python package, so
  # just that one derivation rebuilds (no CHIP recompile). Drop once fixed
  # upstream: https://github.com/home-assistant-libs/python-matter-server
  nixpkgs.overlays = [
    (final: prev: {
      python-matter-server = prev.python-matter-server.overridePythonAttrs (old: {
        patches = (old.patches or []) ++ [./modules/matter-server-skip-bad-paa.patch];
      });
    })
  ];

  services = {
    matter-server = {
      enable = true;
      openFirewall = true; # opens TCP 5580 (WS API) ONLY — not mDNS.
    };

    # mDNS / DNS-SD. This is the missing piece for Thread + Matter discovery:
    #  * HA's Thread panel finds a border router by browsing `_meshcop._udp`.
    #    Without inbound UDP 5353 those advertisements from the SLZB-06U never
    #    reach the box, so you get "No border routers were found" even though
    #    the `otbr` integration can still reach the OTBR REST API on :8081.
    #  * matter-server does its mDNS via Avahi over D-Bus (the module already
    #    bind-mounts /run/dbus), so Matter commissioning needs Avahi running.
    # openFirewall opens inbound UDP 5353, which the default firewall drops.
    avahi = {
      enable = true;
      openFirewall = true;
      nssmdns4 = true; # let the host resolve *.local too (optional)
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
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
