# dotbot-age

A [dotbot](https://github.com/anishathalye/dotbot) plugin for decrypting files using [age](https://github.com/FiloSottile/age).

## Installation

### Method 1: Git Clone (Recommended)

1. Clone this repository into your dotfiles plugins directory:
   ```bash
   git clone https://github.com/your-username/dotbot-age.git
   ```

2. Add the plugin to your `install.conf.yaml`:
   ```yaml
   - plugins:
       - dotbot-age/age.py
   ```

### Method 2: Install as Package

1. Install the plugin using pip:
   ```bash
   pip install dotbot-age
   ```

2. Add the plugin to your `install.conf.yaml`:
   ```yaml
   - plugins:
       - dotbot_age.age
   ```

## Prerequisites

- [age](https://github.com/FiloSottile/age) must be installed and available in your PATH
- An age identity file or recipient for decryption

## Usage

The `age` plugin uses a dictionary format where the key is the target path and the value is either:
- A string (the source file path)
- A dictionary with additional options

### Basic Usage

Simple format (target: source):
```yaml
- age:
    ~/.config/app/config: secrets/app/config.age
```

This will decrypt `secrets/app/config.age` to `~/.config/app/config`.

### Advanced Configuration

Specify custom identity and permissions:
```yaml
- age:
    ~/.config/app/credentials:
      source: secrets/credentials.age
      identity: ~/.age/identities/default
      mode: "600"
```

Decrypt with recipient:
```yaml
- age:
    ~/.config/app/api-keys:
      source: secrets/api-keys.age
      recipients:
        - age1ql3z7hjy54pw3hyww5p5v06xfjpxxjwzkhxj4nt7p8l3j8g8p9dsqypza4p
```

Use a custom age binary:
```yaml
- age:
    ~/.local/share/app/secret:
      source: secret.conf.age
      binary: /usr/local/bin/age
```

### Multiple Files

Decrypt multiple files with different configurations:
```yaml
- age:
    # Simple format: target: source
    ~/.config/app1/config: secrets/app1/config.age

    # Advanced format with options
    ~/.config/app2/secrets:
      source: secrets/app2/secrets.age
      identity: ~/.age/identities/app2
      mode: "600"

    # Using recipient
    ~/.config/app3/tokens:
      source: secrets/tokens.age
      recipients: age1ql3z7hjy54pw3hyww5p5v06xfjpxxjwzkhxj4nt7p8l3j8g8p9dsqypza4p

    # Script with execute permissions
    ~/bin/secure-script:
      source: scripts/secure-script.age
      mode: "755"
```

### Working Directory

The plugin executes age commands from the same working directory where dotbot is run. This ensures:
- Consistency with other dotbot operations
- Relative paths are resolved relative to your dotfiles root directory
- Use absolute paths for identity files if they're located elsewhere

### Automatic Directory Creation

The plugin automatically creates necessary parent directories for target files:
```yaml
- age:
    # Will create ~/.config/app/secrets/ directory if it doesn't exist
    ~/.config/app/secrets/database.conf: secrets/db.conf.age

    # Creates nested directories as needed
    ~/.local/share/backup/2024/config: backup/config.age
```

If directory creation fails due to permissions or other errors, the decryption will be aborted with an appropriate error message.

### Cross-Platform Permissions

The `mode` option works differently across platforms:

**Unix-like systems (Linux, macOS):**
- Full chmod support with octal permissions (e.g., "600", "755")
- Standard Unix permission bits are respected

**Windows:**
- Limited permission support due to Windows file system differences
- When write bit is disabled (e.g., mode "400", "444"), file is set as read-only
- When write bit is enabled (e.g., mode "600", "644"), read-only attribute is removed
- Fine-grained permissions (group/other) are ignored on Windows
- If `pywin32` is installed, native Windows APIs are used for better integration

## Configuration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `source` | string | Yes | - | Path to the encrypted file (typically ending with `.age`) |
| `target` | string | No | `source` without `.age` extension | Path where the decrypted file will be written |
| `identity` | string | No | See below | Path to age identity file for decryption |
| `recipients` | string or array | No | See below | Age recipients for decryption |
| `binary` | string | No | `age` | Path to age binary |
| `mode` | string or int | No | Current umask | File permissions (Unix octal). On Windows, only controls read-only attribute |

### Identity Resolution

If neither `identity` nor `recipients` is specified, the plugin will try to find an identity file in these locations (in order):
1. `~/.age/identities/default`
2. `~/.config/age/identities/default`
3. `~/.ssh/id_ed25519`

## Example Configuration

```yaml
# install.conf.yaml
- defaults:
    link:
      create: true
      relink: true

- clean: ['~']

- plugins:
    - dotbot-age/age.py

- link:
    ~/.dotfiles: ''
    ~/.config/alacritty: config/alacritty

- age:
    # Simple format: target: source
    ~/.config/vpn/config: secrets/vpn/config.age

    # Advanced format with options
    ~/.ssh/config:
      source: secrets/ssh-config.age
      identity: ~/.age/identities/ssh
      mode: "600"

    # Multiple recipients
    ~/.config/app/tokens:
      source: secrets/api-tokens.age
      recipients:
        - age1ql3z7hjy54pw3hyww5p5v06xfjpxxjwzkhxj4nt7p8l3j8g8p9dsqypza4p
        - age1key6l9qr9t9q8s6q2p7y8x4z3w5v6u7i8o9p0q

    # Scripts with permissions
    ~/bin/secure-deploy:
      source: scripts/secure-deploy.sh.age
      mode: "755"
```

## Security Considerations

- Decrypted files will be written to your filesystem in plain text
- Ensure your identity files have appropriate permissions (typically `600`)
- Be careful not to commit decrypted files to version control
- Consider using a gitignore pattern like `*.decrypted` or specific file paths

## Troubleshooting

### "age command not found"
Ensure age is installed and in your PATH:
```bash
# Install age (examples)
brew install age          # macOS
pacman -S age             # Arch Linux
cargo install age         # Rust/cargo
```

### "No identity file specified and no default identity found"
Either:
- Specify an `identity` file in your configuration
- Specify `recipients` for decryption
- Create a default identity file at `~/.age/identities/default`

### "Identity file does not exist"
Check that the path to your identity file is correct and the file exists.

## License

Apache License 2.0

## Contributing

Pull requests are welcome! Please ensure your code follows the existing style and includes appropriate tests.