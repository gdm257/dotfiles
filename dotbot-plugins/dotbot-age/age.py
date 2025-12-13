import os
import subprocess
import shutil
from typing import Any, Dict, List, Optional, Union

import dotbot
import dotbot.util


class Age(dotbot.Plugin):
    """
    Dotbot plugin for decrypting files using age (https://github.com/FiloSottile/age).

    This plugin allows you to decrypt encrypted files and symlinks in your dotfiles
    repository using the age encryption tool.
    """

    _directive = "age"

    def can_handle(self, directive: str) -> bool:
        return directive == self._directive

    def handle(self, directive: str, data: Any) -> bool:
        if directive != self._directive:
            raise ValueError(f"Age cannot handle directive {directive}")

        success = True

        if isinstance(data, dict):
            # Dictionary format: key is target, value is source or config dict
            for target_path, value in data.items():
                if isinstance(value, str):
                    # Simple format: target: source
                    config = {
                        "source": value,
                        "target": target_path
                    }
                elif isinstance(value, dict):
                    # Advanced format: target: {source: ..., other options}
                    config = value.copy()
                    config["target"] = target_path
                    if "source" not in config:
                        self._log.error(f"Age configuration for {target_path} missing 'source' field")
                        success = False
                        continue
                else:
                    self._log.error(f"Invalid age configuration for {target_path}: {value}")
                    success = False
                    continue

                if not self._handle_config(config):
                    success = False
        elif isinstance(data, list):
            # Legacy list format for backward compatibility
            self._log.warning("List format is deprecated, use dictionary format instead")
            for item in data:
                if isinstance(item, dict):
                    if not self._handle_config(item):
                        success = False
                elif isinstance(item, str):
                    # Handle simple string format as encrypted file path
                    config = {
                        "source": item,
                        "target": item.rsplit(".age", 1)[0] if item.endswith(".age") else item
                    }
                    if not self._handle_config(config):
                        success = False
                else:
                    self._log.error(f"Invalid age configuration: {item}")
                    success = False
        else:
            self._log.error(f"Age configuration must be a dictionary, got {type(data)}")
            return False

        return success

    def _handle_config(self, config: Dict[str, Any]) -> bool:
        """Handle a single age configuration."""
        # Required fields
        if "source" not in config:
            self._log.error("Age configuration missing 'source' field")
            return False

        source = os.path.expanduser(config["source"])

        # Default target to source without .age extension
        if "target" in config:
            target = os.path.expanduser(config["target"])
        else:
            target = source.rsplit(".age", 1)[0] if source.endswith(".age") else source

        # Check if source file exists
        if not os.path.exists(source):
            self._log.error(f"Source file does not exist: {source}")
            return False

        # Create target directory if it doesn't exist
        target_dir = os.path.dirname(os.path.abspath(target))
        if target_dir and not os.path.exists(target_dir):
            self._log.lowinfo(f"Creating directory: {target_dir}")
            if not self._safe_makedirs(target_dir):
                self._log.error(f"Failed to create directory: {target_dir}")
                return False
            else:
                self._log.lowinfo(f"Successfully created directory: {target_dir}")

        # Decrypt the file
        return self._decrypt_file(source, target, config)

    def _decrypt_file(self, source: str, target: str, config: Dict[str, Any]) -> bool:
        """Decrypt a file using age."""
        try:
            # Check if age is available
            age_cmd = config.get("binary", "age")
            if not shutil.which(age_cmd):
                self._log.error(f"age command not found: {age_cmd}")
                return False

            # Build age command
            cmd = [age_cmd, "--decrypt", "-o", target]

            # Add identity file if specified
            if "identity" in config:
                identity_file = os.path.expanduser(config["identity"])
                if not os.path.exists(identity_file):
                    self._log.error(f"Identity file does not exist: {identity_file}")
                    return False
                cmd.extend(["-i", identity_file])
            elif "recipients" in config:
                # Handle multiple recipients
                recipients = config["recipients"]
                if isinstance(recipients, str):
                    recipients = [recipients]
                for recipient in recipients:
                    cmd.extend(["-r", recipient])
            else:
                # Try default identity files
                default_identities = [
                    os.path.expanduser("~/.age/identities/default"),
                    os.path.expanduser("~/.config/age/identities/default"),
                    os.path.expanduser("~/.ssh/id_ed25519"),
                ]

                identity_found = False
                for identity_file in default_identities:
                    if os.path.exists(identity_file):
                        cmd.extend(["-i", identity_file])
                        identity_found = True
                        break

                if not identity_found:
                    self._log.warning(
                        "No identity file specified and no default identity found. "
                        "You may need to provide an identity file or recipients."
                    )

            # Add source file
            cmd.append(source)

            # Run the command from the current working directory
            # This maintains consistency with dotbot's behavior
            self._log.lowinfo(f"Decrypting {source} to {target}")
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            if result.returncode == 0:
                self._log.info(f"Successfully decrypted {source} to {target}")

                # Set file permissions if specified
                if "mode" in config:
                    self._set_file_permissions(target, config["mode"])

                return True
            else:
                self._log.error(f"Failed to decrypt {source}: {result.stderr}")
                return False

        except Exception as e:
            self._log.error(f"Error decrypting {source}: {str(e)}")
            return False

    def _set_file_permissions(self, path: str, mode: Union[str, int]) -> None:
        """Set file permissions in a cross-platform way.

        On Unix-like systems, sets standard Unix permissions.
        On Windows, only handles basic read-only attribute since chmod has limited effect.

        Args:
            path: Path to the file
            mode: Either Unix octal string (e.g., "600") or integer (e.g., 0o600)
        """
        if isinstance(mode, str):
            try:
                mode = int(mode, 8)
            except ValueError:
                self._log.warning(f"Invalid mode format: {mode}, skipping permission set")
                return

        import stat

        if os.name == 'nt':  # Windows
            # On Windows, only handle read-only attribute
            # Remove all write permissions for user (make read-only)
            if mode & 0o200 == 0:  # No user write permission
                try:
                    import win32api
                    import win32con
                    win32api.SetFileAttributes(path, win32con.FILE_ATTRIBUTE_READONLY)
                    self._log.lowinfo(f"Set Windows read-only attribute on {path}")
                except ImportError:
                    # Fallback: try removing write permission
                    current_mode = stat.S_IMODE(os.lstat(path).st_mode)
                    new_mode = current_mode & ~stat.S_IWUSR
                    os.chmod(path, new_mode)
                    self._log.lowinfo(f"Set read-only permissions on {path} (fallback)")
                except Exception as e:
                    self._log.warning(f"Failed to set Windows permissions on {path}: {e}")
            else:
                try:
                    # Remove read-only attribute if write permission is granted
                    import win32api
                    import win32con
                    win32api.SetFileAttributes(path, win32con.FILE_ATTRIBUTE_NORMAL)
                    self._log.lowinfo(f"Removed Windows read-only attribute from {path}")
                except ImportError:
                    # Fallback: add write permission
                    current_mode = stat.S_IMODE(os.lstat(path).st_mode)
                    new_mode = current_mode | stat.S_IWUSR
                    os.chmod(path, new_mode)
                    self._log.lowinfo(f"Set write permissions on {path} (fallback)")
                except Exception as e:
                    self._log.warning(f"Failed to set Windows permissions on {path}: {e}")
        else:
            # Unix-like systems: use standard chmod
            try:
                os.chmod(path, mode)
                self._log.lowinfo(f"Set Unix permissions on {path} to {oct(mode)}")
            except Exception as e:
                self._log.warning(f"Failed to set permissions on {path}: {e}")

    def _safe_makedirs(self, path: str) -> bool:
        """Safely create directories with better error handling."""
        try:
            # Normalize the path first
            path = os.path.normpath(path)

            # Skip creation if path is root or empty
            if path in (os.sep, '') or path == os.path.dirname(path):
                return True

            os.makedirs(path, exist_ok=True)
            return True
        except PermissionError as e:
            self._log.error(f"Permission denied when creating directory {path}: {e}")
            return False
        except OSError as e:
            # Check if directory already exists (race condition check)
            if os.path.exists(path) and os.path.isdir(path):
                return True
            self._log.error(f"Failed to create directory {path}: {e}")
            return False
        except Exception as e:
            self._log.error(f"Unexpected error creating directory {path}: {e}")
            return False

    # Helper methods for consistency with other dotbot plugins
    def _exists(self, path: str) -> bool:
        return os.path.exists(path)

    def _is_link(self, path: str) -> bool:
        return os.path.islink(path)

    def _readlink(self, path: str) -> Optional[str]:
        try:
            return os.readlink(path)
        except OSError:
            return None

    def _canonical_exists(self, path: str) -> bool:
        return self._exists(self._readlink(path) or path)