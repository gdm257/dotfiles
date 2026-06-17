{
  inputs,
  outputs,
  globals,
  lib,
  config,
  pkgs,
  ...
}:
let
  init_extra = ''
    [ ! -f "$HOMEBREW_PREFIX/bin/brew" ] || eval "$($HOMEBREW_PREFIX/bin/brew shellenv)";
    [ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" && [ -f "$HOME/.nix-profile/bin/," ] && unalias ,;
  '';
in
{
  home.shellAliases = {
    ".." = "cd ..";
    "..." = "cd ../..";
  };
  home.sessionVariables = {
    HOMEBREW_PREFIX =
      let
        isLinux = pkgs.stdenv.isLinux;
        isDarwin = pkgs.stdenv.isDarwin;
        isAarch64 = pkgs.stdenv.isAarch64; # Apple Silicon
      in
        if isDarwin then
          if isAarch64 then "/opt/homebrew"
          else "/usr/local"
        else "/home/linuxbrew/.linuxbrew";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
    "${config.home.sessionVariables.HOMEBREW_PREFIX}/bin"
    "${config.home.sessionVariables.HOMEBREW_PREFIX}/sbin"
  ];

  # ==== Shell programs ====
  programs.bash = {
    enable = true;
    historySize = 70000;
    historyIgnore = [
      "cd"
      "clear"
      "exit"
      "ls"
      "pwd"
    ];
    sessionVariables = { };
    shellAliases = { };
    profileExtra = "";
    initExtra = ''
      ${init_extra}
    '';
    bashrcExtra = "";
    logoutExtra = "";
  };
  programs.zsh = {
    enable = true;
    autocd = false;
    cdpath = [ ];
    shellAliases = { };
    shellGlobalAliases = { };
    dirHashes = {
      docs = "$HOME/Documents";
      vids = "$HOME/Videos";
      dl = "$HOME/Downloads";
    };
    zprof.enable = false;
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
        # "match_prev_cmd"
      ];
    };
    history = {
      save = 65536;
    };
    defaultKeymap = null; # "emacs" "viins" "vicmd"
    sessionVariables = { };
    initContent =
      let
        _initExtraFirst = lib.mkOrder 500 ''
        '';
        _initExtraBeforeCompInit = lib.mkOrder 550 ''
        '';
        _initExtra = lib.mkOrder 1000 ''
          ${init_extra}

          # Prompt
          _zsh_auto_shorten_path() {
            local min_length=20
            local max_length=$(( COLUMNS * 60 / 100 ))
            local current_path="$(eval 'print -P "%~"')"
            local current_length=''${#current_path} # nix escape
            if (( COLUMNS < min_length )); then
              echo "%1~"
            elif (( current_length > max_length )); then
              echo "%(4~|%-1~/…/%2~|%~)"
            else
              echo "$1"
            fi
          }
          setopt prompt_subst
          _zsh_update_prompt() {
            PS1='
          %F{#3465A4}┌──(%f%F{#AD7FA8}%n㉿%m%f%F{#3465A4}%)-[%f%F{yellow}$(_zsh_auto_shorten_path "%~")%f%F{#3465A4}]%f
          %F{#3465A4}└──%f%(?.🟢 %F{#16C60C}%(!.#.>)%f.🔴 %F{red}%(!.#.>)%f) '
          }
          add-zsh-hook precmd _zsh_update_prompt
        '';
        _initMkAfeter = lib.mkOrder 1500 ''
        '';
      in
        lib.mkMerge [ _initExtraFirst _initExtraBeforeCompInit _initExtra _initMkAfeter ]
    ;
    envExtra = "";
    profileExtra = "";
    loginExtra = "";
    logoutExtra = "";
    localVariables = { };
    plugins = [ ];
    oh-my-zsh = { };
    prezto = {
      enable = true;
      caseSensitive = false;
      editor.keymap = "vi"; # vi | emacs
      prompt.theme = "peepcode"; # peepcode | adam2 | adam1
      prompt.pwdLength = "long"; # short | long | full
      prompt.showReturnVal= true;
      syntaxHighlighting.highlighters = [
        "main"
        "brackets"
        "pattern"
        "line"
        "cursor"
        "root"
      ];
      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "spectrum"
        "archive"
        "docker"
        # "utility" # bug: mkdir
        # "completion" # too slow
        # "prompt"
      ];
      # extraModules = [ ];
      # extraFunctions = [ ];
    };
  };
  programs.direnv = {
    enable = false; # disable if mise enables `env_file`
    mise.enable = true;
    config = {
      global.load_dotenv = true;
    };
  };
  programs.mise = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${globals.system}.mise;
    globalConfig = {
      settings = {
        trusted_config_paths = [ "/" ];
        experimental = true;
        env_file = ".env"; # comment if direnv is used
        env_shell_expand = true;
        jobs = 4;
        prefer_offline = true;
        auto_install = false;
        exec_auto_install = true;
        npm.package_manager = "pnpm"; # require mise 2025.12.7+
        pipx.uvx = true;
        python.uv_venv_auto = true;
      };
      tools = {
        node = { version="lts"; postinstall="corepack enable"; };
      };
    };
  };
  programs.man.enable = true;
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      add_newline = true;
      character.success_symbol = "[>](bold green)";
      directory.truncation_length = 10;
      directory.use_os_path_sep = false;
      directory.style = "bold #edc809";
      username.style_user = "green";
      username.style_root = "green";
      username.format = "[\$user](\$style)";
      username.disabled = false;
      username.show_always = true;
      hostname.ssh_only = false;
      hostname.format = "[\$ssh_symbol](bold blue)[@\$hostname](green) ";
      hostname.disabled = false;
      status.style = "red bold";
      status.symbol = "🔴 ";
      status.success_symbol = "🟢 ";
      status.format = "[\$symbol\$signal_name\$maybe_int](\$style)";
      status.map_symbol = true;
      status.disabled = false;
      battery.full_symbol = "🔋 ";
      battery.charging_symbol = "⚡️ ";
      battery.discharging_symbol = "💀 ";
      battery.display = [
        {
          threshold = 50;
          style = "bold red";
        }
      ];
    };
  };
  programs.yazi = {
    enable = true;
    package = pkgs.yazi;
    shellWrapperName = "yy";
    settings =
      {
        mgr = {
          linemode = "size";
          ratio = [1 3 3];
          show_hidden = true;
        };
        preview = {
          image_filter = "lanczos3";
        };
      }
    ;
    keymap =
      {
        input.prepend_keymap = [
          { run = "close"; on = [ "<C-q>" ]; }
        ];
      }
    ;
    theme =
      {
        flavor = { dark = "catppuccin-mocha"; light = "catppuccin-mocha"; use = "catppuccin-mocha"; };
      }
    ;
    flavors =
      let
        repo = pkgs.fetchFromGitHub {
          owner = "yazi-rs";
          repo = "flavors";
          rev = "0f9204bc948c8313963f5c9d571a82edc201f8aa";
          hash = "sha256-qWNArjWuxWL+rOjLzyIniW5hJgWiAWTCgXmMXJpaWZE=";
        };
      in
      {
        catppuccin-frappe = repo + "/catppuccin-frappe.yazi";
        catppuccin-latte = repo + "/catppuccin-latte.yazi";
        catppuccin-macchiato = repo + "/catppuccin-macchiato.yazi";
        catppuccin-mocha = repo + "/catppuccin-mocha.yazi";
      }
    ;
  };
  programs.zellij.enable = true;
  programs.zoxide.enable = true;
  programs.zoxide.enableBashIntegration = true;
  programs.zoxide.enableFishIntegration = true;
  programs.zoxide.enableNushellIntegration = true;
  programs.zoxide.enableZshIntegration = true;
}
