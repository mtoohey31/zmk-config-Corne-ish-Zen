{
  description = "zmk-config-Corne-ish-Zen";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        overlays = [
          (_: prev: import ./pkgs {
            pkgs = prev;
            Corne-ish-Zen-firmware-version = self.shortRev or "dirty";
          })
        ];
        inherit system;
      };
      inherit (pkgs) Corne-ish-Zen-firmware mkShell;
    in
    {
      packages.default = Corne-ish-Zen-firmware;

      devShells.default = mkShell {
        inherit (self.packages.${system}.default) nativeBuildInputs;
      };
    });
}
