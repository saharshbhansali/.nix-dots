
{ config, lib, pkgs, inputs, ... }:

{

  ## User level packages
  home.packages = with pkgs; [

    # ## VS Code
    # vscode-fhs
    # vscodium
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        github.copilot
        github.copilot-chat
        supermaven.supermaven
        tabnine.tabnine-vscode

        ms-azuretools.vscode-docker

        bbenoist.nix
        ms-python.python
        ms-python.debugpy

        # catppuccin.cattppuccin-vscode
      ];
    })
    vimPlugins.supermaven-nvim

    # ## Helix editor
    helix
    # evil-helix
    # helix-gpt

    ## AI editors
    # code-cursor
    code-cursor-fhs
    windsurf
    # zed-editor
    zed-editor-fhs

    # AI code assistant
    opencode
    claude-code
    gpt-cli
    # aider-chat
    aider-chat-full

  ];

}
