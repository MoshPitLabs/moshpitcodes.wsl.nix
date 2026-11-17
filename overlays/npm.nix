_final: prev: {
  # nixpkgs bundles npm 11 inside pkgs.nodejs. npm 12 is installed separately
  # as `npm12` so only the interactive `npm` on PATH changes (see
  # modules/home/dev.nix); the coding-agent wrappers keep calling
  # ${pkgs.nodejs}/bin/npx and stay on the bundled npm 11.
  #
  # The registry tarball ships its dependencies bundled, so there is no
  # install or build step and no package scripts run. npm 12 needs node
  # ^22.22.2 || ^24.15.0 || >=26.0.0; it runs on pkgs.nodejs.
  #
  # The npm tree lives in $out/libexec/npm, not lib/node_modules/npm, so the
  # only path shared with pkgs.nodejs is bin/npm (which hiPrio in dev.nix
  # resolves) and the merged profile never mixes npm 11 and npm 12 files.
  #
  # Remove this overlay once nixpkgs' `nodejs` bundles npm >= 12. The pin does
  # not follow `nix flake update`: bump version and hash deliberately when
  # npm/cli or its bundled dependencies get a security advisory.
  npm12 = prev.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "npm";
    # A bump needs a new hash: the registry's `dist.integrity` for the version
    # (https://registry.npmjs.org/npm/<version>).
    version = "12.2.2";

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/npm/-/npm-${finalAttrs.version}.tgz";
      hash = "sha512-KglgbZyacf7jH+FHuNRqVuCzQi8VhI2a7J87Ix43FsPTuZoGWmIXXGdZtBUOA79vwL+IJREqURVzupA7PsQTcA==";
    };

    sourceRoot = "package";

    nativeBuildInputs = [ prev.makeWrapper ];

    dontConfigure = true;
    dontBuild = true;
    dontPatchShebangs = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/libexec/npm $out/bin
      cp -r . $out/libexec/npm

      makeWrapper ${prev.nodejs}/bin/node $out/bin/npm \
        --add-flags $out/libexec/npm/bin/npm-cli.js

      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Package manager for JavaScript (npm 12, run on nixpkgs' nodejs)";
      homepage = "https://www.npmjs.com/package/npm";
      license = licenses.artistic2;
      mainProgram = "npm";
      platforms = platforms.unix;
    };
  });
}
