{...}: {
  enable = true;
  overrideDevices = true;
  overrideFolders = true;
  settings = {
    devices = {
      "work-mbp" = {id = "RHL2UVR-RLAXLTD-KCGRL7Y-JLNKFNP-QUCJ4N6-HEHUQSY-BJQSGLO-DQVXMQO";};
      "personal-mbp" = {id = "IVT2GVZ-XNHWGFK-ZEXD6JP-SYTJZNW-5TBZVM2-G7IDYHL-W5RWMYR-SHX2CQ2";};
    };
    folders = {
      "Notes" = {
        path = "~/notes";
        devices = [
          "work-mbp"
          # "personal-mbp"
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
}
