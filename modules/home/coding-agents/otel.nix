# OpenTelemetry export for Claude Code and Codex: OTLP/HTTP to the otel-collector
# on infra-01 (moshpitcodes.homelab, services/grafana-stack), which feeds the
# "Coding Agents (OTel)" Grafana dashboard. The collector's firewall allows this
# machine by its LAN address (192.168.178.157 at the time of writing, DHCP).
#
# Prompt text, tool arguments and raw API bodies stay off: Claude Code's
# OTEL_LOG_* switches default to disabled and Codex's log_user_prompt is set
# false explicitly.
{
  endpoint = "http://192.168.178.53:4318";
  # Reported as host.name (Claude Code) and read back as host_name; Codex reports
  # the machine hostname itself, so keep this equal to networking.hostName.
  hostName = "nixos-wsl";
}
