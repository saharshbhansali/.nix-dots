{ config, lib, pkgs, inputs, ... }:

{

  imports = [ inputs.flatpaks.nixosModules.default ];

}
