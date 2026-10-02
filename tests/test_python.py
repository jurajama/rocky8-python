"""Smoke tests for the Python interpreter built from source in the image.

Run inside the built image, for example:

    docker run --rm -v "$PWD/tests:/tests:ro" \
        -e EXPECTED_PYTHON_VERSION=3.11.14 -e EXPECTED_MACHINE=x86_64 \
        rocky8-python python3 -m unittest discover -v -s /tests

EXPECTED_PYTHON_VERSION and EXPECTED_MACHINE are optional; the corresponding
checks are skipped when they are not set.
"""

import os
import platform
import subprocess
import sys
import tempfile
import unittest

PYTHON_PREFIX = "/usr/local"


def _square(x):
    return x * x


class InterpreterTest(unittest.TestCase):
    def test_interpreter_is_source_build(self):
        self.assertEqual(sys.prefix, PYTHON_PREFIX)
        self.assertTrue(os.path.realpath(sys.executable).startswith(PYTHON_PREFIX + "/bin/"))

    def test_python3_on_path_is_source_build(self):
        out = subprocess.run(
            ["python3", "-c", "import sys; print(sys.prefix)"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        self.assertEqual(out, PYTHON_PREFIX)

    def test_version(self):
        expected = os.environ.get("EXPECTED_PYTHON_VERSION")
        if not expected:
            self.skipTest("EXPECTED_PYTHON_VERSION not set")
        self.assertEqual(platform.python_version(), expected)

    def test_architecture(self):
        expected = os.environ.get("EXPECTED_MACHINE")
        if not expected:
            self.skipTest("EXPECTED_MACHINE not set")
        self.assertEqual(platform.machine(), expected)


class ExtensionModuleTest(unittest.TestCase):
    """Modules that depend on the -devel packages installed before the build."""

    def test_ssl(self):
        import ssl

        self.assertIn("OpenSSL", ssl.OPENSSL_VERSION)
        ctx = ssl.create_default_context()
        self.assertEqual(ctx.verify_mode, ssl.CERT_REQUIRED)
        self.assertGreater(ctx.cert_store_stats()["x509_ca"], 0, "no system CA certificates loaded")

    def test_hashlib(self):
        import _hashlib  # noqa: F401  OpenSSL backed hashes
        import hashlib

        self.assertEqual(
            hashlib.sha256(b"abc").hexdigest(),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        )
        self.assertEqual(hashlib.md5(b"abc").hexdigest(), "900150983cd24fb0d6963f7d28e17f72")

    def test_zlib_and_gzip(self):
        import gzip
        import zlib

        data = b"rocky8-python " * 1000
        self.assertEqual(zlib.decompress(zlib.compress(data)), data)
        self.assertEqual(gzip.decompress(gzip.compress(data)), data)

    def test_ctypes(self):
        import ctypes
        import ctypes.util

        libc = ctypes.CDLL(ctypes.util.find_library("c"))
        self.assertEqual(libc.strlen(b"hello"), 5)

    def test_decimal_c_accelerator(self):
        import _decimal  # noqa: F401
        import decimal

        self.assertEqual(decimal.Decimal("0.1") + decimal.Decimal("0.2"), decimal.Decimal("0.3"))


class RuntimeTest(unittest.TestCase):
    def test_json_roundtrip(self):
        import json

        obj = {"a": [1, 2.5, None, True], "b": "äö€"}
        self.assertEqual(json.loads(json.dumps(obj)), obj)

    def test_threading(self):
        from concurrent.futures import ThreadPoolExecutor

        with ThreadPoolExecutor(max_workers=4) as pool:
            self.assertEqual(list(pool.map(_square, range(10))), [x * x for x in range(10)])

    def test_multiprocessing(self):
        from multiprocessing import Pool

        with Pool(2) as pool:
            self.assertEqual(pool.map(_square, range(10)), [x * x for x in range(10)])

    def test_asyncio(self):
        import asyncio

        async def main():
            await asyncio.sleep(0)
            return 42

        self.assertEqual(asyncio.run(main()), 42)


class PackagingTest(unittest.TestCase):
    def test_pip(self):
        subprocess.run([sys.executable, "-m", "pip", "--version"], check=True, capture_output=True)

    def test_venv_with_pip(self):
        with tempfile.TemporaryDirectory() as tmp:
            venv_dir = os.path.join(tmp, "venv")
            subprocess.run([sys.executable, "-m", "venv", venv_dir], check=True)
            venv_python = os.path.join(venv_dir, "bin", "python")
            out = subprocess.run(
                [venv_python, "-c", "import sys; print(sys.prefix != sys.base_prefix)"],
                check=True, capture_output=True, text=True,
            ).stdout.strip()
            self.assertEqual(out, "True")
            subprocess.run([venv_python, "-m", "pip", "--version"], check=True, capture_output=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
