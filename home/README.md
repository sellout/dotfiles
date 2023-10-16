This directory should only contain files referenced by home.nix (except for this file). They’re organized according to the defaults in the [Cross-Desktop Group (XDG) Base Directory
Specification](https://specifications.freedesktop.org/basedir-spec/latest/), assuming `$HOME` is this directory.

None of these files should be executable. home.nix will set the executable bits on the ones that should be. That helps ensure they’re not run from here, but rather their nix store path.

Also, files that will be executable shouldn’t have an extension. The shebang line is enough to get syntax highlighting in most editors and the caller shouldn’t care what language they’re written in.

We can only store files here that don’t reference any Nix configuration. If they do need to reference Nix, they’re embedded in [home-configuration.nix](../nix/modules/home-configuration.nix) itself.
