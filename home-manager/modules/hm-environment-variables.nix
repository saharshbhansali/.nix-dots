{ config, lib, pkgs, inputs, ... }:

{

  # Set environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    # QT_QPA_PLATFORMTHEME = "kvantum";
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = 1;
  };

}

