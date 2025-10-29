## A shell prompt customizer (https://starship.rs/)
{lib, ...}: {
  programs.starship = let
    ## Group some of the modules.
    environment = [
      "$nix_shell"
      "$guix_shell"
    ];
    language = [
      "$c"
      "$cmake"
      "$cobol"
      "$daml"
      "$dart"
      "$deno"
      "$dotnet"
      "$elixir"
      "$elm"
      "$erlang"
      "$fennel"
      "$golang"
      "$haskell"
      "$haxe"
      "$helm"
      "$java"
      "$julia"
      "$kotlin"
      "$gradle"
      "$lua"
      "$nim"
      "$nodejs"
      "$ocaml"
      "$opa"
      "$perl"
      "$php"
      "$pulumi"
      "$purescript"
      "$python"
      "$raku"
      "$rlang"
      "$red"
      "$ruby"
      "$rust"
      "$scala"
      "$solidity"
      "$swift"
      "$terraform"
      "$vlang"
      "$vagrant"
      "$zig"
    ];
    vcs = [
      "$pijul_channel"
      "$vcsh"
      "$fossil_branch"
      "$git_branch"
      "$git_commit"
      "$git_state"
      "$git_metrics"
      "$git_status"
      "$hg_branch"
    ];

    ## This just converts https://starship.rs/presets/nerd-font to Nix.
    nerdFontPreset = {
      aws.symbol = "  ";
      buf.symbol = " ";
      bun.symbol = " ";
      c.symbol = " ";
      cpp.symbol = " ";
      cmake.symbol = " ";
      conda.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      deno.symbol = " ";
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fossil_branch.symbol = " ";
      gcloud.symbol = "  ";
      git_branch.symbol = " ";
      git_commit.tag_symbol = "  ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      ocaml.symbol = " ";
      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CachyOS = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        Nobara = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      pixi.symbol = "󰏗 ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      swift.symbol = " ";
      zig.symbol = " ";
      gradle.symbol = " ";
    };
  in {
    enable = true;
    settings =
      ## TODO: This probably needs to do a recursive merge, so my own settings
      ##       don’t trample them (unless I explicitly set the same field).
      nerdFontPreset
      // {
        directory.truncate_to_repo = false;
        format = lib.concatStrings (
          [
            "$username"
            "$hostname"
            "$localip"
            "$directory"
          ]
          ++ vcs
          ++ environment
          ++ language
          ++ ["$all"]
        );
        hostname = {
          ssh_symbol = "";
          ## TODO: Ideally the “:” would appear whenever there’s _anything_
          ##       before the path, likethe local non-logged-in user.
          format = "[$ssh_symbol$hostname]($style):";
        };
        nix_shell = {
          format = "[$symbol$state]($style) ";
          heuristic = true;
          impure_msg = "!";
          pure_msg = "";
          # Just removes the trailing space (which would be better in the
          # `format`, IMO) from the Nerd Fonts variant.
          symbol = "";
          unknown_msg = "?";
        };
        pijul_channel.disabled = false;
        shlvl = {
          disabled = false;
          symbol = "🪆";
        };
        ## TODO: Ideally the “@” would only appear when there’s a hostname, but
        ##       we need _something_ to separate the user from the path.
        ## TODO: Would like to use the ‘BUST IN SILHOUETTE’ emoji instead of the
        ##       actual username, but on macOS that codepoint gets Mac styling,
        ##       which doesn’t allow coloring (and setting this on remote Linux
        ##       machines doesn’t help because it still gets rendered by the
        ##       client-side Mac. Also, would be great if an ssh user could be
        ##       elided if it matches the local username.
        username.format = "[$user]($style)@";
      };
  };
}
