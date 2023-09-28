This directory should exclusively contain files that are referenced in home.nix
(except for this file). They should be organized according to the defaults in
the [XDG Base Directory
Specification](https://specifications.freedesktop.org/basedir-spec/latest/),
assuming `HOME` is set to this directory.

None of these files should be executable. home.nix will set the executable bits
on the ones that should be. That helps ensure they’re not run from here, but
rather their nix store path. Also, files that are meant to be executable
shouldn’t have an extension – the shebang line is enough to get syntax
highlighting in most editors and the caller shouldn’t care what language they’re
written in.

We can only store files here that don’t reference any Nix configuration. If they
do need to reference Nix, they will be embedded in `../home.nix` itself.
