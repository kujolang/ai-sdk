"""Exercise the wrapper with a controlled runtime; no Kujo install required."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WrapperTests(unittest.TestCase):
    def test_cleanup_preserves_output_arguments_and_exit_status(self):
        for status in (0, 7):
            with self.subTest(status=status), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                runtime = root / "runtime"
                runtime.write_text('#!/bin/bash\nprintf "%s\\n" "$PWD" "$@"\nexit "${TEST_EXIT}"\n')
                runtime.chmod(0o700)
                env = dict(os.environ, KUJO_BIN=str(runtime), TMPDIR=directory, TEST_EXIT=str(status))
                result = subprocess.run([str(ROOT / "kujo"), "run", "examples/main.kujo", "--", "two words"], env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, status, result.stderr)
                lines = result.stdout.splitlines()
                self.assertEqual(lines[1:], ["run", "examples/main.kujo", "--", "two words"])
                self.assertFalse(Path(lines[0]).exists(), "staged workspace leaked")
                self.assertEqual(list(root.glob("kujo-workspace.*")), [])

    def test_staging_failure_cleans_workspace_and_does_not_run_runtime(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rsync = root / "rsync"
            rsync.write_text('#!/bin/bash\nexit 23\n')
            rsync.chmod(0o700)
            env = dict(os.environ, KUJO_BIN="/usr/bin/false", TMPDIR=directory, PATH=directory + os.pathsep + os.environ["PATH"])
            result = subprocess.run([str(ROOT / "kujo"), "test-run", "tests/sdk_contract_tests.kujo"], env=env, capture_output=True)
            self.assertEqual(result.returncode, 23)
            self.assertEqual(list(root.glob("kujo-workspace.*")), [])


if __name__ == "__main__":
    unittest.main()
