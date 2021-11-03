{ config, pkgs, lib, ... }:

with lib;

{
  # useful debug tools
  environment.systemPackages = with pkgs; [
    htop
    strace
    tree
  ];

  # don't waste any time
  documentation.enable = mkForce false;
  documentation.nixos.enable = mkForce false;
}
