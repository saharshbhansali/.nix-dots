{ config, pkgs, lib, inputs, ... }:

{
  # imports = [ inputs.nixCatsNvim.nixosModules.default ];

  environment.systemPackages = [
    inputs.nixCatsNvim.packages.${pkgs.system}.default
    pkgs.fd
  ];

}
