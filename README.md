# dotfiles

[![built with garnix](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsellout%2Fdotfiles)](https://garnix.io/repo/sellout/dotfiles)
[![Nix CI](https://nix-ci.com/badge/gh:sellout:dotfiles)](https://nix-ci.com/gh:sellout:dotfiles)
[![Project Manager](https://img.shields.io/badge/%20-Project%20Manager-%235277C3?logo=nixos&labelColor=%23cccccc)](https://sellout.github.io/project-manager/)

Sellout’s general configuration

The non-personal bits of Sellout’s configuration, suitable for all to see.

This is missing pieces of Sellout’s actual configurations, such as

- account information,
- employer information,
- keys, and
- machine information.

Sellout’s actual system configurations depend on this repository and add some necessary pieces. But this has the bulk of their configuration to be able to share it and to get feedback.

## development environment

We recommend the following steps to make working in this repository as easy as possible.

### `nix run github:sellout/project-manager -- switch`

This is sort-of a catch-all for keeping your environment up-to-date. It regenerates files, wires up the project’s Git configuration, ensures the shells have the right packages configured the right way, enables checks & formatters, etc.

If you already have it installed on your system or once you’ve run `direnv allow`, you can instead use `project-manager switch`.

### `direnv allow`

This command ensures that any work you do within this repository happens within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

## building & development

`nix build` will build the various packages that are part of this project.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

`nix flake check` will do a comprehensive check of the state of the repository (package-specific tests are usually run as part of `nix build`, but this covers formatting, consistency, and larger integration testing).

## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to offer minor updates and revisions.

## comparisons

Other projects similar to this one, and how they differ.
