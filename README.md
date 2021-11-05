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

```
nix-env -f https://github.com/mkg20001/lxd-nixpkgs-test/archive/master.tar.gz -i
```

Set everything up by running `lnt init <location-of-nixpkgs>`

Afterwards use `lnt enter <worktree>` to spawn and enter a container with your worktree checked out

Modify `<worktree>/config/default.nix` and re-run `lnt rebuild <worktree>` in the container to have your changes applied

NOTE: this tool assumes the git worktree workflow

If you don't know git worktree then you should really look it up

`git worktree add your-big-feature`
