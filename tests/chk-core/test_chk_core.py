#!/usr/bin/env python3
"""tests/chk-core (cq-w0-chk-core): the evaluator core, the trace contract, the violations, stubgen
over the pinned corpus. Run: python3 tests/chk-core/test_chk_core.py [-v]"""
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "checker"))
sys.path.insert(0, str(REPO / "checker" / "rt"))

from cqcheck import run  # noqa: E402
from cqcheck.contracts import DriverSpec, RunResult, to_json  # noqa: E402
import stubgen  # noqa: E402

SPEC = Path(os.environ.get("CQ_SPEC_DIR", REPO.parent / "CQ_spec"))
RT = [REPO / "checker" / "rt" / "core.c", REPO / "checker" / "rt" / "dispatch.c"]
FAM = [HERE / "testfam.c"]
LLVM = run.LLVM_BIN

# frozen trace fields (cq-arch)
FROZEN = {
    "alloc": {"h", "w", "v", "known"}, "tmpl": {"sym", "out", "args"}, "unc": {"sym", "out", "args", "residue"},
    "free": {"h", "v", "known"}, "ry": {"h", "theta", "ctl", "ctlv"}, "ry_qangle": {"h", "a", "aval", "ctl", "ctlv"},
    "phase": {"f", "fv", "theta"}, "phase_qangle": {"a", "aval", "ctl", "ctlv"}, "measure": {"h", "v"},
    "exit": {"live"}, "violation": {"what", "h"},
}


def spec1(proto, fn, ctypes):
    return DriverSpec(example="chk-core", protos=[proto], setup="",
                      calls=[{"fn": fn, "args": [{"ctype": c, "quantum": i == 0} for i, c in enumerate(ctypes)]}])


def go(ll, proto, fn, ctypes, args):
    r = run.run_sample(HERE / ll, spec1(proto, fn, ctypes), {"call": 0, "args": args}, "ours",
                       rt_sources=RT, extra_sources=FAM)
    to_json(r)  # serializable
    return r


def trace_of(ll, proto, fn, ctypes, args):
    """The raw trace of one run (rebuilds through run.build, then runs by hand)."""
    spec = spec1(proto, fn, ctypes)
    prog = run.build(HERE / ll, spec, {}, RT, FAM)
    argv = ["0"]
    for c, a in zip(ctypes, args):
        _, x = run.encode_arg(c, a)
        argv.append(f"b:{x & (2**64 - 1):x}:{x >> 64:x}")
    with tempfile.TemporaryDirectory() as d:
        t = Path(d) / "t.jsonl"
        subprocess.run([str(prog), *argv], env=dict(os.environ, CQE_TRACE=str(t)), check=True, capture_output=True)
        return [json.loads(l) for l in t.read_text().splitlines() if l.strip()]


class CoreGates(unittest.TestCase):
    ARGS = ("int core_all(int,double)", "core_all", ["int", "double"])

    def test_every_core_gate_traces(self):
        ev = trace_of("core_gates.ll", *self.ARGS, [6, 0.25])
        kinds = [e["ev"] for e in ev]
        for e in ev:
            if e["ev"] in FROZEN:
                self.assertTrue(FROZEN[e["ev"]] <= set(e), f"{e} lacks frozen fields {FROZEN[e['ev']]}")
            for k, v in e.items():
                if k in ("v", "residue", "aval", "theta") and v is not None:
                    self.assertRegex(v, r"^0x[0-9a-f]+$", f"{k} of {e}")
        for k in ("alloc", "ry", "ry_qangle", "phase", "phase_qangle", "measure", "free", "tmpl", "unc", "gate",
                  "push", "pop", "ret", "exit"):
            self.assertIn(k, kinds, k)
        self.assertEqual([e for e in ev if e["ev"] == "violation"], [])
        gates = {e["sym"] for e in ev if e["ev"] == "gate"}
        self.assertEqual(gates, {"cqrt_not_i1", "cqrt_and_i1", "cqrt_or_i1", "cqrt_xor_i1", "cqrt_copy_i32",
                                 "cqrt_copy_i32_controlled", "cqrt_xorc_i32", "cqrt_xorc_i32_controlled"})
        ry = [e for e in ev if e["ev"] == "ry"]
        self.assertEqual(ry[0]["theta"], "0x3fd0000000000000")
        self.assertEqual((ry[0]["ctl"], ry[1]["ctlv"], ry[1]["v"]), ([], [1], "0x0"))
        rq = [e for e in ev if e["ev"] == "ry_qangle"]
        self.assertEqual([e["aval"] for e in rq], ["0x3fe0000000000000"] * 2)
        self.assertEqual([e["ctl"] != [] for e in rq], [False, True])
        ph = [e for e in ev if e["ev"] == "phase"][0]
        self.assertEqual((ph["fv"], ph["theta"]), (1, "0x3fd0000000000000"))
        # values: x=6; y copies x then the controlled copy (f=1) zeroes it; z = 5^3^6 = 0
        self.assertEqual([e["v"] for e in ev if e["ev"] == "free"], ["0x0", "0x0", "0x0", "0x1"])
        self.assertTrue(all(e["known"] for e in ev if e["ev"] == "free"))
        tm = [e for e in ev if e["ev"] == "tmpl"]
        self.assertEqual((tm[0]["v"], tm[0]["args"]), ("0x9", [{"h": 1, "v": "0x6"}, {"lit": "0x3"}]))
        self.assertEqual(tm[1]["v"], "0x1")   # 7 + 250 mod 2^8, through the i8-only handler
        self.assertEqual([e["residue"] for e in ev if e["ev"] == "unc"], ["0x0"])
        self.assertEqual([e["word"] for e in ev if e["ev"] == "pop"], [1])
        ret = [e for e in ev if e["ev"] == "ret"][0]
        self.assertEqual(ret["v"], hex(6 + 1 + 1))
        live = {e["h"]: e["role"] for e in ev[-1]["live"]}
        self.assertEqual(ev[-1]["ev"], "exit")
        roles = sorted(live.values())
        self.assertEqual(roles, ["frozen", "frozen", "measured", "measured", "measured", "measured"])

    def test_run_result_shape(self):
        r = go("core_gates.ll", *self.ARGS, [6, 0.25])
        self.assertIsInstance(r, RunResult)
        self.assertEqual(r.violations, [])
        self.assertEqual(r.outputs["ret"][0]["v"], {"w": "i32", "v": "0x8"})
        self.assertEqual([m["v"] for m in r.measured], ["0x1", "0x3fe0000000000000", "0x6", "0x1"])
        self.assertEqual([x["ev"] for x in r.rotations],
                         ["ry", "phase", "ry", "ry_qangle", "ry_qangle", "phase_qangle", "phase_qangle"])
        self.assertEqual(len(r.kept), 6)
        self.assertEqual(len(r.clean), 4)

    def test_handles_deterministic(self):
        a = go("core_gates.ll", *self.ARGS, [6, 0.25])
        b = go("core_gates.ll", *self.ARGS, [-3, 0.25])
        self.assertEqual([x.get("h") for x in a.rotations], [x.get("h") for x in b.rotations])
        self.assertEqual([k["h"] for k in a.kept], [k["h"] for k in b.kept])


class Violations(unittest.TestCase):
    ARGS = ("int v(int,double)", "v", ["int", "double"])

    def what(self, ll, x0=5):
        r = go(ll, *self.ARGS, [x0, 0.5])
        return [v["what"] for v in r.violations]

    def test_clean_has_none(self):
        self.assertEqual(self.what("ok_clean.ll"), [])

    def test_dirty_free(self):
        self.assertEqual(self.what("v_dirty_free.ll"), ["dirty_free"])

    def test_unc_residue(self):
        self.assertEqual(self.what("v_unc_residue.ll"), ["unc_residue", "dirty_free"])

    def test_use_after_free(self):
        self.assertEqual(self.what("v_use_after_free.ll"), ["use_after_free"])

    def test_bad_handle(self):
        self.assertEqual(self.what("v_bad_handle.ll"), ["bad_handle"])

    def test_unc_after_nondiagonal(self):
        self.assertEqual(self.what("v_unc_after_nondiagonal.ll"), ["unc_after_nondiagonal", "dirty_free"])

    def test_no_family(self):
        self.assertEqual(self.what("v_no_family.ll"), ["no_family"])

    def test_default_runtime_links_family_constructors(self):
        """Without rt_sources, run.py links every checker/rt/*.c as objects, so a merged family's
        registering constructor is present (tmpl-int's add here)."""
        if not (REPO / "checker" / "rt" / "tmpl_int.c").exists():
            self.fail("tmpl_int.c is not merged; this test needs a family registering add")
        r = run.run_sample(HERE / "ok_clean.ll", spec1(*self.ARGS), {"call": 0, "args": [5, 0.5]}, "ours")
        self.assertEqual(r.violations, [])

    def test_sample_and_build_failures_are_results(self):
        r = run.run_sample(HERE / "ok_clean.ll", spec1(*self.ARGS), {"call": 0, "args": [1]}, "ours",
                           rt_sources=RT, extra_sources=FAM)
        self.assertEqual([v["what"] for v in r.violations], ["sample"])
        with tempfile.TemporaryDirectory() as d:
            bad = Path(d) / "undef.ll"
            bad.write_text('target triple = "x86_64-apple-macosx16.0.0"\ndeclare i32 @__cq_q_ext_fn_10(i32)\n'
                           'define i32 @v(i32 %a, double %b) {\n  %r = call i32 @__cq_q_ext_fn_10(i32 %a)\n  ret i32 %r\n}\n')
            r = run.run_sample(bad, spec1(*self.ARGS), {"call": 0, "args": [1, 0.5]}, "ours", rt_sources=RT)
            self.assertEqual([v["what"] for v in r.violations], ["build"])


class MultiWord(unittest.TestCase):
    def test_wide_rails(self):
        v = (1 << 127) | 0x1234
        r = go("multiword.ll", "unsigned __int128 wide(unsigned __int128,long double)", "wide",
               ["unsigned __int128", "long double"], [v, 1.5])
        self.assertEqual(r.violations, [])
        f80 = run._f80_bits(1.5)
        self.assertEqual([m["v"] for m in r.measured], [hex(v), hex((1 << 100) - 1), hex(f80)])
        self.assertEqual(r.outputs["ret"][0]["v"]["w"], "i128")
        self.assertEqual(int(r.outputs["ret"][0]["v"]["v"], 16), v ^ ((1 << 100) - 1) ^ f80)
        self.assertEqual({k["w"] for k in r.kept}, {"i128", "i100", "f80"})


class Parser(unittest.TestCase):
    def classify(self, lines):
        with tempfile.TemporaryDirectory() as d:
            exe = Path(d) / "classify"
            subprocess.run([str(LLVM / "clang"), "-std=c17", "-O1", "-w", "-I", str(REPO / "checker" / "rt"),
                            str(HERE / "classify.c"), *map(str, RT), "-o", str(exe)], check=True)
            p = subprocess.run([str(exe)], input="\n".join(lines) + "\n", capture_output=True, text=True)
            return p.returncode, p.stdout

    def test_names(self):
        good = ["cq_template_fadd_f64_hl_rm_exc_unc|void|i32,i32,double,i32",
                "cq_template_trunc_f64|i32|i32", "cq_template_trunc_i64_to_i7_unc|void|i32,i32",
                "cq_template_icmp_sgt_i32_hl|i32|i32,i32", "cq_template_fcmps_olt_f64_exc|i32|i32,i32",
                "cq_template_select_i8_lh|i32|i32,i8,i32", "cq_template_fadd_f64_ll_rmq|i32|double,double,i32",
                "cq_template_qrom_load_f64_s|i32|ptr,i64,i64,i32", "cq_template_uadd_sat_i32|i32|i32,i32",
                "cq_template_fshl_i32_qll|i32|i32,i32,i32", "cq_template_is_fpclass_f64_hl|i32|i32,i32",
                "cqrt_qram_store_i32_hl_controlled_unc|void|i32,i32,i32,i32", "cqrt_tape_write_str_lit|void|i32,ptr",
                "cqrt_ry_i32_qangle_controlled|void|i32,i32,i32", "cqrt_copy_i7_unc|void|i32,i32", "cqrt_abort_i1|void|i32"]
        rc, out = self.classify(good)
        self.assertEqual(rc, 0, out)
        bad = ["cq_template_icmp_foo_i32|i32|i32,i32", "cq_template_add_i0|i32|i32,i32", "cq_template_add_f128|i32|i32,i32",
               "cq_template_add_i32_hl_unc_rm|void|i32,i32,i32", "cqrt_cnot|void|i32,i32", "cq_template_select_i8_lh|i32|i8,i32"]
        rc, out = self.classify(bad)
        self.assertIn(f"failed {len(bad)}", out)


class StubgenCorpus(unittest.TestCase):
    """stubgen covers every cqrt_*/cq_template_* declared in the pinned corpus."""

    def test_corpus(self):
        lowered = sorted(SPEC.glob("examples/*/*.lowered.ll"))
        self.assertTrue(lowered, f"no corpus under {SPEC}")
        lines, failures, nsym = set(), [], 0
        with tempfile.TemporaryDirectory() as d:
            for ll in lowered:
                text = ll.read_text()
                declared = set(re.findall(r"^declare [^@]*@((?:cqrt|cq_template)_[A-Za-z0-9_.]+)\(", text, re.M))
                try:
                    out, names = stubgen.generate([text])
                except stubgen.StubError as e:
                    failures.append(f"{ll.parent.name}: {e}")
                    continue
                nsym += len(names)
                if set(names) != declared:
                    failures.append(f"{ll.parent.name}: stubs {sorted(set(names) ^ declared)}")
                stubs = Path(d) / "stubs.ll"
                stubs.write_text(out)
                p = subprocess.run([str(LLVM / "llvm-link"), str(ll), str(stubs), "-o", os.devnull],
                                   capture_output=True, text=True)
                if p.returncode:
                    failures.append(f"{ll.parent.name}: llvm-link: {p.stderr.strip()[:300]}")
                for name, ret, _, params in (stubgen.parse_decl(l) for l in text.splitlines()
                                             if stubgen.parse_decl(l)):
                    lines.add(f"{name}|{ret}|{','.join(t for t, _ in params)}")
        rc, out = Parser().classify(sorted(lines))
        print(f"\nstubgen corpus: {len(lowered)} lowered files, {nsym} stubs, {len(lines)} distinct declarations; "
              f"{out.strip().splitlines()[-1]}", file=sys.stderr)
        self.assertEqual(failures, [])
        self.assertEqual(rc, 0, out)


if __name__ == "__main__":
    unittest.main()
