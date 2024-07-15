# Emacs configuration

This is the entirety of Sellout’s Emacs configuration (minus any secrets, etc.).

The entry-point is [default.nix](./default.nix), which pulls everything together and contains Emacs Lisp that depends on Nix configuration.

[init.el](./init.el) is the ostensible `user-init-file`, however it’s actually spliced into the Emacs Lisp included in default.nix. Consequently, this module requires you to have a file `$XDG_CONFIG_HOME/emacs/init.el` and to also have _none_ of ~/.emacs.d/, ~/.emacs, nor ~/.emacs.el, because [Emacs’ init file search algorithm](https://www.gnu.org/software/emacs/manual/html_node/emacs/Find-Init.html) will otherwise result in an incorrect `user-emacs-directory`, missing a lot of the configuration in this module.

The upside of that detail is that `$XDG_CONFIG_HOME/emacs/init.el` is a user-editable file that can contain local configuration (which will be loaded before any of the configuration in this module). This is a good place to put things temporarily until you have tested that they work and want to move them into [init.el](./init.el) here.

Emacs’ Customization API is also configured to write to `(concat user-emacs-directory "/custom.el")`, so that Customizations can be held there as well, and moved into [init.el](./init.el) once they’re settled.
