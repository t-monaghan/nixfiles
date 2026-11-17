{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.rex.nixosModules.default
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/srv/backups" = {
    device = "/dev/disk/by-uuid/41f1eab0-7a16-4120-87be-2c91881a417e";
    fsType = "ext4";
    options = ["noatime" "nofail" "x-systemd.device-timeout=10s"];
  };

  networking = {
    networkmanager.enable = true;
    hostName = "craton";
    firewall.interfaces.tailscale0.allowedTCPPorts = [45876];
  };

  users.users.tom = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [
      vim
      tree
      parted
      age
      lsof
      dig
      tcpdump
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGumOqP9Fp+Ozt4aNyj6CMOdxdcs+LbhZACc4DdgD6U2 tomaghan@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILA8fMUiRTSP7vgj5ezBhhAeFJNlTQFgjdZf3WeYlHOf #SSH ID - @tmonaghan"
    ];
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      j = "just";
      nv = "nvim";
      gco = "git checkout";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gpu = "git pull --autostash --rebase";
      gs = "git status";
      gl = "tv git-log";
      gd = "git difftool";
      gdc = "git difftool --cached";
      ga = "git add";
      gc = "git commit -m";
      gcp = "print-commit-hash";
      ghpr = "gh pr checkout";
      gsc = "git stash clear";
      checks = "gh pr checks --required --watch";
      gsp = "git stash pop";
      gcob = "git checkout -b";
      grs = "git restore --staged";
      grim = "git rebase -i main";
      grm = "git rebase main";
      gap = "git add -p";
      gsl = "git stash list";
      gfm = "git fetch origin main:main";
      gca = "git commit --amend --no-edit";
      grp = "git restore -p";
      gcy = "copy-commit-hash";
      gfy = "copy-changed-file-path";
    };
  };
  environment.shells = [pkgs.fish];
  users.defaultUserShell = "/run/current-system/sw/bin/fish";

  home-manager.users.tom = import ./home.nix;

  environment.systemPackages = with pkgs; [
    git
    just
  ];

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    rex = {
      enable = true;
      user = "tom";
      tailscale = {
        enable = true;
        hostname = "craton-rex";
        allowTailnetMembers = true;
        advertiseTags = ["tag:rex"];
      };
    };
    tailscale = {
      enable = true;
      openFirewall = true;
    };
    beszel.agent = {
      enable = true;
      smartmon.enable = true;
      environment = {
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZ1ySHE2oyVEh2pqVbw9Hd2jISOsZcIEdXszgHf/ryO";
        LISTEN = "100.64.250.109:45876";
      };
    };
  };

  systemd.services = {
    beszel-agent = {
      requires = ["tailscale-online.target"];
      after = ["tailscale-online.target"];
    };
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
