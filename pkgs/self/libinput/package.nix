{ pkgs, ... }:
pkgs.libinput.overrideAttrs (
  _finalAttrs: _prevAttrs: {
    patches = _prevAttrs.patches or [ ] ++ [
      ./0001-gestures-fix-acceleration-in-3fg-drag.patch
      ./0002-enable-3fg-drag-by-default.patch
    ];
  }
)
