with (import <nixpkgs> {});

stdenv.mkDerivation {
  pname = "lxd-nixpkgs-test";
  version = "unstable";

  src = ./.;

  makeFlags = [ "PREFIX=$(out)" ];
}
