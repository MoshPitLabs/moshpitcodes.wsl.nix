# xAI Grok Build CLI (grok).
{ pkgs, ... }:
{
  home.packages = [ pkgs.grok-build ];

  programs.zsh.shellAliases = {
    grok-doppler = "doppler run -- grok";
  };
}
