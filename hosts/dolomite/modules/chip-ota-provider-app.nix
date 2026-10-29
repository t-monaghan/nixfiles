# Prebuilt `chip-ota-provider-app` from the Matter SDK.
#
# python-matter-server performs Matter OTA (firmware) updates by shelling out
# to a `chip-ota-provider-app` binary found on $PATH
# (matter_server/server/ota/provider.py spawns it via create_subprocess_exec).
# nixpkgs does NOT package this binary at all — so on a stock
# `services.matter-server` the very first device update fails with:
#
#     Failed to perform the action update/install.
#     [Errno 2] No such file or directory: 'chip-ota-provider-app'
#
# Upstream doesn't build it from source in their image either: the official
# python-matter-server Dockerfile just downloads the prebuilt release binary
# from home-assistant-libs/matter-linux-ota-provider. We do the same and
# patchelf it onto Nix's runtime libs (glibc + libnl + libstdc++/libgcc).
#
# The binary only links: libnl-3 / libnl-route-3 (netlink iface enumeration),
# libstdc++ / libgcc_s (gcc), and glibc. It uses CHIP's built-in "minimal
# mDNS", so it needs neither Avahi nor D-Bus of its own.
#
# Bump `version` + hashes from the releases page:
#   https://github.com/home-assistant-libs/matter-linux-ota-provider/releases
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libnl,
}: let
  version = "2025.9.0";
  base = "https://github.com/home-assistant-libs/matter-linux-ota-provider/releases/download/${version}";

  # Per-arch release asset + its SRI hash.
  sources = {
    x86_64-linux = {
      asset = "chip-ota-provider-app-x86-64";
      hash = "sha256-RVDfevZSnkYgRj0cASf4MOwkBMgXrUxjQ7KeMs7AFE4=";
    };
    aarch64-linux = {
      asset = "chip-ota-provider-app-aarch64";
      hash = "sha256-4GirbEBQ4j6qbM2pv37M3Et5KiUU4QmMvBK0FM1kqn4=";
    };
  };

  src =
    sources.${stdenv.hostPlatform.system}
    or (throw "chip-ota-provider-app: unsupported system ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "chip-ota-provider-app";
    inherit version;

    src = fetchurl {
      url = "${base}/${src.asset}";
      inherit (src) hash;
    };

    dontUnpack = true;

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [
      libnl # libnl-3.so.200 + libnl-route-3.so.200
      stdenv.cc.cc.lib # libstdc++.so.6 + libgcc_s.so.1 (glibc is implicit)
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/chip-ota-provider-app"
      runHook postInstall
    '';

    meta = {
      description = "Matter SDK OTA Provider example app (prebuilt) for python-matter-server OTA updates";
      homepage = "https://github.com/home-assistant-libs/matter-linux-ota-provider";
      license = lib.licenses.asl20;
      mainProgram = "chip-ota-provider-app";
      platforms = builtins.attrNames sources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
