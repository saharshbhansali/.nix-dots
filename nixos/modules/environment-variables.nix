{ config, lib, pkgs, inputs, ... }:

{

  # Set environment variables
  environment.sessionVariables = {
    EDITOR = "nvim";
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1";
  };

}
