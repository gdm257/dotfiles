# Nix Package Templates

This directory contains templates and examples for creating Nix packages. Use these as starting points when packaging new software.

## Template Structure

```
pkgs/
├── template-binary/     # Single binary packages (like localias)
├── template-targz/     # Compressed archive packages
├── template-complex/   # Complex packages with dependencies
└── README.md          # This file
```

## Template Categories

### 1. `template-binary/` - Simple Binary Packages
**Use Case**: Single executable binaries downloaded directly from releases

**Examples**:
- CLI tools distributed as standalone binaries
- Applications that don't need compilation
- Simple tools with no additional assets

**Key Features**:
- Direct binary download (`fetchurl`)
- Platform-specific downloads
- `dontUnpack = true` for direct binaries
- Minimal installation phase

**Common Platforms**:
- `x86_64-linux` (Intel/AMD 64-bit Linux)
- `aarch64-linux` (ARM 64-bit Linux)
- `x86_64-darwin` (Intel Mac)
- `aarch64-darwin` (Apple Silicon Mac)

### 2. `template-targz/` - Archive Packages
**Use Case**: Packages distributed as compressed archives

**Examples**:
- Applications with multiple binaries
- Packages containing documentation and examples
- Tools that need specific directory structure

**Key Features**:
- Archive extraction (`fetchzip`)
- Multiple file installation
- Documentation and examples support
- Configuration file handling

### 3. `template-complex/` - Advanced Packages
**Use Case**: Complex applications with special requirements

**Examples**:
- GUI applications with desktop integration
- Applications with runtime dependencies
- Tools needing environment setup
- Multi-component packages

**Key Features**:
- Native and runtime dependencies
- Custom build phases
- Environment variable setup
- Shell completion integration
- Desktop file generation
- Wrapper scripts

## Development Workflow

### 1. Create New Package
```bash
# Copy appropriate template
cp -r pkgs/template-binary pkgs/my-new-package
cd pkgs/my-new-package

# Edit the package definition
vim default.nix
```

### 2. First Build (with fakeSha256)
```bash
# Build to get actual hashes
nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'

# The build will fail and show the actual SHA256 hashes
# Copy these hashes and replace lib.fakeSha256
```

### 3. Final Build
```bash
# Build again with real hashes
nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'

# Test the package
./result/bin/my-new-package --version
```

## Common Patterns

### Platform Detection
```nix
stdenv.hostPlatform.system  # Current platform
stdenv.hostPlatform.parsed.cpu.name  # CPU architecture
stdenv.hostPlatform.parsed.kernel.name  # Kernel/OS
```

### URL Construction
```nix
url = "https://github.com/owner/repo/releases/download/v${version}/binary-${stdenv.hostPlatform.system}"
```

### Hash Handling
```nix
# Development phase
sha256 = lib.fakeSha256;

# Production phase
sha256 = "sha256-ABC123...actual-hash...";
```

### Multiple Files
```nix
# For archives
src = fetchzip {
  # ...
  stripRoot = false;  # Keep directory structure
};

# For direct binaries
src = fetchurl {
  # ...
  dontUnpack = true;  # Don't extract
};
```

## Best Practices

### 1. Use fakeSha256 During Development
- Start with `lib.fakeSha256`
- Build once to get actual hashes
- Replace with real hashes for production

### 2. Platform Support
- Always support common platforms
- Use meaningful error messages for unsupported platforms
- Test on multiple platforms if possible

### 3. Metadata
- Provide clear descriptions
- Include homepage and changelog URLs
- Specify correct license
- List supported platforms

### 4. File Organization
- Put binaries in `$out/bin`
- Put libraries in `$out/lib`
- Put shared data in `$out/share`
- Put documentation in `$out/share/doc`

### 5. Dependencies
- Use `nativeBuildInputs` for build-time dependencies
- Use `buildInputs` for runtime dependencies
- Use `propagatedBuildInputs` for dependencies needed by consumers

## Troubleshooting

### Common Issues

1. **Hash Mismatch**: Binary changed, update SHA256
2. **Platform Not Supported**: Add platform mapping or update system detection
3. **Binary Not Found**: Check archive structure and file paths
4. **Permission Denied**: Ensure binaries are executable with `chmod +x`
5. **Missing Dependencies**: Add required packages to `buildInputs`

### Debug Commands
```bash
# Check file types
file ./result/bin/binary-name

# Check dependencies (Linux)
ldd ./result/bin/binary-name

# Check binary info
readelf -h ./result/bin/binary-name

# Test functionality
./result/bin/binary-name --help
./result/bin/binary-name --version
```

## Resources

- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Nixpkgs Contribution Guide](https://nixos.org/manual/nixpkgs/stable/#chap-contributing)

## Examples in This Repo

- `pkgs/localias/` - Single binary package (completed example)
- Template packages (starting points)

Feel free to copy and modify these templates for your own packages!