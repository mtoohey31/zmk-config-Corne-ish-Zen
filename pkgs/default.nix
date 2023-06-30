{ Corne-ish-Zen-firmware-version, pkgs }:

let inherit (pkgs) callPackage lib; in
{
  Corne-ish-Zen-firmware = callPackage ./development/embedded/Corne-ish-Zen-firmware {
    version = Corne-ish-Zen-firmware-version;
  };

  lib = lib // import ../lib lib;

  zephyr-sdk = callPackage ./development/embedded/zephyr-sdk { };
}
