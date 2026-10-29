{...}: {
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "work-mbp" = {id = "RHL2UVR-RLAXLTD-KCGRL7Y-JLNKFNP-QUCJ4N6-HEHUQSY-BJQSGLO-DQVXMQO";};
        "personal-mbp" = {id = "IVT2GVZ-XNHWGFK-ZEXD6JP-SYTJZNW-5TBZVM2-G7IDYHL-W5RWMYR-SHX2CQ2";};
        "dolomite" = {id = "S7M6XFR-W33LSUR-G4L5AKN-BJWTY4C-PMNSYCS-RIWEVZZ-CAQ55SL-NMBZXAW";};
      };
      folders = {
        "Notes" = {
          path = "~/notes";
          devices = [
            "work-mbp"
            "personal-mbp"
            "dolomite"
          ];
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "31536000";
            };
          };
        };
      };
    };
  };
}
