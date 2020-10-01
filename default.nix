let
  nixpkgsPin = {
    url = https://github.com/nixos/nixpkgs/archive/07e5844fdf6fe99f41229d7392ce81cfe191bcfc.tar.gz;
    sha256 = "0p2z6jidm4rlp2yjfl553q234swj1vxl8z0z8ra1hm61lfrlcmb9";
  };
  pkgs = import (builtins.fetchTarball nixpkgsPin) {};
in

pkgs.stdenv.mkDerivation rec {
  name = "gtk-diagrams";
  src = ./.;
  buildInputs = [
    (pkgs.haskell.packages.ghc884.ghcWithPackages (p: [
      p.gi-gtk
      p.cairo
      p.diagrams-cairo
    ]))
    pkgs.cabal-install
    pkgs.pkgconfig
    pkgs.gtk3
    pkgs.gobject-introspection
  ];
  libPath = pkgs.lib.makeLibraryPath buildInputs;
  shellHook = ''
    export LD_LIBRARY_PATH=${libPath}:$LD_LIBRARY_PATH
    export LANG=en_US.UTF-8
  '';
  LOCALE_ARCHIVE =
    if pkgs.stdenv.isLinux
    then "${pkgs.glibcLocales}/lib/locale/locale-archive"
    else "";
}
