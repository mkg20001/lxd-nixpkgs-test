# lxd-nixpkgs-test

Tiny script to help you test nixpkgs changes (requires lxd installed)

# Installation

Clone the repo

Enable LXD

```nix
virtualisation.lxd.enable = true;
users.users.YOU.extraGroups = [ "lxd" ];
```

Init LXD

```
sudo lxd init --auto
```

# Usage

First run `bash import.sh` which will download the latest image from hydra and import it

Then edit `nixpkgs-container.sh` to contain the path to your nixpkgs

Afterwards use `bash nixpkgs-container.sh <worktree>` to spawn a container with your worktree checked out

(If you don't know git worktree then you should really look it up, `git worktree add your-big-feature`)

Modify `<worktree>/config/default.nix` and re-run `nixos-rebuild switch` in the container to have your changes applied
