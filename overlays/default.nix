{ inputs }:
[
  (import ./switch-to-configuration.nix)
  (import ./cpplint.nix)
  (import ./sidecar.nix { inherit inputs; })
  (import ./td.nix { inherit inputs; })
  (import ./terraform.nix)
]
