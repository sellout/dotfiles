## Some derivations fail on darwin with a message like “sandbox: data object
## length x exceeds maximum (y)” (where x > y). The modules in this directory
## work around those errors by selectively unsandboxing derivations that trigger
## it. See NixOS/nix#4119.
##
## When a derivation triggers this error, any other derivation that has that
## first derivation as an input will also trigger it, so you’ll need to include
## those as well.
##
## NOTE: You must have Nix configured with `sandbox = "relaxed"` for this to
##       work.
lib: rec {
  ## Unsandbox a derivation on darwin.
  noChroot = drv:
    if drv.stdenv.hostPlatform.isDarwin
    then drv.overrideAttrs {__noChroot = true;}
    else drv;

  ## Unsandbox a derivation on darwin, if its name is in the provided list.
  noChrootFor = names: drv:
    if lib.elem drv.name names
    then noChroot drv
    else drv;
}
