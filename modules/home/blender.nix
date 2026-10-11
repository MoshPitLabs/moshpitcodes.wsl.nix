{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Blender 4.5 LTS: Enfusion Blender Tools break on 5.x API changes. Its
  # Python 3.11 PySide6 is not in the binary cache, so the first build compiles it.
  pkgsBlender = inputs.nixpkgs-blender.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Enfusion Blender Tools ship with Arma Reforger Tools on Steam and are not
  # redistributable, so the add-on is symlinked from the Windows Steam library
  # instead of being copied into the store. Steam updates apply automatically.
  enfusionBlenderTools = "/mnt/d/SteamLibrary/steamapps/common/Arma Reforger Tools/Blender/scripts/addons/EnfusionBlenderTools";

  # Required by Enfusion Blender Tools (see its requirements.txt). Not in
  # nixpkgs, and the PyPI sdist omits VHACD.h, so build from the 0.0.6 commit.
  vhacdx =
    ps:
    ps.buildPythonPackage {
      pname = "vhacdx";
      version = "0.0.6";
      pyproject = true;

      src = pkgsBlender.fetchFromGitHub {
        owner = "trimesh";
        repo = "vhacdx";
        rev = "70a9bfdec323e3f56b4d6f52fd4967a85101f32e";
        hash = "sha256-aBH/iE2mMmoInGv75XBovz1nbxTUf3OUHxhZQGd66PU=";
      };

      build-system = with ps; [
        setuptools
        wheel
        pybind11
      ];
      dependencies = [ ps.numpy ];
      pythonImportsCheck = [ "vhacdx" ];
    };

  # The add-on only uses QtWidgets. Building PySide6 against the minimal Qt set
  # avoids compiling QtWebEngine (Chromium), which is not cached at this rev.
  pyside6 =
    ps:
    ps.pyside6.overrideAttrs (_: {
      buildInputs = with ps.qt6; [
        ps.ninja
        ps.packaging
        ps.setuptools
        qtbase
        qtsvg
        qttools # Designer; required by the PySide6 CMake setup
      ];
    });

  # Pre-provide the add-on's third-party packages so it skips its runtime
  # `pip install`, whose manylinux wheels would not load on NixOS anyway.
  # The wrapper names its binary and .desktop entry after pname
  # ("blender-wrapped" by default); keep the usual `blender` command.
  blender =
    (pkgsBlender.blender.withPackages (ps: [
      (pyside6 ps)
      ps.shiboken6
      (vhacdx ps)
    ])).overrideAttrs
      { pname = "blender"; };

  blenderVersion = lib.versions.majorMinor pkgsBlender.blender.version;
in
{
  home.packages = [ blender ];

  home.file.".config/blender/${blenderVersion}/scripts/addons/EnfusionBlenderTools".source =
    config.lib.file.mkOutOfStoreSymlink enfusionBlenderTools;
}
