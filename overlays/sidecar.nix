{ inputs }:
_final: prev: {
  # sidecar >= 1.x requires Go 1.27; nixpkgs' default buildGoModule is still on 1.26.
  sidecar = (prev.buildGoModule.override { go = prev.go_1_27; }) rec {
    pname = "sidecar";
    # Keep in sync with the `sidecar` input tag in flake.nix; a bump also
    # needs a new vendorHash.
    version = "1.13.0";

    src = inputs.sidecar;
    vendorHash = "sha256-VOnnjbhOdQBhxIPRkBUKoKX0OpW3PXcOJudsZPJuDMY=";

    subPackages = [ "cmd/sidecar" ];

    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
    ];

    env.CGO_ENABLED = "1";

    meta = with prev.lib; {
      description = "TUI companion for AI coding workflows";
      homepage = "https://github.com/marcus/sidecar";
      license = licenses.mit;
      mainProgram = "sidecar";
      platforms = platforms.unix;
    };
  };
}
