{ pkgs
, system ? builtins.currentSystem
, config ? { }
, sources
, enableHaskellProfiling
}:
let
  inherit (pkgs) stdenv;

  gitignore-nix =
    if builtins ? currentSystem
    then pkgs.callPackage sources.gitignore-nix { }
    else {
      gitignoreFilter = _: builtins.trace "not running gitignoreFilter in pure-eval mode" (_: _: true);
      gitignoreSource = x: builtins.trace "not running gitignoreFilter in pure-eval mode" x;
    };
  # { index-state, compiler-nix-name, project, projectPackages, packages, extraPackages }
  haskell = pkgs.callPackage ./haskell {
    inherit gitignore-nix sources;
    inherit enableHaskellProfiling;
    libsecp256k1 = pkgs.secp256k1;

    # This ensures that the utility scripts produced in here will run on the current system, not
    # the build system, so we can run e.g. the darwin ones on linux
    inherit (pkgs.evalPackages) writeShellScript;
  };

  #
  # additional haskell packages from ./nix/pkgs/haskell-extra
  #
  exeFromExtras = x: haskell.extraPackages."${x}".components.exes."${x}";
  cabal-install = haskell.extraPackages.cabal-install.components.exes.cabal;
  cardano-repo-tool = exeFromExtras "cardano-repo-tool";
  stylish-haskell = exeFromExtras "stylish-haskell";
  cabal-fmt = exeFromExtras "cabal-fmt";
  hlint = exeFromExtras "hlint";
  haskell-language-server = exeFromExtras "haskell-language-server";
  haskell-language-server-wrapper = pkgs.writeShellScriptBin "haskell-language-server-wrapper" ''${haskell-language-server}/bin/haskell-language-server "$@"'';
  hie-bios = exeFromExtras "hie-bios";

  #
  # dev convenience scripts
  #
  fixCabalFmt = pkgs.callPackage ./fix-cabal-fmt { inherit cabal-fmt; };
  fixStylishHaskell = pkgs.callPackage ./fix-stylish-haskell { inherit stylish-haskell; };
  fixPngOptimization = pkgs.callPackage ./fix-png-optimization { };

  #
  # sphinx python packages
  #
  sphinx-markdown-tables = pkgs.python3Packages.callPackage ./sphinx-markdown-tables { };
  sphinxemoji = pkgs.python3Packages.callPackage ./sphinxemoji { };

  scriv = pkgs.python3Packages.callPackage ./scriv { };

  # By default pre-commit-hooks.nix uses its own pinned version of nixpkgs. In order to
  # to get it to use our version we have to (somewhat awkwardly) use `nix/default.nix`
  # to which both `nixpkgs` and `system` can be passed.
  nix-pre-commit-hooks = (pkgs.callPackage (sources.pre-commit-hooks-nix + "/nix/default.nix") {
    inherit system;
    inherit (sources) nixpkgs;
  });

  # sphinx haddock support
  sphinxcontrib-haddock = pkgs.callPackage (sources.sphinxcontrib-haddock) { pythonPackages = pkgs.python3Packages; };

  # combined haddock documentation for all public plutus libraries
  plutus-haddock-combined =
    let
      haddock-combine = pkgs.callPackage (sources.plutus-core + "/nix/lib/haddock-combine.nix") {
        ghc = haskell.projectAllHaddock.pkg-set.config.ghc.package;
        inherit (sphinxcontrib-haddock) sphinxcontrib-haddock;
      };
    in
    pkgs.callPackage (sources.plutus-core + "/nix/pkgs/plutus-haddock-combined") {
      inherit haskell haddock-combine;
      inherit (pkgs) haskell-nix;
    };

  # Collect everything to be exported under `plutus-apps.lib`: builders/functions/utils
  lib = rec {
    inherit gitignore-nix;
    haddock-combine = pkgs.callPackage (sources.plutus-core + "/nix/lib/haddock-combine.nix") { inherit sphinxcontrib-haddock; };
  };

in
{
  inherit sphinx-markdown-tables sphinxemoji sphinxcontrib-haddock;
  inherit scriv;
  inherit nix-pre-commit-hooks;
  inherit haskell cabal-install cardano-repo-tool stylish-haskell hlint haskell-language-server haskell-language-server-wrapper hie-bios cabal-fmt;
  inherit fixStylishHaskell fixCabalFmt fixPngOptimization;
  inherit plutus-haddock-combined;
  inherit lib;
}
