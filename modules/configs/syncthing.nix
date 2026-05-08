{...}: {
  enable = true;
  overrideDevices = true;
  overrideFolders = true;
  settings = {
    devices = {
      "work-mbp" = { id = "RHL2UVR-RLAXLTD-KCGRL7Y-JLNKFNP-QUCJ4N6-HEHUQSY-BJQSGLO-DQVXMQO"; };
      # "personal-mbp" = { id = "REPLACE-WHEN-YOU-RUN-SYNCTHING-ON-PERSONAL"; };
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
