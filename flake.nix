{
  description = "zmk-config-Corne-ish-Zen";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, utils, ... }: utils.lib.eachDefaultSystem (system:
    with import nixpkgs
      {
        overlays = [
          (final: prev: {
            zephyr-sdk = final.stdenv.mkDerivation rec {
              pname = "zephyr-sdk";
              version = "0.15.0";
              nativeBuildInputs = [
                final.autoPatchelfHook
                final.cmake
                final.python38
                final.stdenv.cc.cc.lib
                final.wget
                final.which
              ];
              src = builtins.fetchurl {
                url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/zephyr-sdk-${version}_linux-x86_64.tar.gz";
                sha256 = "0ps17zrk6viwr5ikn40ybm1pwgzrpcyyqc0s3chnwzjb23f26g4r";
              };
              dontUnpack = true;
              dontConfigure = true;
              installPhase = ''
                mkdir $out
                tar -xf $src -C $out --strip-components=1
                cd $out
                bash ./setup.sh -t x86_64-zephyr-elf
              '';
            };
          })
        ];
        inherit system;
      };
    rec {
      packages.default = stdenv.mkDerivation {
        name = "Corne-ish-Zen-firmware";
        src = ./.;
        nativeBuildInputs = [
          cmake
          git
          ninja
          zephyr-sdk
        ] ++ (with python3Packages; [
          west
          pyelftools
        ]);
        dontConfigure = true;
        CCACHE_DISABLE = 1;
        buildPhase =
          let
            moduleCopyCmds = builtins.map
              (module:
                let
                  source = fetchFromGitHub {
                    owner = module.owner or "zephyrproject-rtos";
                    inherit (module) repo rev sha256;
                  };
                in
                "mkdir -p $(dirname ${module.path}) && cp --no-preserve=mode -r ${source} ${module.path}"
                + nixpkgs.lib.optionalString (module.createDotGit or false) ''

                  # west requires a .git dir for some modules
                  git -C ${module.path} init
                  git -C ${module.path} config user.email "nix-builder@example.com"
                  git -C ${module.path} config user.name "Nix Builder"
                  git -C ${module.path} add -A
                  git -C ${module.path} commit -m "nix-build"
                  git -C ${module.path} checkout -b manifest-rev
                  git -C ${module.path} checkout --detach manifest-rev
                ''
              )
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

            ${builtins.concatStringsSep "\n" moduleCopyCmds}

            export Zephyr_DIR=$PWD/zephyr/share/zephyr-package/cmake

            mkdir out
            west build -s zmk/app -b corneish_zen_v1_left -- -DZMK_CONFIG="$PWD/config"
            mv build/zephyr/zmk.uf2 out/corneish_zen_v1_left.uf2
            west build --pristine -s zmk/app -b corneish_zen_v1_right -- -DZMK_CONFIG="$PWD/config"
            mv build/zephyr/zmk.uf2 out/corneish_zen_v1_right.uf2
          '';
        installPhase = "cp -r out $out";
      };

      devShells.default = mkShell {
        inherit (packages.default) nativeBuildInputs;
      };
    });
}
