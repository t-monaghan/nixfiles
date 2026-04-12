# Root Nixfiles Module
{...}: {
  imports = [
    ./home.nix
    ./work/culture-amp/home.nix
    ./work/culture-amp/common.nix
  ];
}
