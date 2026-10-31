{
  lib,
  customsecrets,
  ...
}:
let
  apiKeys = customsecrets.apiKeys or { };
  # Only inject non-empty keys; empty values keep the variable unset so agents
  # can pick up keys from the environment at runtime (e.g. via Doppler).
  keyEnv = lib.filterAttrs (_: v: v != "") {
    ANTHROPIC_API_KEY = apiKeys.anthropic or "";
    OPENAI_API_KEY = apiKeys.openai or "";
    OPENROUTER_API_KEY = apiKeys.openrouter or "";
  };
in
{
  imports = [
    ./agent-browser.nix
    ./antigravity.nix
    ./claude-code.nix
    ./codex.nix
    ./kilo-code.nix
    ./kiro-code.nix
    ./opencode.nix
    ./pi-mono.nix
    ./t3code.nix
  ];

  # API keys are shared across the agent modules (claude-code, codex, kiro,
  # opencode, pi), so they are injected once here rather than per module.
  home.sessionVariables = keyEnv;
}
