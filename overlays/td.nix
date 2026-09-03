{ inputs }:
_final: prev: {
  # td >= 0.6x requires Go 1.27; nixpkgs' default buildGoModule is still on 1.26.
  td = (prev.buildGoModule.override { go = prev.go_1_27; }) rec {
    pname = "td";
    # Keep in sync with the `td` input tag in flake.nix; a bump also needs a
    # new vendorHash.
    version = "0.65.0";

    src = inputs.td;
    proxyVendor = true;
    vendorHash = "sha256-F8G/peY9N/eQzX9s7mUsMj37TyzAjrehDGaho5gENYc=";

    subPackages = [ "." ];

    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
    ];

    env.CGO_ENABLED = "1";

    meta = with prev.lib; {
      description = "Task management CLI for AI-assisted development";
      homepage = "https://github.com/marcus/td";
      license = licenses.mit;
      mainProgram = "td";
      platforms = platforms.unix;
    };
  };
}
