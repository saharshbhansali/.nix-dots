{ config, lib, pkgs, ... }:

{

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        amdgpuBusId = "PCI:5:0:0";     # AMD iGPU
        nvidiaBusId = "PCI:1:0:0";     # NVIDIA dGPU
      };
      # Use the open kernel module (required for driver >= 560 on Turing+ GPUs)
      open = true;
    };
  };

  specialisation = {
    gaming-time.configuration = {
      hardware.nvidia = {
        prime.sync.enable = lib.mkForce true;
        prime.offload = {
          enable = lib.mkForce false;
          enableOffloadCmd = lib.mkForce false;
        };
      };
    };
  };

}

