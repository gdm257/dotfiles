# Binary Package Template
#
# This is a template for creating Nix packages that download pre-compiled binaries
# from GitHub releases or other sources. It demonstrates the common patterns and
# best practices for binary packaging.
#
# Usage Examples:
# - Single binary package (like localias)
# - CLI tools distributed as binaries
# - Applications that don't need compilation
#
# Key Features:
# - Platform-specific downloads
# - Proper URL encoding
# - fakeSha256 for development
# - Static binary handling

{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "example-binary";
  version = "1.0.0";

  # Platform-specific download mapping
  # Common platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
  src = fetchurl {
    url = {
      x86_64-linux = "https://github.com/owner/repo/releases/download/v${version}/binary-linux-amd64";
      aarch64-linux = "https://github.com/owner/repo/releases/download/v${version}/binary-linux-arm64";
      x86_64-darwin = "https://github.com/owner/repo/releases/download/v${version}/binary-darwin-amd64";
      aarch64-darwin = "https://github.com/owner/repo/releases/download/v${version}/binary-darwin-arm64";
      # Add more platforms as needed
      # i686-linux = "https://github.com/owner/repo/releases/download/v${version}/binary-linux-386";
    }.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

    # Use fakeSha256 during development - will be replaced with actual hash
    sha256 = {
      x86_64-linux = lib.fakeSha256;
      aarch64-linux = lib.fakeSha256;
      x86_64-darwin = lib.fakeSha256;
      aarch64-darwin = lib.fakeSha256;
    }.${stdenv.hostPlatform.system};
  };

  # For direct binary downloads (no tar.gz), we don't need to unpack
  dontUnpack = true;

  # Installation phase - copy binary to output
  installPhase = ''
    runHook preInstall

    # Create bin directory
    mkdir -p $out/bin

    # Copy the downloaded binary
    cp $src $out/bin/${pname}

    # Make it executable
    chmod +x $out/bin/${pname}

    # Optional: Create symlinks for alternative names
    # ln -s $out/bin/${pname} $out/bin/alternative-name

    runHook postInstall
  '';

  # For tar.gz archives (compressed packages)
  # Comment out dontUnpack and use this installPhase instead:
  #
  # installPhase = ''
  #   runHook preInstall
  #
  #   mkdir -p $out/bin
  #
  #   # Find the binary in extracted archive
  #   BINARY_DIR=$(find . -maxdepth 1 -type d -name "*${pname}*" | head -n 1)
  #   if [ -z "$BINARY_DIR" ]; then
  #     BINARY_DIR="."
  #   fi
  #
  #   # Copy main binary
  #   if [ -f "$BINARY_DIR/${pname}" ]; then
  #     cp "$BINARY_DIR/${pname}" $out/bin/
  #     chmod +x $out/bin/${pname}
  #   else
  #     echo "Error: ${pname} binary not found in extracted archive!"
  #     echo "Contents:"
  #     ls -la
  #     if [ "$BINARY_DIR" != "." ]; then
  #       echo "Contents of binary directory:"
  #       ls -la "$BINARY_DIR"
  #     fi
  #     exit 1
  #   fi
  #
  #   runHook postInstall
  # '';

  # Metadata
  meta = with lib; {
    description = "Brief description of what this binary does";
    homepage = "https://github.com/owner/repo";
    changelog = "https://github.com/owner/repo/releases/tag/v${version}";
    license = licenses.mit;  # Change to appropriate license
    mainProgram = pname;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    # For binary packages:
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];

    # Optional additional metadata
    # broken = false;  # Set to true if package is known to be broken
    # insecure = false;  # Set to true if package has security vulnerabilities
    # unsupported = false;  # Set to true if package is no longer maintained

    # Long description (optional)
    longDescription = ''
      Detailed description of the package.
      This can span multiple lines and should explain:
      - What the package does
      - Who should use it
      - Key features
      - Any important notes about usage
    '';
  };
}