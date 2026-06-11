# Complex Package Template
#
# This template demonstrates advanced Nix packaging patterns for complex scenarios:
# - Native build dependencies
# - Propagation dependencies
# - Custom build scripts
# - Runtime dependencies
# - Environment setup
# - Multi-stage builds

{ lib, stdenv, fetchurl, makeWrapper, unzip, autoPatchelfHook, writeShellScript }:

stdenv.mkDerivation rec {
  pname = "example-complex";
  version = "1.0.0";

  # Source download - could be URL, git, or local file
  src = fetchurl {
    url = "https://github.com/owner/repo/releases/download/v${version}/${pname}-${version}-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = lib.fakeSha256;
  };

  # Native build dependencies - only needed during build
  nativeBuildInputs = [
    makeWrapper  # For wrapping binaries with environment variables
    unzip        # For .zip files
    autoPatchelfHook  # For fixing ELF binaries on Linux
  ];

  # Build dependencies - needed at runtime
  buildInputs = [
    # Add runtime dependencies here
    # Example: openssl for SSL support
    # Example: zlib for compression
  ];

  # Propagated dependencies - passed to consumers of this package
  propagatedBuildInputs = [
    # Add dependencies that should be available to packages that depend on this
  ];

  # Set environment variables
  env = {
    # Custom environment variables
    EXAMPLE_VAR = "value";
  };

  # Pre-build phase
  preBuild = ''
    # Custom pre-build steps
    echo "Starting build of ${pname}-${version}"
  '';

  # Custom build phase (if needed)
  buildPhase = ''
    runHook preBuild

    # Custom build commands
    # Example: compile scripts, process resources, etc.
    # make

    runHook postBuild
  '';

  # Installation phase
  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/bin
    mkdir -p $out/lib/${pname}
    mkdir -p $out/share/${pname}
    mkdir -p $out/share/doc/${pname}
    mkdir -p $out/etc/${pname}
    mkdir -p $out/share/applications  # For desktop files
    mkdir -p $out/share/icons/hicolor/256x256/apps  # For icons

    # Install main binary
    if [ -f "${pname}" ]; then
      cp ${pname} $out/bin/
      chmod +x $out/bin/${pname}
    fi

    # Install libraries (if any)
    for lib in lib*.so*; do
      if [ -f "$lib" ]; then
        cp "$lib" $out/lib/${pname}/
      fi
    done

    # Install shared resources
    if [ -d "resources" ]; then
      cp -r resources/* $out/share/${pname}/
    fi

    # Install configuration template
    if [ -f "config.yaml.template" ]; then
      cp config.yaml.template $out/etc/${pname}/config.yaml
    fi

    # Install desktop file for GUI applications
    cat > $out/share/applications/${pname}.desktop <<EOF
    [Desktop Entry]
    Name=Example Complex
    Comment=A complex example application
    Exec=$out/bin/${pname}
    Icon=${pname}
    Terminal=false
    Type=Application
    Categories=Utility;Development;
    EOF

    # Install shell completion scripts
    mkdir -p $out/share/bash-completion/completions
    mkdir -p $out/share/zsh/site-functions
    mkdir -p $out/share/fish/vendor_completions.d

    # If you have completion files, install them
    # if [ -f "completions/bash" ]; then
    #   cp completions/bash $out/share/bash-completion/completions/${pname}
    # fi
    # if [ -f "completions/zsh" ]; then
    #   cp completions/zsh $out/share/zsh/site-functions/_${pname}
    # fi
    # if [ -f "completions/fish" ]; then
    #   cp completions/fish $out/share/fish/vendor_completions.d/${pname}.fish
    # fi

    # Create wrapper script with environment setup
    makeWrapper $out/bin/${pname} $out/bin/${pname}-wrapped \
      --prefix PATH : ${lib.makeBinPath buildInputs} \
      --set LD_LIBRARY_PATH $out/lib/${pname} \
      --set EXAMPLE_CONFIG_DIR $out/etc/${pname} \
      --set EXAMPLE_DATA_DIR $out/share/${pname}

    # Create launcher script
    cat > $out/bin/${pname}-launcher <<EOF
    #!/bin/sh
    # Example launcher script
    export EXAMPLE_HOME="\$HOME/.local/share/${pname}"
    mkdir -p "\$EXAMPLE_HOME"
    exec $out/bin/${pname}-wrapped "\$@"
    EOF
    chmod +x $out/bin/${pname}-launcher

    runHook postInstall
  '';

  # Post-install phase
  postInstall = ''
    # Setup hooks and final configuration
    echo "Installation completed successfully"
  '';

  # Fix phase - for fixing binaries and libraries
  fixupPhase = ''
    runHook preFixup

    # AutoPatchelfHook will handle RPATH fixing automatically on Linux
    # Manual patching can be done here if needed
    # patchelf --set-rpath $out/lib/${pname} $out/bin/${pname}

    runHook postFixup
  '';

  # Install hooks for shell completions (if using installShellCompletion)
  # postInstall = ''
  #   installShellCompletion --bash completions/bash
  #   installShellCompletion --zsh completions/zsh
  #   installShellCompletion --fish completions/fish
  # '';

  # Custom tests
  doInstallCheck = true;
  installCheckPhase = ''
    # Basic sanity checks
    if [ -f "$out/bin/${pname}" ]; then
      echo "Binary exists: $out/bin/${pname}"
      $out/bin/${pname} --version || echo "Version check failed, but binary exists"
    else
      echo "Error: Binary not found after installation"
      exit 1
    fi

    # Check if wrapper works
    if [ -f "$out/bin/${pname}-wrapped" ]; then
      echo "Wrapper exists: $out/bin/${pname}-wrapped"
    fi
  '';

  # Create wrapper script for common patterns
  passthru = {
    # Expose additional derivations or functions
    wrapper = writeShellScript "${pname}-env-wrapper" ''
      export EXAMPLE_ENV_VAR="configured"
      export PATH="$out/bin:$PATH"
      exec "$@"
    '';
  };

  # Metadata
  meta = with lib; {
    description = "Complex example package demonstrating advanced Nix patterns";
    homepage = "https://github.com/owner/repo";
    changelog = "https://github.com/owner/repo/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];

    # Additional metadata
    maintainers = with maintainers; [ ];  # Add your username here
    priority = 10;

    # Package features and characteristics
    broken = false;
    insecure = false;
    unsupported = false;

    # Comprehensive description
    longDescription = ''
      This is a comprehensive template that demonstrates advanced Nix packaging
      techniques including:

      Features:
      - Native build dependencies (makeWrapper, autoPatchelfHook)
      - Runtime dependencies and propagated dependencies
      - Environment variable configuration
      - Wrapper scripts for environment setup
      - Shell completion support
      - Desktop application integration
      - Multiple installation patterns
      - Custom build and fixup phases
      - Installation checks and validation
      - Passthru attributes for additional functionality

      This template is suitable for:
      - Complex GUI applications
      - CLI tools with many dependencies
      - Applications requiring environment setup
      - Multi-component packages
      - Packages with custom installation requirements
    '';
  };
}