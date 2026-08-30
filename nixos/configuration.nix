{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./neovim.nix
    ./modules/home-assistant.nix
    inputs.spendable.nixosModules.default
    inputs.agenix.nixosModules.default
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  # used for private github repo access
  # `access-tokens = github.com=TOKEN_HERE`
  nix.extraOptions = ''
    !include /etc/nix/access-tokens.conf
  '';

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    firewall.allowedTCPPorts = [80 53];
    firewall.allowedUDPPorts = [53];
    networkmanager.enable = true;
    hostName = "dolomite";
  };

  users.users.tom = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [
      pi-coding-agent
      vim
      tree
      parted
      age
      lsof
      dig
      tcpdump
      terraform
      terraform-providers.ubiquiti-community_unifi
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGumOqP9Fp+Ozt4aNyj6CMOdxdcs+LbhZACc4DdgD6U2 tomaghan@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+b+a2qqmf90tuwcKHrVGCL41PRmQvL/BU2kXhhxA5J cultureamp-2026"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILA8fMUiRTSP7vgj5ezBhhAeFJNlTQFgjdZf3WeYlHOf #SSH ID - @tmonaghan"
    ];
  };

  programs.fish.enable = true;
  environment.shells = [pkgs.fish];
  users.defaultUserShell = "/run/current-system/sw/bin/fish";

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

      # nixpkgs ships no OTA provider binary, so Matter device firmware
      # updates fail with "[Errno 2] No such file or directory:
      # 'chip-ota-provider-app'". Package the prebuilt binary and put it on
      # the matter-server unit's PATH below. See ./modules/chip-ota-provider-app.nix.
      chip-ota-provider-app = final.callPackage ./modules/chip-ota-provider-app.nix {};
    })
  ];

  systemd.services.matter-server.path = [pkgs.chip-ota-provider-app];

  services = {
    matter-server = {
      enable = true;
      openFirewall = true;
    };
    # avahi used in matter/thread setup
    avahi = {
      enable = true;
      openFirewall = true;
      nssmdns4 = true;
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
    adguardhome = {
      enable = true;
      openFirewall = true;
      settings = {
        dns = {
          upstream_dns = [
            "https://1.1.1.1/dns-query"
            "https://1.0.0.1/dns-query"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
      };
    };
  };

  fileSystems."/media" = {
    device = "/dev/disk/by-uuid/3e01d16f-cedf-4913-9858-e0677715f700";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = [pkgs.intel-media-driver]; # to provide transcoding
  };

  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

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
