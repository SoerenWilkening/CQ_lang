#!/usr/bin/env python3
"""tests/tmpl-int (cq-f69): and, or and xor, the i1 data templates included, are no longer tmpl-int's
(owner ruling on cq-f69: tmpl-bits keeps them). Through the real core and dispatcher (run.py):

  - the default runtime (every checker/rt/*.c) computes them correctly with no violation;
  - core + dispatch + tmpl_bits.c alone computes the same values, so tmpl-bits is what serves them;
  - core + dispatch + tmpl_int.c alone reports no_family, so tmpl-int no longer serves them.

Run: python3 tests/tmpl-int/test_bitops_dispatch.py [-v]"""
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "checker"))

from cqcheck import run  # noqa: E402
from cqcheck.contracts import DriverSpec  # noqa: E402

RT = REPO / "checker" / "rt"
CORE = [RT / "core.c", RT / "dispatch.c"]
LL = HERE / "bitops.ll"
SPEC = DriverSpec(example="tmpl-int-bitops", protos=["int v(int,int)"], setup="",
                  calls=[{"fn": "v", "args": [{"ctype": "int", "quantum": True},
                                              {"ctype": "int", "quantum": True}]}])
M32 = 2**32 - 1
SAMPLES = [(0, 0), (0, -1), (-1, 0), (-1, -1), (1, 0), (0, 1), (1, 1), (-2**31, 2**31 - 1),
           (0x12345678, 0x0F0F00FF), (-0x5A5A5A5B, 0x3C3C3C3C), (7, -8)]


def expected(x0, x1):
    a, b = x0 & M32, x1 & M32
    a1, b1 = a & 1, b & 1
    w = (a << 96) | a
    return [hex(a & b), hex(a | b), hex(a ^ b), hex(a & 0x0F0F0F0F),
            hex(a1 & b1), hex(a1 | b1), hex(a1 ^ b1), hex(a1 ^ 1), hex(w | 2**90)]


def go(x0, x1, rt_sources=None):
    return run.run_sample(LL, SPEC, {"call": 0, "args": [x0, x1]}, "ours", rt_sources=rt_sources)


class BitopsThroughDispatcher(unittest.TestCase):
    def check_values(self, rt_sources):
        for x0, x1 in SAMPLES:
            with self.subTest(x0=x0, x1=x1):
                r = go(x0, x1, rt_sources)
                self.assertEqual(r.violations, [])
                self.assertEqual([int(m["v"], 16) for m in r.measured],
                                 [int(e, 16) for e in expected(x0, x1)])
                self.assertEqual(len(r.clean), 1)  # the xor_i32 forward/_unc pair's rail

    def test_default_runtime(self):
        self.check_values(None)

    def test_tmpl_bits_alone_serves_them(self):
        self.check_values(CORE + [RT / "tmpl_bits.c"])

    def test_tmpl_int_alone_does_not(self):
        r = go(5, 3, CORE + [RT / "tmpl_int.c"])
        syms = [v["msg"].split(":")[0] for v in r.violations if v["what"] == "no_family"]
        self.assertEqual(syms, ["cq_template_and_i32", "cq_template_or_i32", "cq_template_xor_i32",
                                "cq_template_and_i32_hl", "cq_template_xor_i32", "cq_template_xor_i32_unc",
                                "cq_template_and_i1", "cq_template_or_i1", "cq_template_xor_i1",
                                "cq_template_xor_i1_hl", "cq_template_or_i128_hl"])
        # the only other violation is the free of the rail whose forward template had no family
        self.assertEqual([v["what"] for v in r.violations if v["what"] != "no_family"], ["dirty_free"])


if __name__ == "__main__":
    unittest.main()
