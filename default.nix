with (import <nixpkgs> {});

stdenv.mkDerivation {
  pname = "lxd-nixpkgs-test";
  version = "unstable";

  src = ./.;

  installPhase = ''
    sed "s|SELF=.*|SELF=$out|g" -i nixpkgs-container.sh
    install -D nixpkgs-container.sh $out/bin/lxd-nixpkgs-test
    cp -r shared inside help.txt $out
    ln -s $out/bin/lxd-nixpkgs-test $out/bin/lnt
  '';
}
