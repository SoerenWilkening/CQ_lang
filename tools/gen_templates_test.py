#!/usr/bin/env python3
"""tools/gen_templates_test.py - self-test for tools/gen_templates.py.

Asserts:
  1. Total symbol count == 780.
  2. Per-kind breakdown matches YAML projection (derived at runtime).
  3. Every .h declaration has a matching .c definition.
  4. YAML SHA-256 banner appears in every emitted file (cq_templates.{h,c}).
  5. Generator is byte-idempotent.
  6. --check returns 0 on clean tree, 1 after a tampered byte.

Run: python3 tools/gen_templates_test.py
"""
from __future__ import annotations

import filecmp, hashlib, os, pathlib, re, subprocess, sys, tempfile, unittest
import yaml

REPO = pathlib.Path(__file__).resolve().parent.parent
GEN = REPO / "tools" / "gen_templates.py"
YAML_PATH = REPO / "tools" / "opcode_table.yaml"


def _generate(out_dir):
    subprocess.run([sys.executable, str(GEN), "--output-dir", str(out_dir)],
                   check=True, capture_output=True, text=True)


def _expected_counts(table):
    binary = sum(len(o["variants"]) * len(o["widths"]) for o in table["binary_opcodes"])
    unary = sum(len(o["variants"]) * len(o["widths"]) for o in table["unary_opcodes"])
    compare = sum(len(o["variants"]) * len(table["predicates"][o["predicate_set"]])
                  * len(o["widths"]) for o in table["compare_opcodes"])
    cast = sum(len(o["variants"]) * len(o["pairs"]) for o in table["cast_opcodes"])
    return {"binary": binary, "unary": unary, "compare": compare, "cast": cast}


def _classify(name, table):
    for k in ("cast_opcodes", "compare_opcodes", "unary_opcodes"):
        for op in table[k]:
            if name.startswith(f"cq_template_{op['opcode']}_"):
                return k.replace("_opcodes", "")
    return "binary"


class GenTemplatesTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.yaml_bytes = YAML_PATH.read_bytes()
        cls.table = yaml.safe_load(cls.yaml_bytes)
        cls.yaml_sha = hashlib.sha256(cls.yaml_bytes).hexdigest()
        cls.tmpdir = tempfile.TemporaryDirectory()
        cls.out = pathlib.Path(cls.tmpdir.name)
        _generate(cls.out)
        cls.h_text = (cls.out / "cq_templates.h").read_text()
        cls.c_text = (cls.out / "cq_templates.c").read_text()
        cls.h_decls = sorted(re.findall(r"^int32_t (cq_template_\w+)\(",
                                        cls.h_text, re.MULTILINE))
        cls.c_defs = sorted(re.findall(r"^int32_t (cq_template_\w+)\([^)]*\)\s*\{",
                                       cls.c_text, re.MULTILINE))

    @classmethod
    def tearDownClass(cls):
        cls.tmpdir.cleanup()

    def test_total_symbol_count_is_780(self):
        self.assertEqual(len(self.h_decls), 780)

    def test_per_kind_breakdown_matches_yaml(self):
        expected = _expected_counts(self.table)
        actual = {"binary": 0, "unary": 0, "compare": 0, "cast": 0}
        for d in self.h_decls:
            actual[_classify(d, self.table)] += 1
        self.assertEqual(actual, expected)

    def test_decl_def_pairing(self):
        self.assertEqual(self.h_decls, self.c_defs)

    def test_yaml_sha_banner_in_all_files(self):
        for rel in ("cq_templates.h", "cq_templates.c"):
            self.assertIn(self.yaml_sha, (self.out / rel).read_text(),
                          f"yaml-sha256 missing from {rel}")

    def test_idempotence(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            _generate(a); _generate(b)
            d = filecmp.dircmp(a, b)
            self.assertFalse(d.diff_files, f"non-idempotent: {d.diff_files}")
            for sub in d.common_dirs:
                sd = filecmp.dircmp(os.path.join(a, sub), os.path.join(b, sub))
                self.assertFalse(sd.diff_files, f"non-idempotent in {sub}: {sd.diff_files}")

    def test_check_mode_clean_and_tampered(self):
        clean = subprocess.run(
            [sys.executable, str(GEN), "--output-dir", str(self.out), "--check"],
            capture_output=True, text=True)
        self.assertEqual(clean.returncode, 0, f"clean tree check failed: {clean.stdout!r}")
        target = self.out / "cq_templates.h"
        original = target.read_bytes()
        try:
            target.write_bytes(original + b"// tamper\n")
            drifted = subprocess.run(
                [sys.executable, str(GEN), "--output-dir", str(self.out), "--check"],
                capture_output=True, text=True)
            self.assertEqual(drifted.returncode, 1, f"tampered check returncode: {drifted.stdout!r}")
            self.assertIn("cq_templates.h", drifted.stdout)
        finally:
            target.write_bytes(original)


if __name__ == "__main__":
    unittest.main(verbosity=2)
