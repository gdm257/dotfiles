{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  programs.vscode = {
    # FIXME
    enable = false;
    package = pkgs.vscodium;
    extensions =
      let
        pkgs-vscode-extensions = with pkgs.vscode-extensions; [ ];
        vscode-marketplace-release-extensions = with inputs.nix-vscode-extensions.extensions.${globals.system}.vscode-marketplace-release; [ ];
        vscode-marketplace-extensions = with inputs.nix-vscode-extensions.extensions.${globals.system}.vscode-marketplace; [
          # assembly
          dan-c-underwood.arm
          platformio.platformio-ide
          cl.eide
          # "13xforever".language-x86-64-assembly

          # c/c++
          bbenoist.doxygen
          cschlosser.doxdocgen
          jeff-hykin.better-cpp-syntax
          xaver.clang-format
          llvm-vs-code-extensions.vscode-clangd
          ms-vscode.cmake-tools
          twxs.cmake
          vadimcn.vscode-lldb
          ms-vscode.makefile-tools
          tboox.xmake-vscode

          # rust
          fill-labs.dependi
          rust-lang.rust-analyzer
          vadimcn.vscode-lldb

          # go
          golang.go
          xiaoxin-technology.goctl

          # web - js/ts/css/html
          anbuselvanrocky.bootstrap5-vscode
          antfu.iconify
          astro-build.astro-vscode
          bradlc.vscode-tailwindcss
          aaravb.chrome-extension-developer-tools
          burkeholland.simple-react-snippets
          christian-kohler.npm-intellisense
          christian-kohler.path-intellisense
          cipchk.cssrem
          dbaeumer.vscode-eslint
          donjayamanne.jquerysnippets
          abhipatel.jquery-snippets
          dsznajder.es7-react-js-snippets
          ecmel.vscode-html-css
          esbenp.prettier-vscode
          firefox-devtools.vscode-firefox-debug
          hollowtree.vue-snippets
          mariusschulz.yarn-lock-syntax
          ms-vscode.live-server
          ritwickdey.liveserver
          swmansion.react-native-ide
          msjsdiag.vscode-react-native
          octref.vetur
          otovo-oss.htmx-tags
          pcbowers.alpine-intellisense
          pranaygp.vscode-css-peek
          rvest.vs-code-prettier-eslint
          humao.rest-client
          sdras.vue-vscode-snippets
          orta.vscode-jest
          vue.volar
          # wallabyjs.quokka-vscode
          xabikos.javascriptsnippets
          zignd.html-css-class-completion
          yoavbls.pretty-ts-errors
          # youngjuning.yarn-lock-preview
          zxh404.vscode-proto3

          # jvm - java/kotlin/scala/clojure
          betterthantomorrow.calva-spritz
          betterthantomorrow.calva
          vscjava.vscode-java-pack
          fwcd.kotlin
          scalameta.metals
          scala-lang.scala
          sonarsource.sonarlint-vscode
          vmware.vscode-boot-dev-pack

          # lua
          sumneko.lua
          actboy168.lua-debug

          # matlab
          affenwiesel.matlab-formatter
          apommel.matlab-interactive-terminal
          bat67.matlab-extension-pack

          # lisp
          mattn.lisp

          # nix
          pinage404.nix-extension-pack

          # .net - c#/f#/powershell
          ms-dotnettools.vscodeintellicode-csharp
          ionide.ionide-fsharp
          ms-vscode.powershell
          ms-dotnettools.dotnet-interactive-vscode

          # php
          zobo.php-intellisense
          xdebug.php-debug
          xdebug.php-pack

          # python
          ms-python.python
          ms-python.vscode-pylance
          ms-python.debugpy
          # gaogaotiantian.coredumpy-vscode
          njpwerner.autodocstring
          rodolphebarbanneau.python-docstring-highlighter
          seanwu.vscode-qt-for-python
          ericsia.pythonsnippets3
          # "076923".python-image-preview
          batisteo.vscode-django
          junstyle.vscode-django-support
          samuelcolvin.jinjahtml
          battlebas.kivy-vscode
          marimo-team.vscode-marimo
          ms-toolsai.jupyter
          ms-python.mypy-type-checker
          charliermarsh.ruff
          ms-python.vscode-python-envs

          # devops
          redhat.ansible
          mrmlnc.vscode-apache
          ahmadalli.vscode-nginx-conf
          raynigon.nginx-formatter
          eiminsasete.apacheconf-snippets
          thqby.vscode-autohotkey2-lsp
          rogalmic.bash-debug
          mads-hartmann.bash-ide-vscode
          jeff-hykin.better-dockerfile-syntax
          # srl-labs.vscode-containerlab
          jeff-hykin.better-shellscript-syntax
          samuelcolvin.jinjahtml
          matthewpi.caddyfile-support
          formulahendry.code-runner
          dbcode.dbcode
          ms-azuretools.vscode-docker
          p1c2u.docker-compose
          exiasr.hadolint
          maarti.jenkins-doc
          # ivory-lab.jenkinsfile-support
          ms-kubernetes-tools.vscode-kubernetes-tools
          berublan.vscode-log-viewer
          xshrim.txt-syntax
          meronz.manpages
          okteto.remote-kubernetes
          asciidoctor.asciidoctor-vscode
          tetradresearch.vscode-h2o
          woozy-masta.shell-script-ide
          foxundermoon.shell-format
          timonwong.shellcheck
          remisa.shellman
          hangxingliu.vscode-systemd-support
          bbenoist.vagrant
          # marcostazi.vs-code-vagrantfile

          # ==== common ====

          # ai
          github.copilot
          github.copilot-chat
          # ms-vscode.vscode-websearchforcopilot
          # ms-vscode.copilot-mermaid-diagram
          # cpulvermacher.lgtm
          # vscjava.migrate-java-to-azure

          # kilocode.kilo-code
          marscode.marscode-extension

          # vim
          asvetliakov.vscode-neovim
          # vscodevim.vim

          # snippets
          visualstudioexptteam.intellicode-api-usage-examples
          visualstudioexptteam.vscodeintellicode
          vscode-snippet.snippet
          zjffun.snippetsmanager
          inu1255.easy-snippet
          antonreshetov.masscode-assistant

          # docs/notes
          deerawan.vscode-dash
          gruntfuggly.todo-tree
          codediagram.codediagram
          alefragnani.bookmarks
          alefragnani.project-manager

          # git
          mhutchie.git-graph
          donjayamanne.githistory
          pomber.git-file-history
          moshfeu.compare-folders
          eamodio.gitlens
          adam-bender.commit-message-editor
          github.vscode-github-actions
          github.vscode-pull-request-github
          github.remotehub

          # remote
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          # ms-vscode-remote.remote-wsl
          ms-vscode-remote.vscode-remote-extensionpack
          ms-vscode.azure-repos
          ms-vscode.remote-explorer
          ms-vscode.remote-repositories
          ms-vscode.remote-server
          kelvin.vscode-sshfs

          # theme
          unthrottled.doki-theme
          emmanuelbeziat.vscode-great-icons

          # funny
          # alexshenvscode.vscode-osu
          # hoovercj.vscode-power-mode
          # ezshine.rainbow-fart-waifu
          # deepred.daily-anime

          # others
          editorconfig.editorconfig
          emilast.logfilehighlighter
          grapecity.gc-excelviewer
          hediet.debug-visualizer
          jock.svg
          ms-vscode.vscode-speech
          mutantdino.resourcemonitor
          quicktype.quicktype
          redhat.vscode-yaml
          ryu1kn.edit-with-shell
          shardulm94.trailing-spaces
          shd101wyy.markdown-preview-enhanced
          sleistner.vscode-fileutils
          tamasfe.even-better-toml
          usernamehw.errorlens
          yutengjing.open-in-external-app
          yzhang.markdown-all-in-one
          rszyma.vscode-kanata
        ];
        open-vsx-release-extensions = with inputs.nix-vscode-extensions.extensions.${globals.system}.open-vsx-release; [ ];
        open-vsx-extensions = with inputs.nix-vscode-extensions.extensions.${globals.system}.open-vsx; [ ];
      in
        pkgs-vscode-extensions
        ++ vscode-marketplace-release-extensions
        ++ vscode-marketplace-extensions
        ++ open-vsx-release-extensions
        ++ open-vsx-extensions
      ;
    mutableExtensionsDir = true;
    userTasks = { };
    globalSnippets = { };
    languageSnippets = { };
    haskell.enable = false;
    haskell.hie.enable = false;
  };
  programs.vscode.userSettings = {
    # ==== Format specific ====
    "[markdown]" = {
      "editor.codeLens" = false;
      "editor.fontFamily" = "'LXGW WenKai Mono', 'Sarasa Mono SC'";
      "editor.fontSize" = 20.5;
      "editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
    };
    "[json]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };
    "[yaml]" = {
      "editor.tabSize" = 2;
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "vscode.typescript-language-features";
    };
    "[javascript]" = {
      "editor.defaultFormatter" = "vscode.typescript-language-features";
    };
    "[css]" = {
      "editor.defaultFormatter" = "vscode.css-language-features";
    };
    "[html]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.wordWrap" = "on";
    };
    "[jinja-html]" = {
      "editor.tabSize" = 2;
    };
    "[django-html]" = {
      "editor.wordWrap" = "on";
      "editor.quickSuggestions" = {
        "other" = true;
        "comments" = true;
        "strings" = true;
      };
      "editor.tabSize" = 2;
      "editor.defaultFormatter" = "junstyle.vscode-django-support";
    };
    # ==== AI ====
    "intelephense.files.exclude" = [
      "**/.hg/**"
      "**/CVS/**"
      "**/.DS_Store/**"
      "**/node_modules/**"
      "**/bower_components/**"
      "**/vendor/**/{Tests,tests}/**"
      "**/.history/**"
      "**/vendor/**/vendor/**"
    ];
    "path-intellisense.showHiddenFiles" = true;
    "Codegeex.Privacy" = false;
    "CodeGPT.query.language" = "Chinese";
    "codium.enable" = true;
    "github.copilot.chat.generateTests.codeLens" = true;
    "github.copilot.codesearch.enabled" = true;
    "github.copilot.nextEditSuggestions.enabled" = true;
    "githubPullRequests.experimental.chat" = true;
    "githubPullRequests.experimental.useQuickChat" = true;
    "tabnine.experimentalAutoImports" = true;
    # ==== Git (built-in) ====
    "git.closeDiffOnOperation" = true;
    "git.ignoreLegacyWarning" = true;
    # ==== Git ====
    "githubIssues.queries" = [
      {
        "label" = "My Issues";
        "query" = "default";
      }
      {
        "label" = "Created Issues";
        "query" = "author:${user} state:open repo:${owner}/${repository} sort:created-desc";
      }
      {
        "label" = "Recent Issues";
        "query" = "state:open repo:${owner}/${repository} sort:updated-desc";
      }
    ];
    "gitlens.currentLine.enabled" = false;
    "gitlens.advanced.messages" = {
      "suppressGitVersionWarning" = true;
    };
    # ==== Markdown (built-in) ====
    "markdown.preview.fontSize" = 16;
    # ==== Markdown ====
    "markdown-preview-enhanced.previewTheme" = "monokai.css";
    # ==== Java ====
    "java.codeGeneration.generateComments" = true;
    "java.codeGeneration.useBlocks" = true;
    "java.debug.logLevel" = "info";
    "java.maven.downloadSources" = true;
    "kotlin.debugAdapter.enabled" = false;
    "kotlin.languageServer.enabled" = false;
    "maven.pomfile.autoUpdateEffectivePOM" = true;
    # ==== JS/TS (built-in) ====
    "typescript.suggest.paths" = true;
    # ==== LaTeX ====
    "latex-workshop.bibtex-format.tab" = "4 spaces";
    "latex-workshop.latex.autoClean.run" = "onFailed";
    "latex-workshop.latex.recipe.default" = "lastUsed";
    "latex-workshop.view.pdf.viewer" = "tab";
    # ==== Python (built-in) ====
    "notebook.cellToolbarLocation" = {
      "default" = "right";
      "jupyter-notebook" = "left";
      "runme" = "right";
    };
    "notebook.lineNumbers" = "on";
    "notebook.outline.showCodeCells" = true;
    # ==== Python ====
    "black-formatter.args" = [
      "--skip-string-normalization"
    ];
    "isort.args" = [
      "--profile"
      "black"
    ];
    "isort.logLevel" = "debug";
    "jupyter.interactiveWindow.textEditor.autoAddNewCell" = false;
    "jupyter.interactiveWindow.textEditor.autoMoveToNextCell" = false;
    "python.condaPath" = "micromamba";
    "python.createEnvironment.contentButton" = "show";
    "python.autoComplete.extraPaths" = [
      "__pypackages__/2.7/lib"
      "__pypackages__/3.4/lib"
      "__pypackages__/3.5/lib"
      "__pypackages__/3.6/lib"
      "__pypackages__/3.7/lib"
      "__pypackages__/3.8/lib"
      "__pypackages__/3.9/lib"
      "__pypackages__/3.10/lib"
      "__pypackages__/3.11/lib"
      "__pypackages__/3.12/lib"
      "__pypackages__/3.13/lib"
      "__pypackages__/3.14/lib"
      "__pypackages__/3.15/lib"
      "__pypackages__/3.16/lib"
      "__pypackages__/3.17/lib"
      "__pypackages__/3.18/lib"
      "__pypackages__/3.19/lib"
      "__pypackages__/3.20/lib"
      "__pypackages__/3.21/lib"
      "__pypackages__/3.22/lib"
      "__pypackages__/3.23/lib"
      "__pypackages__/3.24/lib"
      "__pypackages__/3.25/lib"
      "__pypackages__/3.26/lib"
      "__pypackages__/3.27/lib"
      "__pypackages__/3.28/lib"
      "__pypackages__/3.29/lib"
      "__pypackages__/3.30/lib"
      "__pypackages__/3.31/lib"
      "__pypackages__/3.32/lib"
      "__pypackages__/3.33/lib"
    ];
    # ==== UI (built-in) ====
    "debug.console.wordWrap" = false;
    "diffEditor.experimental.showMoves" = true;
    "editor.bracketPairColorization.enabled" = true;
    "editor.find.autoFindInSelection" = "multiline";
    "editor.fontFamily" = "'JetBrains Mono', Sarasa Mono SC, monospace";
    "editor.fontSize" = 18;
    "editor.guides.highlightActiveIndentation" = "always";
    "editor.renderControlCharacters" = true;
    "editor.renderLineHighlight" = "gutter";
    "editor.renderWhitespace" = "none";
    "editor.roundedSelection" = false;
    "editor.scrollbar.vertical" = "visible";
    "editor.unicodeHighlight.ambiguousCharacters" = false;
    "editor.unicodeHighlight.invisibleCharacters" = false;
    "editor.wordWrap" = "off";
    "editor.minimap.enabled" = false;
    "editor.cursorSmoothCaretAnimation" = "off";
    "explorer.autoReveal" = false;
    "explorer.copyRelativePathSeparator" = "/";
    "scm.inputFontSize" = 17;
    "window.zoomLevel" = 1.5;
    "workbench.colorTheme" = "Monokai";
    "workbench.iconTheme" = "vscode-great-icons";
    # ==== UI ====
    "background.style" = {
      "opacity" = 0.95;
    };
    "background.useFront" = false;
    "osumode.enableCursorExplosions" = false;
    "osumode.explosionSize" = 3;
    "osumode.comboImageInterval" = 25;
    "osumode.enableComboCounter" = false;
    # ==== Others (built-in) ====
    "files.associations" = {
      "*.cheat" = "shellscript";
    };
    "files.eol" = "\n";
    "files.exclude" = {
      "**/.git" = false;
      "**/.svn" = false;
    };
    "json.maxItemsComputed" = 5001;
    "remote.defaultExtensionsIfInstalledLocally" = [
      "GitHub.copilot"
      "GitHub.copilot-chat"
      "GitHub.vscode-pull-request-github"
    ];
    "terminal.integrated.allowChords" = false;
    "terminal.integrated.copyOnSelection" = true;
    "terminal.integrated.defaultProfile.windows" = "PowerShell";
    "terminal.integrated.fontSize" = 17;
    "terminal.integrated.profiles.windows" = {
      "Bash" = {
        "icon" = "terminal-linux";
        "path" = "cmd";
        "args" = [
          "/c"
          "%GIT_INSTALL_ROOT%\\bin\\sh"
          "--login"
          "-i"
        ];
      };
      "PowerShell Core" = {
        "icon" = "terminal-powershell";
        "path" = "pwsh";
      };
      "CMD" = {
        "icon" = "terminal-cmd";
        "path" = "cmd";
      };
    };
    "terminal.integrated.rightClickBehavior" = "default";
    "terminal.integrated.scrollback" = 32000;
    "security.workspace.trust.enabled" = false;
    "update.enableWindowsBackgroundUpdates" = false;
    "update.mode" = "manual";
    "window.doubleClickIconToClose" = true;
    "window.newWindowDimensions" = "offset";
    "workbench.editorAssociations" = {
      "*.html" = "default";
    };
    "workbench.startupEditor" = "none";
    "workbench.tree.expandMode" = "singleClick";
    "window.restoreWindows" = "none";
    # ==== Others ====
    "redhat.telemetry.enabled" = false;
    "resmon.disk.format" = "Remaining";
    "resmon.show.battery" = false;
    "resmon.show.cpufreq" = false;
    "resmon.show.mem" = false;
    "settingsSync.ignoredExtensions" = [
      "lhl2617.vslilypond"
    ];
    "settingsSync.ignoredSettings" = [
      "black-formatter.interpreter"
      "-window.zoomLevel"
      "terminal.integrated.profiles.windows"
      "http.proxy"
      "projectManager.git.baseFolders"
      "ahk++.file.interpreterPathV2"
      "AutoHotkey2.InterpreterPath"
      "AutoHotkey2.CompilerCMD"
      "terminal.integrated.fontFamily"
      "terminal.integrated.fontSize"
      "ahk++.file.interpreterPathV1"
      "ahk++.file.helpPathV2"
      "ahk++.file.helpPathV1"
      "ahk++.file.compilerPath"
    ];
    "vscode-office.previewCode" = false;
    "vscode-office.viewAbsoluteLocal" = true;
    "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
    "yaml.maxItemsComputed" = 30000;
    "sqltools.results.limit" = 100;
    "bangumiOpen.EnableReminder" = false;
    "errorLens.excludeByMessage" = [
      "unknown word"
    ];
    "makefile.configureOnOpen" = true;
    "vim.camelCaseMotion.enable" = true;
    "vim.easymotion" = true;
    "vim.targets.enable" = true;
    "vim.sneak" = true;
    "vim.sneakReplacesF" = true;
    "vim.sneakUseIgnorecaseAndSmartcase" = true;
    "vim.foldfix" = true;
    "vim.incsearch" = true;
    "vim.showMarksInGutter" = true;
    "vim.useSystemClipboard" = true;
    "vim.matchpairs" = "(:),{:},[:],<:>,（:）,《:》,【:】,「:」,『:』,＜:＞,［:］,｛:｝,\":\",＂:＂";
    "vim.leader" = "<space>";
    "vim.useCtrlKeys" = true;
    "vim.handleKeys" = {
        "<C-j>" = false;
        "<C-k>" = false;
        "<C-s>" = false;
    };
    "vim.normalModeKeyBindings" = [
        {
            "before" = [":"];
            "commands" = ["vim.showQuickpickCmdLine"];
            "when" = "editorTextFocus && vim.mode != 'Insert'";
        }
    ];
    "vim.visualModeKeyBindings" = [
        {
            "before" = [">"];
            "commands" = ["editor.action.indentLines"];
        }
        {
            "before" = ["<"];
            "commands" = ["editor.action.outdentLines"];
        }
    ];
    "vim.insertModeKeyBindings" = [
        {
            "before" = ["j" "j"];
            "after" = ["<Esc>"];
        }
        {
            "before" = ["j" "k"];
            "after" = ["<Esc>"];
            "commands" = ["workbench.action.files.save"];
        }
        {
            "before" = ["<C-c>"];
            "commands" = ["editor.action.clipboardCopyAction"];
        }
        {
            "before" = ["<C-x>"];
            "commands" = ["editor.action.clipboardCutAction"];
        }
        {
            "before" = ["<C-w>"];
            "commands" = ["workbench.action.closeActiveEditor"];
        }
    ];
  };
  programs.vscode.keybindings = [
    {
      key = "ctrl+p";
      command = "workbench.action.showCommands";
    }
    {
      key = "ctrl+shift+p";
      command = "workbench.action.quickOpen";
    }
    {
      key = "ctrl+shift+p";
      command = "workbench.action.quickOpenNavigateNextInFilePicker";
      when = "inFilesPicker && inQuickOpen";
    }
    {
      key = "ctrl+tab";
      command = "workbench.action.nextEditor";
    }
    {
      key = "ctrl+shift+tab";
      command = "workbench.action.previousEditor";
    }
    {
      key = "ctrl+oem_plus";
      command = "-workbench.action.zoomIn";
    }
    {
      key = "ctrl+oem_minus";
      command = "-workbench.action.zoomOut";
    }
    {
      key = "ctrl+shift+oem_minus";
      command = "-workbench.action.zoomOut";
    }
    {
      key = "ctrl+numpad_subtract";
      command = "-workbench.action.zoomOut";
    }
    {
      key = "ctrl+shift+oem_plus";
      command = "-workbench.action.zoomIn";
    }
    {
      key = "ctrl+numpad_add";
      command = "-workbench.action.zoomIn";
    }
    {
      key = "ctrl+numpad0";
      command = "-workbench.action.zoomReset";
    }
    {
      key = "alt+p";
      command = "workbench.action.showCommands";
    }
    {
      key = "alt+k h";
      command = "editor.action.triggerSuggest";
      when = "editorHasCompletionItemProvider && textInputFocus && !editorReadonly";
    }
    {
      key = "alt+k h";
      command = "toggleSuggestionDetails";
      when = "suggestWidgetVisible && textInputFocus";
    }
    {
      key = "alt+k p";
      command = "editor.action.triggerParameterHints";
      when = "editorHasSignatureHelpProvider && editorTextFocus";
    }
    {
      key = "alt+k p";
      command = "issue.suggestRefresh";
      when = "suggestWidgetVisible";
    }
    {
      key = "alt+k b";
      command = "workbench.action.toggleSidebarVisibility";
    }
    {
      key = "alt+k shift+b";
      command = "workbench.action.toggleAuxiliaryBar";
    }
  ];
}
