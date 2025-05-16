{
  flaky,
  options,
  ...
}: {
  config = flaky.lib.multiConfig options {
    homeConfig = {
      services.udiskie.enable = true;
    };

    nixosConfig = {
      services.udisks2.enable = true;
    };
  };
}
