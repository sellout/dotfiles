[![built with garnix](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsellout%2Fdotfiles)](https://garnix.io)

# dotfiles

Sellout’s general configuration

The non-personal bits of my configuration, suitable for all to see.

This is missing pieces of my actual configurations, such as

- account information,
- employer information,
- keys, and
- machine information.

My actual system configurations depend on this repo and add some necessary pieces. But this contains the bulk of my configuration in order to be able to share it and to solicit feedback.

## development environment

We recommend the following steps to make working in this repo as easy as possible.

### `direnv allow`

This command ensures that any work you do within this repo is done within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

### `git config --local include.path ../.config/git/config`

This will apply our repo-specific Git configuration to `git` commands run against this repo. It is very lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.

## building & development

Especially if you are unfamiliar with the nix ecosystem, there is a Nix build (both with and without a flake). If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to provide minor updates and revisions.

## comparisons

Other projects similar to this one, and how they differ.
