# Quick Usage Guide

## Installation

### Git Clone (Recommended):
```yaml
- plugins:
    - dotbot-age/age.py
```

### Pip Install:
```yaml
- plugins:
    - dotbot_age.age
```

## Basic Usage
Dictionary format: target is the key, source is the value
```yaml
- age:
    ~/.config/app/secrets: secrets/app/secrets.age
```

## With Identity File
```yaml
- age:
    ~/.config/app/config:
      source: secrets/config.age
      identity: ~/.age/identities/default
      mode: "600"
```

## With Recipients
```yaml
- age:
    ~/.config/app/tokens:
      source: secrets/tokens.age
      recipients: age1ql3z7hjy54pw3hyww5p5v06xfjpxxjwzkhxj4nt7p8l3j8g8p9dsqypza4p
```

## Multiple Files
```yaml
- age:
    ~/.ssh/config: secrets/ssh-config.age
    ~/.app1/secrets:
      source: secrets/app1.age
      identity: ~/.age/identities/app1
    ~/bin/script:
      source: scripts/script.age
      mode: "755"
```

## Nested Directories
Parent directories are created automatically:
```yaml
- age:
    ~/.config/deeply/nested/path/config: secrets/config.age
```

## Platform Notes
- **Unix**: Full permission support (600, 755, etc.)
- **Windows**: Only controls read-only attribute (600/644 = writable, 400/444 = read-only)

Note: Install age from https://github.com/FiloSottile/age