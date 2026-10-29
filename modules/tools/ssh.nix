{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.context.role.desktop {
  programs.ssh = {
    enable = true;
    # Opt out of the deprecated implicit `Host *` defaults; declare our own blocks.
    enableDefaultConfig = false;
    # Emitted as an `Include` at the top of ~/.ssh/config, ahead of our
    # match blocks. OrbStack manages this file for its VMs/containers.
    includes = ["~/.orbstack/ssh/config"];
    settings = {
      dolomite = {
        hostname = "ssh.dolomite.lan";
        user = "tom";
      };
    };
  };
}
