{ autoPatchelfHook, cmake, python38, stdenv, wget, which }:

stdenv.mkDerivation rec {
  pname = "zephyr-sdk";
  version = "0.15.0";

  src = builtins.fetchurl {
    url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/zephyr-sdk-${version}_linux-x86_64.tar.gz";
    sha256 = "0ps17zrk6viwr5ikn40ybm1pwgzrpcyyqc0s3chnwzjb23f26g4r";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    cmake
    python38
    stdenv.cc.cc.lib
    wget
    which
  ];

  dontUnpack = true;
  dontConfigure = true;
  installPhase = ''
    mkdir $out
    tar -xf $src -C $out --strip-components=1
    cd $out
    bash ./setup.sh -t x86_64-zephyr-elf
  '';

  meta.platforms = [ "x86_64-linux" ];
}
