#!/usr/bin/env python3
"""tools/gen_templates_test.py - self-test for tools/gen_templates.py.

Asserts:
  1. Total symbol count == 1562 (1172 value-returning + 390 void `_unc`).
  2. Per-kind breakdown matches YAML projection (derived at runtime).
  3. Every .h declaration has a matching .c definition.
  4. YAML SHA-256 banner appears in every emitted file (cq_templates.{h,c}).
  5. Generator is byte-idempotent.
  6. --check returns 0 on clean tree, 1 after a tampered byte.
  7. Every controlled symbol's first parameter is the i32 control flag
     (PRD §1.2: one control wire per op, prepended as argument 0).
  8. The void in-place `_unc` uncompute family (Phase 5, PRD §2.3 / DD-3):
     void return, `out` prepended as arg 0, forward operands following in
     original order; trace-only bodies (no alloc, no return, no `-> h`).

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
        # Both return types: `int32_t` (fwd/inv/controlled, mint a handle) and
        # `void` (the in-place `_unc` uncompute family, Phase 5 — zeroes a rail,
        # mints nothing). cq_templates.h holds ONLY cq_template_* symbols, so a
        # `^void ` line there is always an `_unc` decl (the cqrt_* void runtime
        # symbols live in cq_runtime.h).
        cls.h_decls = sorted(re.findall(r"^(?:int32_t|void) (cq_template_\w+)\(",
                                        cls.h_text, re.MULTILINE))
        cls.c_defs = sorted(re.findall(r"^(?:int32_t|void) (cq_template_\w+)\([^)]*\)\s*\{",
                                       cls.c_text, re.MULTILINE))

    @classmethod
    def tearDownClass(cls):
        cls.tmpdir.cleanup()

    def test_total_symbol_count_is_1732(self):
        # 1294 value-returning templates (fwd/inv/controlled) + 438 void
        # in-place `_unc` symbols: binary 209 + unary 3 + cast 90 + compare 136.
        # Phase 7.1 Increment D added the **f16** fp width (i128 deferred — its
        # C ABI shreds __int128 to {i64,i64}; see the i128 follow-up issue). f16
        # rides every fp row: 5 fp binary ops (+65), fneg (+3), fcmp (6 preds x
        # 2 variants = +12 unc, +36 total), and 22 new cast pairs touching f16
        # (fpext/fptrunc f16<->{f32,f64}, sitofp/uitofp ints->f16, fptosi/fptoui
        # f16->ints; x3 fwd/inv/unc = +66). Net +170 over the 1562 baseline.
        self.assertEqual(len(self.h_decls), 1732)

    def test_unc_family_is_void_in_place(self):
        """PRD §2.3 / DD-3: the `_unc` uncompute family is VOID and in-place.
        `out` is prepended as argument 0; the forward operands follow in
        their ORIGINAL order. There is no `int32_t` return (the op zeroes a
        rail by recomputing f from live sources — it mints nothing)."""
        unc = re.findall(r"^(int32_t|void) (cq_template_\w+_unc)\(([^)]*)\)",
                         self.h_text, re.MULTILINE)
        self.assertTrue(unc, "no _unc symbols emitted")
        for ret, sym, params in unc:
            self.assertEqual(ret, "void",
                             f"{sym}: return type {ret!r}, expected 'void' "
                             "(the _unc family zeroes a rail, never mints)")
            first = params.split(",")[0].strip()
            self.assertEqual(first, "int32_t out_handle",
                             f"{sym}: first parameter {first!r}, expected "
                             "'int32_t out_handle' (DD-3: out is arg 0)")
        sigs = {sym: params for _, sym, params in unc}
        # DD-3 pinned slot mapping (out, then forward operands in order):
        #   qq      -> (out, a_handle, b_handle)   [BARE — QQ carries no shape token,
        #                                           matching the bare forward QQ form]
        #   hl      -> (out, a_handle, b_classical)
        #   lh      -> (out, a_classical, b_handle)
        #   unary   -> (out, a_handle)
        #   cast    -> (out, a_handle)
        self.assertEqual(sigs.get("cq_template_add_i32_unc"),
                         "int32_t out_handle, int32_t a_handle, int32_t b_handle")
        self.assertEqual(sigs.get("cq_template_add_i32_hl_unc"),
                         "int32_t out_handle, int32_t a_handle, int32_t b_classical")
        self.assertEqual(sigs.get("cq_template_sub_i32_lh_unc"),
                         "int32_t out_handle, int32_t a_classical, int32_t b_handle")
        self.assertEqual(sigs.get("cq_template_fneg_f32_unc"),
                         "int32_t out_handle, int32_t a_handle")
        self.assertEqual(sigs.get("cq_template_sext_i1_to_i8_unc"),
                         "int32_t out_handle, int32_t a_handle")
        # Compare `_unc` (WI-0 / §6.0): qq -> (out, a_handle, b_handle);
        # hl -> (out, a_handle, b_classical). A compare-as-data flag reverses
        # in place by recompute-and-XOR, identical slot mapping to add/mul.
        self.assertEqual(sigs.get("cq_template_icmp_slt_i32_unc"),
                         "int32_t out_handle, int32_t a_handle, int32_t b_handle")
        self.assertEqual(sigs.get("cq_template_icmp_slt_i32_hl_unc"),
                         "int32_t out_handle, int32_t a_handle, int32_t b_classical")
        self.assertEqual(sigs.get("cq_template_fcmp_olt_f64_hl_unc"),
                         "int32_t out_handle, int32_t a_handle, double b_classical")
        # No `_lh` compare uncompute exists — compares canonicalize an lhs
        # literal by predicate flip (`5<x` ⇒ `x>5`), so they NEVER emit `_lh`
        # on any axis (CompareLowering.cpp / TemplateName.cpp).
        self.assertIsNone(sigs.get("cq_template_icmp_slt_i32_lh_unc"))

    def test_unc_bodies_are_trace_only(self):
        """PRD §2.3: `_unc` bodies are trace-only stubs — NO handle mint
        (`cqrt_alloc_handle`), NO `return`, and the trace has NO `-> h`
        result suffix (so the handle counter never advances). The out
        handle prints first (DD-3 slot order)."""
        bodies = re.findall(
            r"^void (cq_template_\w+_unc)\([^)]*\)\s*\{(.*?)\n\}",
            self.c_text, re.MULTILINE | re.DOTALL)
        self.assertTrue(bodies, "no _unc definitions emitted")
        for sym, body in bodies:
            self.assertNotIn("cqrt_alloc_handle", body,
                             f"{sym}: body mints a handle (must be in-place)")
            self.assertNotIn("return", body,
                             f"{sym}: body returns a value (must be void)")
            self.assertNotIn("-> h", body,
                             f"{sym}: trace carries a `-> h` result suffix")
            self.assertIn(f'printf("{sym}(h%d', body,
                          f"{sym}: trace does not lead with the out handle")

    def test_controlled_first_param_is_control_flag(self):
        """PRD §1.2: every controlled symbol prepends `int32_t ctrl_flag`
        as argument 0 (the single control wire). Pins the controlled
        surface against a signature that forgets / reorders the flag."""
        # Grab each controlled decl's parameter list from the header.
        sigs = dict(re.findall(
            r"^int32_t (cq_template_\w*_controlled(?:_inv)?)\(([^)]*)\)",
            self.h_text, re.MULTILINE))
        controlled = [d for d in self.h_decls if "_controlled" in d]
        self.assertTrue(controlled, "no controlled symbols emitted")
        self.assertEqual(sorted(sigs), sorted(controlled),
                         "controlled decl set mismatch between regex and h_decls")
        for sym, params in sigs.items():
            first = params.split(",")[0].strip()
            self.assertEqual(first, "int32_t ctrl_flag",
                             f"{sym}: first parameter is {first!r}, "
                             "expected 'int32_t ctrl_flag' (PRD §1.2)")

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
