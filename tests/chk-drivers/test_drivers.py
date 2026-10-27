"""Unit tests of cqcheck.drivers and cqcheck.sampling (cq-w0-chk-drivers). Run from checker/."""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "checker"))

from cqcheck import drivers as D          # noqa: E402
from cqcheck import sampling as S         # noqa: E402
from cqcheck.contracts import DriverSpec, SampleSet, from_json, to_json   # noqa: E402

CLANG = str(S.LLVM_BIN / "clang")


def q(spec, call=0):
    return [a["quantum"] for a in spec.calls[call]["args"]]


class DriverSpecs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.specs = {n: D.driver_spec(n, D.example_dir(n)) for n in D.all_examples()}

    def test_every_example_has_a_line_and_a_spec(self):
        lines = D.read_drivers_txt()
        self.assertEqual(sorted(lines), sorted(D.all_examples()))
        for n, s in self.specs.items():
            self.assertEqual(s.example, n)
            self.assertTrue(s.calls)
            self.assertEqual(from_json(DriverSpec, to_json(s)), s)

    def test_seven_setup_snippets(self):
        with_setup = [n for n, l in D.read_drivers_txt().items() if l.setup]
        self.assertEqual(len(with_setup), 7)
        for n in with_setup:
            self.assertIn(D.read_drivers_txt()[n].setup, self.specs[n].setup)

    def test_implicit_objects(self):
        self.assertIn("static const double coef[4]", self.specs["28_horner_accumulator"].setup)
        self.assertIn("static const int icoef[4]", self.specs["36_callee_with_loop"].setup)
        self.assertEqual(self.specs["01_add_classical_const"].setup, "")

    def test_quantum_arguments(self):
        s = self.specs
        self.assertEqual(q(s["01_add_classical_const"]), [True, False, False])
        self.assertEqual(q(s["02_add_quantum_quantum"]), [True, True, False, False])
        # the angle of a second rotation is not a register (38)
        self.assertEqual(q(s["38_second_rotation"]), [True, False, False])
        # a register reached through local memory and a callee (61 invert_call: x via &x into prep)
        self.assertEqual(q(s["61_invert_theta_and_call"], 1), [True, True, False, False, False, False])
        # sizes that also seed registers are classical (114: q[i] = (i >= n - k))
        self.assertEqual(q(s["114_dicke_n"]), [False, False])
        # a compare that picks the register value is classical (144: if (x > k) y += 1)
        self.assertEqual(q(s["144_value_arm_then_rotate"]), [True, False, True, False, False, False])
        # registers computed inside the program: no quantum argument (58, 113)
        self.assertEqual(q(s["58_register_array"]), [False, False])
        self.assertEqual(s["113_dicke4"].calls[0]["args"], [])
        # a pointer to the caller's registers (60)
        self.assertEqual(q(s["60_qft"]), [True, False, False])


class Encoding(unittest.TestCase):
    def test_literals(self):
        ct = D.parse_ctype
        self.assertEqual(S.encode_c_literal(ct("int"), "-1"), "0xffffffff")
        self.assertEqual(S.encode_c_literal(ct("long long"), "-9223372036854775807-1"), "0x8000000000000000")
        self.assertEqual(S.encode_c_literal(ct("unsigned"), "0xc9"), "0x000000c9")
        self.assertEqual(S.encode_c_literal(ct("double"), ".5"), "0x3fe0000000000000")
        self.assertEqual(S.encode_c_literal(ct("float"), "3"), "0x40400000")
        self.assertEqual(S.encode_c_literal(ct("long double"), "1"), "0x3fff8000000000000000")
        self.assertEqual(S.encode_c_literal(ct("_Bool"), "1"), "0x1")

    def test_fp_kinds(self):
        self.assertEqual(S.fp_kind(0x7ff8000000000000, 64)[0], "nan")
        self.assertEqual(S.fp_kind(1, 64)[0], "sub")
        self.assertEqual(S.fp_kind(0x3fff8000000000000000, 80), ("norm", 1))
        for nc in S.f80_noncanonical():
            self.assertEqual(S.fp_kind(nc, 80)[0], "noncanon")

    def test_driver_source_is_bit_exact(self):
        """driver_source renders every scalar width with its exact bit pattern."""
        spec = DriverSpec("t", ["int f(_Bool,signed char,unsigned long long,float,double,long double);"], "",
                          [{"fn": "f", "args": [{"ctype": c, "quantum": True} for c in
                                                ("_Bool", "signed char", "unsigned long long", "float",
                                                 "double", "long double")]}])
        vals = ["0x1", "0x80", "0xfedcba9876543210", "0x7fc12345", "0xfff8000000012345", "0x7fffc000000000000001"]
        src = D.driver_source(spec, [{"call": 0, "args": vals}])
        callee = r"""
#include <stdio.h>
#include <string.h>
int f(_Bool a, signed char b, unsigned long long c, float d, double e, long double g) {
    unsigned u; unsigned long long v, m; unsigned short x;
    memcpy(&u, &d, 4); memcpy(&v, &e, 8); memcpy(&m, &g, 8); memcpy(&x, (char *)&g + 8, 2);
    printf("%d %x %llx %x %llx %04x%016llx\n", a, (unsigned char)b, c, u, v, x, m); return 0; }
"""
        with tempfile.TemporaryDirectory() as t:
            Path(t, "d.c").write_text(src)
            Path(t, "f.c").write_text(callee)
            subprocess.run([CLANG, "-w", "-O0", str(Path(t, "d.c")), str(Path(t, "f.c")), "-o", str(Path(t, "a"))],
                           check=True)
            out = subprocess.run([str(Path(t, "a"))], capture_output=True, text=True, check=True).stdout.split()
        self.assertEqual(out, ["1", "80", "fedcba9876543210", "7fc12345", "fff8000000012345", "7fffc000000000000001"])


class Sampling(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["CQ_SAMPLES_CACHE"] = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def sample(self, n):
        spec = D.driver_spec(n, D.example_dir(n))
        ss = S.sample_set(spec, D.example_dir(n))
        self.assertEqual(S.check_sample_set(spec, ss), [])
        self.assertEqual(from_json(SampleSet, to_json(ss)), ss)
        return spec, ss

    def rows(self, ss):
        return {(r["site"].split(":")[0], r["row"]): r for r in ss.classes["totalization"]["rows"]}

    def test_divrem_rows(self):
        spec, ss = self.sample("11_int_divrem")
        rows = self.rows(ss)
        for fn, row in (("@sdiv_qc", "sdiv(a, 0)"), ("@sdiv_qc", "sdiv(INT_MIN, -1)"), ("@udiv_qc", "udiv(a, 0)"),
                        ("@srem_qc", "srem(INT_MIN, -1)"), ("@urem_qq", "urem(a, 0)")):
            self.assertIn("samples", rows[(fn, row)], (fn, row))
        # a hit really hits: sdiv_qc(x, th, c) with x = INT_MIN and c = -1
        s = ss.samples[rows[("@sdiv_qc", "sdiv(INT_MIN, -1)")]["samples"][0]]
        self.assertEqual((s["args"][0], s["args"][2]), ("0x80000000", "0xffffffff"))
        self.assertEqual(ss.classes["trips"]["loops"], [])
        self.assertIn("empty", ss.classes["trips"])
        # baselines first
        self.assertEqual(ss.samples[0], {"call": 0, "args": ["0x00000000", "0x3fe0000000000000", "0x00000003"]})

    def test_exhaustive_and_edges(self):
        spec, ss = self.sample("12_int_widths")
        ex = ss.classes["exhaustive"]
        self.assertEqual(ex["0"]["bits"], 8)
        self.assertEqual(len(ex["0"]["samples"]), 256)
        self.assertEqual(len(ex["3"]["samples"]), 4)          # and_i1: two _Bool registers
        self.assertIn("empty", ex["2"])                       # add_i64: 64 bits
        edge = {tuple(ss.samples[i]["args"][:1]) for i in ss.classes["edge"]["2"]["samples"]}
        self.assertTrue({("0x8000000000000000",), ("0x7fffffffffffffff",), ("0xffffffffffffffff",)} <= edge)
        self.assertIn("empty", ss.classes["specials"]["0"])

    def test_trips(self):
        spec, ss = self.sample("05_while_quantum_cond")
        (lp,) = ss.classes["trips"]["loops"]
        for t in ("0", "3", "4", "5"):
            self.assertIn("sample", lp["trips"][t], t)

    def test_nonarg_registers(self):
        spec, ss = self.sample("113_dicke4")
        self.assertIn("computed inside the program", ss.classes["edge"]["0"]["empty"])
        self.assertEqual(ss.classes["exhaustive"]["0"]["samples"], [0])


if __name__ == "__main__":
    unittest.main(verbosity=2)
