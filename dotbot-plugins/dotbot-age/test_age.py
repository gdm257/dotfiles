#!/usr/bin/env python3
"""
Test script for dotbot-age plugin.

This script creates a test environment to verify the plugin functionality.
"""

import os
import sys
import tempfile
import shutil
import subprocess
from pathlib import Path

# Add the plugin directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from age import Age


def test_age_plugin():
    """Test the age plugin functionality."""
    print("Testing dotbot-age plugin...")

    # Check if age is installed
    if not shutil.which("age"):
        print("❌ age is not installed. Skipping tests.")
        print("Please install age from https://github.com/FiloSottile/age")
        return False

    # Create a temporary directory for testing
    with tempfile.TemporaryDirectory() as tmpdir:
        print(f"Using temporary directory: {tmpdir}")

        # Create test files and directories
        test_dir = Path(tmpdir)
        source_file = test_dir / "test.txt.age"
        target_file = test_dir / "test.txt"
        identity_file = test_dir / "test_key.txt"
        original_file = test_dir / "original.txt"

        # Create test content
        test_content = "This is a secret message for testing dotbot-age plugin!"
        original_file.write_text(test_content)

        # Generate a test key
        print("Generating test key...")
        subprocess.run(
            ["age-keygen", "-o", str(identity_file)],
            check=True,
            capture_output=True
        )

        # Extract the public key
        key_output = subprocess.run(
            ["age-keygen", "-y", str(identity_file)],
            check=True,
            capture_output=True,
            text=True
        )
        public_key = key_output.stdout.strip()
        print(f"Generated public key: {public_key}")

        # Encrypt the test file
        print("Encrypting test file...")
        subprocess.run(
            ["age", "-r", public_key, "-o", str(source_file), str(original_file)],
            check=True
        )

        # Verify encrypted file exists
        assert source_file.exists(), "Encrypted file was not created"
        print("✓ File encrypted successfully")

        # Create the plugin instance
        plugin = Age()

        # Test can_handle
        assert plugin.can_handle("age"), "Plugin should handle 'age' directive"
        assert not plugin.can_handle("something_else"), "Plugin should not handle other directives"
        print("✓ Plugin can_handle method works correctly")

        # Test basic decryption
        config = {
            "source": str(source_file),
            "target": str(target_file),
            "identity": str(identity_file)
        }

        success = plugin._handle_config(config)
        assert success, "Decryption should succeed"
        assert target_file.exists(), "Decrypted file should exist"
        decrypted_content = target_file.read_text()
        assert decrypted_content == test_content, "Decrypted content should match original"
        print("✓ Basic decryption works correctly")

        # Test new dictionary format - simple (target: source)
        target_file2 = test_dir / "test2.txt"
        dict_config = {
            str(target_file2): str(source_file)
        }
        success = plugin.handle("age", dict_config)
        assert success, "Dictionary format (simple) should succeed"
        assert target_file2.exists(), "Decrypted file should exist"
        decrypted_content2 = target_file2.read_text()
        assert decrypted_content2 == test_content, "Decrypted content should match original"
        print("✓ Dictionary format (simple) works correctly")

        # Test new dictionary format - advanced (target: {source: ..., options})
        target_file3 = test_dir / "test3.txt"
        dict_config2 = {
            str(target_file3): {
                "source": str(source_file),
                "identity": str(identity_file),
                "mode": "600"
            }
        }
        success = plugin.handle("age", dict_config2)
        assert success, "Dictionary format (advanced) should succeed"
        assert target_file3.exists(), "Decrypted file should exist"
        decrypted_content3 = target_file3.read_text()
        assert decrypted_content3 == test_content, "Decrypted content should match original"
        file_mode = oct(target_file3.stat().st_mode)[-3:]
        assert file_mode == "600", f"File mode should be 600, got {file_mode}"
        print("✓ Dictionary format (advanced) works correctly")

        # Test legacy list format (deprecated)
        os.remove(target_file2)
        list_config = [{
            "source": str(source_file),
            "target": str(target_file2)
        }]
        success = plugin.handle("age", list_config)
        assert success, "Legacy list format should still work"
        assert target_file2.exists(), "Decrypted file should exist"
        decrypted_content4 = target_file2.read_text()
        assert decrypted_content4 == test_content, "Decrypted content should match original"
        print("✓ Legacy list format still works (with warning)")

        # Test string format (old deprecated)
        os.remove(target_file3)
        success = plugin.handle("age", str(source_file))
        assert success, "String format should still work"
        assert target_file3.exists(), "Decrypted file should exist"
        decrypted_content5 = target_file3.read_text()
        assert decrypted_content5 == test_content, "Decrypted content should match original"
        print("✓ String format still works (with warning)")

        # Test error handling - non-existent source
        bad_dict_config = {
            str(test_dir / "nonexistent.txt"): str(test_dir / "nonexistent.age")
        }
        success = plugin.handle("age", bad_dict_config)
        assert not success, "Should fail with non-existent source file"
        print("✓ Error handling for non-existent source works correctly")

        # Test error handling - missing source field in dict
        bad_dict_config2 = {
            str(test_dir / "output.txt"): {
                "identity": str(identity_file)
            }
        }
        success = plugin.handle("age", bad_dict_config2)
        assert not success, "Should fail with missing source field"
        print("✓ Error handling for missing source field in dict works correctly")

        # Test error handling - invalid data type
        success = plugin.handle("age", "invalid_data")
        assert not success, "Should fail with invalid data type"
        print("✓ Error handling for invalid data type works correctly")

        # Test automatic directory creation
        nested_target = test_dir / "level1" / "level2" / "level3" / "nested.txt"
        nested_config = {
            str(nested_target): str(source_file)
        }
        success = plugin.handle("age", nested_config)
        assert success, "Should succeed with nested directory creation"
        assert nested_target.exists(), "Decrypted file should exist in nested directory"
        assert nested_target.parent.exists(), "Nested directories should be created"
        decrypted_nested = nested_target.read_text()
        assert decrypted_nested == test_content, "Decrypted content should match original"
        print("✓ Automatic directory creation works correctly")

        # Test directory creation with permissions
        perm_target = test_dir / "permdir" / "config.txt"
        perm_config = {
            str(perm_target): {
                "source": str(source_file),
                "mode": "600"
            }
        }
        success = plugin.handle("age", perm_config)
        assert success, "Should succeed with directory creation and permissions"
        assert perm_target.exists(), "Decrypted file should exist"
        print("✓ Directory creation with permissions works correctly")

        print("\n✅ All tests passed!")
        return True


def main():
    """Run the tests."""
    try:
        success = test_age_plugin()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()