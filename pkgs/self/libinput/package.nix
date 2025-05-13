{ pkgs, ... }:
let
  version = "1.28.1";
in
pkgs.libinput.overrideAttrs (
  _finalAttrs: _prevAttrs: {
    version =
      if _prevAttrs.version != "1.27.1" then
        builtins.warn ''
          Please note! libinput in nixpkgs has bumped version to ${_prevAttrs.version}
        '' version
      else
        version;

    src = pkgs.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "libinput";
      repo = "libinput";
      rev = _finalAttrs.version;
      hash = "sha256-kte5BzGEz7taW/ccnxmkJjXn3FeikzuD6Hm10l+X7c0=";
    };

    patches = _prevAttrs.patches or [ ] ++ [
      ./0001-gestures-fix-acceleration-in-3fg-drag.patch
      ./0002-enable-3fg-drag-by-default.patch
    ];
  }
)
