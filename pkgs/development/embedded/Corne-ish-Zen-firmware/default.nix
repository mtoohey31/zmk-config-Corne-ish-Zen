{ cmake
, fetchFromGitHub
, git
, lib
, ninja
, python3Packages
, stdenv
, version
, zephyr-sdk
}:

stdenv.mkDerivation {
  pname = "Corne-ish-Zen-firmware";
  inherit version;

  src = builtins.path {
    path = ../../../..;
    name = "zmk-config-Corne-ish-Zen-src";
  };

  nativeBuildInputs = [
    cmake
    git
    ninja
    zephyr-sdk
  ] ++ (
    let inherit (python3Packages) pyelftools west; in [
      pyelftools
      west
    ]
  );

  dontConfigure = true;
  CCACHE_DISABLE = 1;
  buildPhase =
    let
      modulesCopyCommands = builtins.map
        (lib.moduleCopyCommands { inherit fetchFromGitHub; })
        (import ./west-modules.nix);
    in
    ''
      mkdir -p .west
      cat >.west/config <<EOF
      [manifest]
      path = config
      file = west.yml

      [zephyr]
      base = zephyr
      EOF

      ${builtins.concatStringsSep "\n" modulesCopyCommands}

      export Zephyr_DIR=$PWD/zephyr/share/zephyr-package/cmake

      mkdir out
      west build -s zmk/app -b corneish_zen_v1_left -- -DZMK_CONFIG="$PWD/config"
      mv build/zephyr/zmk.uf2 out/corneish_zen_v1_left.uf2
      west build --pristine -s zmk/app -b corneish_zen_v1_right -- -DZMK_CONFIG="$PWD/config"
      mv build/zephyr/zmk.uf2 out/corneish_zen_v1_right.uf2
    '';
  installPhase = "cp -r out $out";

  meta.platforms = [ "x86_64-linux" ];
}
