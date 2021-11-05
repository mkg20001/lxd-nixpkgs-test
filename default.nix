with (import <nixpkgs> {});

stdenv.mkDerivation {
  pname = "lxd-nixpkgs-test";
  version = "unstable";

  src = ./.;

  installPhase = ''
    install -D nixpkgs-container.sh $out/bin/lxd-nixpkgs-test
    install -D import.sh $out/bin/lxd-nixpkgs-test-import
    ln -s $out/bin/lxd-nixpkgs-test $out/bin/lnt
  '';
}
