# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  alist = {
    pname = "alist";
    version = "v3.35.0";
    src = fetchFromGitHub {
      owner = "alist-org";
      repo = "alist";
      rev = "v3.35.0";
      fetchSubmodules = false;
      sha256 = "sha256-N9WgaPzc8cuDN7N0Ny3t6ARGla0lCluzF2Mut3Pg880=";
    };
  };
  cyrus-imapd = {
    pname = "cyrus-imapd";
    version = "cyrus-imapd-3.8.3";
    src = fetchFromGitHub {
      owner = "cyrusimap";
      repo = "cyrus-imapd";
      rev = "cyrus-imapd-3.8.3";
      fetchSubmodules = false;
      sha256 = "sha256-LK5mmtVxr6ljwqhaCA8g2bgxxSF0z1G8pbhnH2Idj3k=";
    };
  };
}
