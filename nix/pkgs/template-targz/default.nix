# Tar.gz Archive Package Template
#
# This template is for packages distributed as compressed archives (.tar.gz, .zip, etc.)
# that contain multiple files, directories, or need extraction before installation.
#
# Use Cases:
# - Archives containing multiple binaries
# - Packages with additional assets (docs, examples, etc.)
# - Applications that need specific directory structure
# - Releases with complex file layouts

{ lib, stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "example-archive";
  version = "1.0.0";

  # Platform-specific archive download
  src = fetchzip {
    url = {
      x86_64-linux = "https://github.com/owner/repo/releases/download/v${version}/${pname}-${version}-x86_64-unknown-linux-gnu.tar.gz";
      aarch64-linux = "https://github.com/owner/repo/releases/download/v${version}/${pname}-${version}-aarch64-unknown-linux-gnu.tar.gz";
      x86_64-darwin = "https://github.com/owner/repo/releases/download/v${version}/${pname}-${version}-x86_64-apple-darwin.tar.gz";
      aarch64-darwin = "https://github.com/owner/repo/releases/download/v${version}/${pname}-${version}-aarch64-apple-darwin.tar.gz";
    }.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

    sha256 = {
      x86_64-linux = lib.fakeSha256;
      aarch64-linux = lib.fakeSha256;
      x86_64-darwin = lib.fakeSha256;
      aarch64-darwin = lib.fakeSha256;
    }.${stdenv.hostPlatform.system};

    # Important: Don't strip root directory from the archive if it contains
    # important directory structure
    stripRoot = false;
  };

  # For complex archives, you might need to set sourceRoot
  # sourceRoot = ".";

  # Installation phase for archives
  installPhase = ''
    runHook preInstall

    # Create necessary directories
    mkdir -p $out/bin
    mkdir -p $out/share/${pname}  # For additional files
    mkdir -p $out/share/doc/${pname}  # For documentation
    mkdir -p $out/share/examples/${pname}  # For examples

    # Find the extracted directory (common pattern: version-specific directories)
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "*${pname}*" | head -n 1)
    if [ -z "$EXTRACTED_DIR" ]; then
      # If no version-specific directory, assume files are in current directory
      EXTRACTED_DIR="."
    fi

    echo "Found extracted directory: $EXTRACTED_DIR"
    echo "Contents of extracted directory:"
    ls -la "$EXTRACTED_DIR"

    # Install main binaries
    if [ -f "$EXTRACTED_DIR/${pname}" ]; then
      cp "$EXTRACTED_DIR/${pname}" $out/bin/
      chmod +x $out/bin/${pname}
      echo "Installed main binary: $out/bin/${pname}"
    else
      echo "Error: Main binary ${pname} not found!"
      exit 1
    fi

    # Install additional binaries (if any)
    for binary in "${EXTRACTED_DIR}"/${pname}-*; do
      if [ -f "$binary" ] && [[ ! "$binary" =~ \. ]]; then
        bin_name=$(basename "$binary")
        cp "$binary" $out/bin/
        chmod +x $out/bin/$bin_name
        echo "Installed additional binary: $out/bin/$bin_name"
      fi
    done

    # Install configuration files (if any)
    if [ -f "$EXTRACTED_DIR/config.yaml" ]; then
      cp "$EXTRACTED_DIR/config.yaml" $out/share/${pname}/
      echo "Installed configuration file"
    fi

    # Install documentation (if any)
    if [ -f "$EXTRACTED_DIR/README.md" ]; then
      cp "$EXTRACTED_DIR/README.md" $out/share/doc/${pname}/
    fi
    if [ -f "$EXTRACTED_DIR/LICENSE" ]; then
      cp "$EXTRACTED_DIR/LICENSE" $out/share/doc/${pname}/
    fi

    # Install examples (if any)
    if [ -d "$EXTRACTED_DIR/examples" ]; then
      cp -r "$EXTRACTED_DIR/examples"/* $out/share/examples/${pname}/
      echo "Installed examples"
    fi

    # Install shell completions (if available)
    # if [ -f "$EXTRACTED_DIR/completions/bash" ]; then
    #   installShellCompletion --bash "$EXTRACTED_DIR/completions/bash"
    # fi
    # if [ -f "$EXTRACTED_DIR/completions/zsh" ]; then
    #   installShellCompletion --zsh "$EXTRACTED_DIR/completions/zsh"
    # fi
    # if [ -f "$EXTRACTED_DIR/completions/fish" ]; then
    #   installShellCompletion --fish "$EXTRACTED_DIR/completions/fish"
    # fi

    # Install desktop files (for GUI applications)
    # if [ -f "$EXTRACTED_DIR/${pname}.desktop" ]; then
    #   install -Dm444 "$EXTRACTED_DIR/${pname}.desktop" $out/share/applications/${pname}.desktop
    # fi

    # Install icons (for GUI applications)
    # if [ -f "$EXTRACTED_DIR/icon.png" ]; then
    #   install -Dm444 "$EXTRACTED_DIR/icon.png" $out/share/icons/hicolor/256x256/apps/${pname}.png
    # fi

    runHook postInstall
  '';

  # Optional: Add post-install setup
  # postInstall = ''
  #   # Additional setup steps after installation
  # '';

  # Optional: Add patch phase for modifying files before installation
  # patchPhase = ''
  #   # Patch any files that need modification
  # '';

  # Metadata
  meta = with lib; {
    description = "Example package distributed as compressed archive";
    homepage = "https://github.com/owner/repo";
    changelog = "https://github.com/owner/repo/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];

    # Optional features
    # maintainers = with maintainers; [ your-username ];
    # priority = 10;  # Lower number = higher priority

    longDescription = ''
      This is an example template for packages distributed as compressed archives.
      It demonstrates how to handle:
      - Multi-file installations
      - Directory structure preservation
      - Documentation and examples installation
      - Shell completions integration
      - Desktop application support
    '';
  };
}