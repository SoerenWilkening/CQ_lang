#!/usr/bin/env python3
"""tests/chk-core (cq-w0-chk-core): the evaluator core, the trace contract, the violations, stubgen
over the pinned corpus. Run: python3 tests/chk-core/test_chk_core.py [-v]"""
import bisect
import json
import math
import os
import random
import re
import struct
import subprocess
import sys
import tempfile
import unittest
from fractions import Fraction
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "checker"))
sys.path.insert(0, str(REPO / "checker" / "rt"))

from cqcheck import drivers, run  # noqa: E402
from cqcheck import kept as kept_mod  # noqa: E402
from cqcheck.contracts import DriverSpec, RunResult, to_json  # noqa: E402


def to_json(r):
    """A RunResult as compared across runs: the address tables are this process's (CR §6: host addresses
    differ per run; compare.py reads them relationally)."""
    import dataclasses
    from cqcheck import contracts
    out = {k: v for k, v in r.outputs.items() if k not in ("objects", "regions")} if isinstance(r.outputs, dict) else r.outputs
    return contracts.to_json(dataclasses.replace(r, outputs=out))

import stubgen  # noqa: E402

SPEC = Path(os.environ.get("CQ_SPEC_DIR", REPO.parent / "CQ_spec"))
# core.c reaches the bus (rt_bus.c, cqe__bus_load_of; it needs rt_tape.c) and clone replay (rt_replay.c, cqe__rp_put) since cq-kcn5i
RT = [REPO / "checker" / "rt" / f for f in ("core.c", "dispatch.c", "rt_bus.c", "rt_tape.c", "rt_replay.c")]
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
    prog = run.build(HERE / ll, spec, (), RT, FAM)
    return run_prog(prog, spec, {"call": 0, "args": args})


def run_prog(prog, spec, sample):
    """The trace of one sample run by hand: the driver reads drivers' sample file from $CQD_SAMPLES
    (cq-arch Z2) and runs the sample in a forked child (core.c, shots)."""
    with tempfile.TemporaryDirectory() as d:
        t, f = Path(d) / "t.jsonl", Path(d) / "s"
        f.write_text(drivers.sample_file(spec, [run.canonical_sample(spec, sample)]))
        subprocess.run([str(prog)], env=dict(os.environ, CQE_TRACE=str(t), CQD_SAMPLES=str(f)), check=True,
                       capture_output=True)
        # the runner's shot frames (core.c, cq-e2i9) are not events of the sample
        return [e for e in (json.loads(l) for l in t.read_text().splitlines() if l.strip())
                if e["ev"] not in ("shot", "shot_end")]



def freed(r: RunResult) -> int:
    """The sample's cqrt_free count: the compact trace's summary (run.py, cq-8m6v), which also says
    that no free of the sample was dirty when no tagged free event precedes it."""
    summ = [c for c in r.clean if "freed" in c]
    assert len(summ) == 1 and summ[0] is r.clean[-1], r.clean
    return summ[0]["freed"]

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
        self.assertEqual(freed(r), 4)

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

    def test_handle_zero_is_reserved(self):
        # cq-06bi: CR §1.1 (CQ_spec f684858): handle 0 names no rail
        r = go("v_handle_zero.ll", *self.ARGS, [5, 0.5])
        self.assertEqual([v["what"] for v in r.violations], ["bad_handle"])
        self.assertIn("handle 0 is reserved", r.violations[0]["msg"])


    def test_unc_after_nondiagonal(self):
        self.assertEqual(self.what("v_unc_after_nondiagonal.ll"), ["unc_after_nondiagonal", "dirty_free"])

    def test_no_family(self):
        self.assertEqual(self.what("v_no_family.ll"), ["no_family"])

    def test_measure_reread(self):
        # cq-ihlt: a second cqrt_measure of a measured rail re-reads it (one measure event, same value)
        r = go("measure_reread.ll", *self.ARGS, [5, 0.5])
        self.assertEqual(r.violations, [])
        self.assertEqual(len(r.measured), 1)
        self.assertEqual(r.outputs["ret"][0]["v"]["v"], hex(2 * int(r.measured[0]["v"], 16)))

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

    def test_failed_build_is_cached(self):
        """cq-3ebz: a build that fails is recorded under its hash; every later sample gets the same
        'build' violation without rerunning the toolchain, alone or as a batch."""
        with tempfile.TemporaryDirectory() as d, tempfile.TemporaryDirectory() as cache:
            bad = Path(d) / "undef.ll"
            bad.write_text('target triple = "x86_64-apple-macosx16.0.0"\ndeclare i32 @__cq_q_ext_fn_11(i32)\n'
                           'define i32 @v(i32 %a, double %b) {\n  %r = call i32 @__cq_q_ext_fn_11(i32 %a)\n  ret i32 %r\n}\n')
            spec = spec1(*self.ARGS)
            old_env, old_sh = os.environ.get("CQE_CACHE"), run._sh
            os.environ["CQE_CACHE"] = cache
            try:
                first = run.run_sample(bad, spec, {"call": 0, "args": [1, 0.5]}, "ours", rt_sources=RT)
                self.assertEqual([v["what"] for v in first.violations], ["build"])
                self.assertEqual(len(list((Path(cache) / "prog").glob("*.build_error"))), 1)

                def no_tool(cmd, cwd=None):
                    raise AssertionError(f"toolchain rerun for a cached failure: {cmd[0]}")
                run._sh = no_tool
                again = run.run_sample(bad, spec, {"call": 0, "args": [2, 1.5]}, "ours", rt_sources=RT)
                self.assertEqual(again.violations, first.violations)
                batch = run.run_samples(bad, spec, [{"call": 0, "args": [i, 0.5]} for i in range(5)]
                                        + [{"call": 0, "args": [1]}], "ours", rt_sources=RT)
                self.assertEqual([r.violations for r in batch[:5]], [first.violations] * 5)
                self.assertEqual([v["what"] for v in batch[5].violations], ["sample"])
                self.assertEqual([r.sample["args"][0] for r in batch[:5]], list(range(5)))
            finally:
                run._sh = old_sh
                if old_env is None:
                    os.environ.pop("CQE_CACHE", None)
                else:
                    os.environ["CQE_CACHE"] = old_env

    def test_batch_equals_one_by_one(self):
        """run_samples gives each sample run_sample's RunResult, in order (report.evaluate's path)."""
        spec = spec1(*self.ARGS)
        samples = [{"call": 0, "args": [x, 0.5]} for x in (0, 1, -3, 5)] + [{"call": 0, "args": [1]}]
        batch = run.run_samples(HERE / "ok_clean.ll", spec, samples, "ours", rt_sources=RT, extra_sources=FAM)
        one = [run.run_sample(HERE / "ok_clean.ll", spec, s, "ours", rt_sources=RT, extra_sources=FAM)
               for s in samples]
        self.assertEqual([to_json(r) for r in batch], [to_json(r) for r in one])
        saved = run.MIN_PART
        run.MIN_PART = 1    # several runner processes, each over a strided part of the batch
        try:
            workers = run.run_samples(HERE / "ok_clean.ll", spec, samples, "ours", 3, rt_sources=RT,
                                      extra_sources=FAM)
        finally:
            run.MIN_PART = saved
        self.assertEqual([to_json(r) for r in workers], [to_json(r) for r in one])
        self.assertTrue(all(w.sample is s for w, s in zip(workers, samples)))


class DiskCaps(unittest.TestCase):
    """cq-3fjt: no runner writes GBs. A sample past a cap ends with a trace_cap violation (as by
    SIGXFSZ) and the samples around it are unaffected; a trace past $CQE_TRACE_ROTATE goes on in a
    fresh runner with the same results. Each test has a cache of its own (a cap changes results)."""
    V = ("int v(int,double)", "v", ["int", "double"])
    P = ("int p(int,double)", "p", ["int", "double"])

    def setUp(self):
        self._cache = tempfile.TemporaryDirectory()
        self._env = {k: os.environ.get(k) for k in ("CQE_CACHE", "CQE_SHOT_TRACE_MAX", "CQE_SHOT_OUTPUT_MAX",
                                                     "CQE_TRACE_ROTATE", "CQE_SHOT_VIOL_MAX")}
        os.environ["CQE_CACHE"] = self._cache.name
        os.environ["CQE_SHOT_VIOL_MAX"] = "0"     # the disk caps alone (ViolationCap tests the violation cap)

    def tearDown(self):
        for k, v in self._env.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        self._cache.cleanup()

    def batch(self, fn, ns):
        return run.run_samples(HERE / "disk_flood.ll", spec1(*fn), [{"call": 0, "args": [n, 0.5]} for n in ns],
                               "ours", rt_sources=RT, extra_sources=FAM)

    def whats(self, r):
        return [v["what"] for v in r.violations]

    def test_trace_cap(self):
        os.environ["CQE_SHOT_TRACE_MAX"] = "200000"
        rs = self.batch(self.V, [3, 10 ** 7, 4])
        self.assertEqual(self.whats(rs[0]), ["bad_handle"] * 3)
        self.assertEqual(self.whats(rs[2]), ["bad_handle"] * 4)
        w = self.whats(rs[1])
        self.assertIn("trace_cap", w)
        self.assertIn("signal", w)
        self.assertLess(w.count("bad_handle"), 3000)   # ~90 bytes each: it stopped at the cap
        self.assertIn("cq-3fjt", next(v["msg"] for v in rs[1].violations if v["what"] == "trace_cap"))

    def test_trace_cap_default(self):
        # the default per-sample cap (32 MiB) stops the 15 GB sample of cq-3fjt's report
        rs = self.batch(self.V, [10 ** 8])
        self.assertIn("trace_cap", self.whats(rs[0]))

    def test_output_cap(self):
        os.environ["CQE_SHOT_OUTPUT_MAX"] = "100000"
        rs = self.batch(self.P, [5, 10 ** 8, 6])
        self.assertEqual([r.violations for r in (rs[0], rs[2])], [[], []])
        self.assertEqual([r.outputs["stdout"] for r in (rs[0], rs[2])], ["xxxxx", "xxxxxx"])
        self.assertIn("trace_cap", self.whats(rs[1]))
        self.assertIn("stdout", next(v["msg"] for v in rs[1].violations if v["what"] == "trace_cap"))

    def test_rotation_keeps_results(self):
        ns = [50, 120, 7, 300, 1, 90, 200, 3]
        want = [to_json(r) for r in self.batch(self.V, ns)]
        self._cache.cleanup()
        self._cache = tempfile.TemporaryDirectory()
        os.environ["CQE_CACHE"] = self._cache.name
        os.environ["CQE_TRACE_ROTATE"] = "20000"      # a rotation every few samples
        got = self.batch(self.V, ns)
        self.assertEqual([to_json(r) for r in got], want)
        self.assertEqual([self.whats(r).count("bad_handle") for r in got], ns)


class ViolationCap(unittest.TestCase):
    """cq-r8-chk176: a sample past $CQE_SHOT_VIOL_MAX violations (default 256) ends there with a
    violation_cap violation, as at a disk cap; the samples around it are unaffected and keep every
    violation below the cap. 176's lowering logged 350k violations a sample (32 MiB of trace, seconds
    and ~300 MB each), and its run passed heavy.sh's 2 GB cap."""

    V = DiskCaps.V
    tearDown, batch, whats = DiskCaps.tearDown, DiskCaps.batch, DiskCaps.whats

    def setUp(self):
        DiskCaps.setUp(self)
        os.environ.pop("CQE_SHOT_VIOL_MAX", None)     # the default

    def test_violation_cap_default(self):
        rs = self.batch(self.V, [3, 10 ** 8, 256, 4])
        self.assertEqual(self.whats(rs[0]), ["bad_handle"] * 3)
        self.assertEqual(self.whats(rs[2]), ["bad_handle"] * 256)   # at the cap: not past it
        self.assertEqual(self.whats(rs[3]), ["bad_handle"] * 4)
        w = self.whats(rs[1])
        self.assertEqual(w.count("bad_handle"), 257)
        self.assertIn("violation_cap", w)
        self.assertNotIn("trace_cap", w)
        self.assertIn("signal", w)
        self.assertIn("more than 256 violations", next(v["msg"] for v in rs[1].violations
                                                      if v["what"] == "violation_cap"))

    def test_violation_cap_env(self):
        os.environ["CQE_SHOT_VIOL_MAX"] = "10"
        rs = self.batch(self.V, [10, 11, 2])
        self.assertEqual(self.whats(rs[0]), ["bad_handle"] * 10)
        self.assertEqual(self.whats(rs[1]).count("bad_handle"), 11)
        self.assertIn("violation_cap", self.whats(rs[1]))
        self.assertEqual(self.whats(rs[2]), ["bad_handle"] * 2)


class Sweep(unittest.TestCase):
    """cq-3fjt: tmpdirs.sweep removes run dirs whose owner is dead and keeps every other one."""

    def test_sweep(self):
        from cqcheck import tmpdirs
        dead = subprocess.Popen(["true"])
        dead.wait()
        with tempfile.TemporaryDirectory() as root:
            r = Path(root)

            def mk(name, owner=None, age=0.0):
                d = r / name
                (d / "shot").mkdir(parents=True)
                (d / "trace.jsonl").write_text("x" * 1000)
                if owner is not None:
                    (d / "owner").write_text(f"{owner}\n")
                if age:
                    t = __import__("time").time() - age
                    for q in (d / "shot", d / "trace.jsonl", d / "owner", d):
                        if q.exists():
                            os.utime(q, (t, t))
                return d
            gone = mk("cqe-run.dead", dead.pid)
            gone_o = mk("cqo-run.dead", dead.pid)
            live = mk("cqe-run.live", os.getpid(), age=10 * tmpdirs.LEGACY_AGE)   # old, but its owner lives
            live_o = mk("cqo-run.live", os.getppid())
            fresh = mk("cqe-run.noowner")                                        # mkdtemp before the owner file
            old = mk("cqo-run.noowner", age=2 * tmpdirs.LEGACY_AGE)              # left by a pre-cq-3fjt run
            other = mk("cqd-run.dead", dead.pid)                                 # not a run dir
            removed = tmpdirs.sweep(r)
            self.assertEqual(sorted(removed), sorted([gone, gone_o, old]))
            for d in (live, live_o, fresh, other):
                self.assertTrue(d.is_dir(), d)
            for d in (gone, gone_o, old):
                self.assertFalse(d.exists(), d)

    def test_make_run_dir_names_its_owner(self):
        from cqcheck import tmpdirs
        d = tmpdirs.make_run_dir("cqe-run.")
        try:
            self.assertEqual(int((d / "owner").read_text()), os.getpid())
            self.assertNotIn(d, tmpdirs.sweep(d.parent))
            self.assertTrue(d.is_dir())
        finally:
            import shutil
            shutil.rmtree(d)
        w = run._work_dir()
        self.assertEqual(int((w / "owner").read_text()), os.getpid())


class ShotReset(unittest.TestCase):
    """cq-e2i9: a batch runs in one runner process that forks one child per sample (core.c, shots);
    nothing of sample i (rails, handles, violations, a dirty free, a signal, _exit, fenv, program
    globals) is visible in sample i+1. shot_reset.ll's mode 0 is clean; every other mode leaves state."""
    ARGS = ("int sr(int,double)", "sr", ["int", "double"])

    def test_no_state_crosses_samples(self):
        spec = spec1(*self.ARGS)
        modes = [0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 0]
        samples = [{"call": 0, "args": [m, 0.5]} for m in modes]
        alone = run.run_samples(HERE / "shot_reset.ll", spec, [samples[0]], "ours", 1, rt_sources=RT,
                                extra_sources=FAM)[0]
        self.assertEqual(alone.violations, [])
        self.assertEqual(alone.outputs["ret"][0]["v"], {"w": "i32", "v": "0x1"})  # counter fresh, round-to-nearest
        self.assertEqual(alone.outputs["exit"], 0)
        batch = run.run_samples(HERE / "shot_reset.ll", spec, samples, "ours", 1, rt_sources=RT,
                                extra_sources=FAM)
        for m, r in zip(modes, batch):
            if m == 0:
                self.assertEqual(to_json(r), to_json(alone), f"a clean sample saw earlier state: {r}")
        whats = {m: [v["what"] for v in r.violations] for m, r in zip(modes, batch)}
        self.assertIn("dirty_free", whats[1])
        self.assertEqual(whats[2], ["signal", "no_exit"])
        self.assertEqual(batch[3].outputs["exit"], -8)
        self.assertIn("bad_handle", whats[3])
        self.assertEqual(whats[4], ["no_exit"])
        self.assertEqual(batch[7].outputs["exit"], 7)
        self.assertEqual(whats[5], [])
        self.assertEqual(batch[9].outputs["ret"][0]["v"], {"w": "i32", "v": "0x0"})
        # several runners, each over a strided part: the same results
        saved = run.MIN_PART
        run.MIN_PART = 1
        try:
            par = run.run_samples(HERE / "shot_reset.ll", spec, samples, "ours", 3, rt_sources=RT,
                                  extra_sources=FAM)
        finally:
            run.MIN_PART = saved
        self.assertEqual([to_json(r) for r in par], [to_json(r) for r in batch])

    def part(self, modes, timeout, budget):
        spec = spec1(*self.ARGS)
        samples = [{"call": 0, "args": [m, 0.5]} for m in modes]
        prog = run.build(HERE / "shot_reset.ll", spec, (), RT, FAM)
        items = [(s, drivers.sample_file(spec, [run.canonical_sample(spec, s)]), None) for s in samples]
        saved = run.STEP_BUDGET
        run.STEP_BUDGET = budget
        try:
            return run._run_part(prog, items, "ours", timeout)
        finally:
            run.STEP_BUDGET = saved

    def test_runner_dying_at_startup_is_no_shot(self):
        """cq-9a9i (speed review h2, owner 2026-11-01: a permanent rejection test): the per-thread trace
        file is reused across batches; a runner that dies before core.c opens it (here /usr/bin/false)
        must read as no shots, never as the previous batch's passing sample left in the file."""
        w = run._work_dir()
        (w / "trace.jsonl").write_text("".join(json.dumps(e) + "\n" for e in (
            {"ev": "shot", "k": 0},
            {"ev": "ret", "v": "0x7", "w": "i64", "call": 0, "fn": "f"},
            {"ev": "exit", "live": []},
            {"ev": "shot_end", "k": 0, "code": 0, "timeout": 0, "stdout": "", "stderr": "", "freed": 0,
             "fdig": "0xcbf29ce484222325"})))
        res = run._run_part("/usr/bin/false", [({"call": 0, "args": []}, "rec\n", None)], "ours", 5.0)
        self.assertEqual(len(res), 1)
        self.assertEqual(res[0].outputs["ret"], [], "the previous batch's ret was read back")
        self.assertIn("runner", [v["what"] for v in res[0].violations])

    def test_timeout_ends_one_sample_only(self):
        """A sample that never returns (mode 6) is a timeout, by the step budget (cq-o4ul); the samples
        around it are clean."""
        res = self.part((0, 6, 0, 6, 0), 30.0, 1 << 16)
        self.assertEqual([[v["what"] for v in r.violations] for r in res], [[], ["timeout"], [], ["timeout"], []])
        self.assertEqual(len({to_json(r) for r in (res[0], res[2], res[4])}), 1)

    def test_cpu_backstop(self):
        """With no step budget, a sample that never returns ends at its CPU-time limit."""
        res = self.part((0, 6, 0), 0.5, 0)
        self.assertEqual([[v["what"] for v in r.violations] for r in res], [[], ["timeout"], []])

    def test_wall_time_is_no_timeout(self):
        """cq-o4ul: a sample that takes 1.5 s of wall time (mode 7; a loaded machine) under a 1 s limit is
        not a timeout: the limits count steps and CPU time, never wall time."""
        res = self.part((0, 7, 0), 1.0, 1 << 16)
        self.assertEqual([r.violations for r in res], [[], [], []])
        self.assertEqual(res[1].outputs, res[0].outputs)
        self.assertEqual(res[1].kept, res[0].kept)

    def test_fresh_worker_takes_its_own_stack_copy(self):
        """cq-o4ul: a worker forked after a crash (mode 1) saved the stack into the block the previous
        worker had allocated, memory of no one in the new worker; whether the C library then handed it
        out, and the sample's bytes were put back over the driver's stack, depended on the CPU the
        worker ran on. core.c checks the copy is its own block (a stale one ends the runner, 98)."""
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            exe = d / "shot_stack"
            subprocess.run([str(LLVM / "clang"), "-std=c17", "-O1", "-w", "-I", str(REPO / "checker" / "rt"),
                            str(HERE / "shot_stack.c"), *map(str, RT), "-o", str(exe)], check=True)
            (d / "shot").mkdir()
            modes = "0121012"
            env = dict(os.environ, CQE_TRACE=str(d / "t.jsonl"), CQE_SHOT_DIR=str(d / "shot"))
            p = subprocess.run([str(exe), modes], env=env, capture_output=True, text=True, timeout=60)
            self.assertEqual(p.returncode, 0, p.stderr)
            ev = [json.loads(l) for l in (d / "t.jsonl").read_text().splitlines() if l.strip()]
            self.assertEqual([e["i"] for e in ev if e["ev"] == "mark"], [i for i, m in enumerate(modes) if m != "1"])
            self.assertEqual([(e["k"], e["code"]) for e in ev if e["ev"] == "shot_end"],
                             [(i, -8 if m == "1" else 0) for i, m in enumerate(modes)])


class ThetaSubstitution(unittest.TestCase):
    """cq-6m2 (cq-arch Z4): with $CQE_THETA, a firing Ry takes the earliest schedule reach of its width
    and angle, and its ry event logs the chosen value; a control reading 0 takes nothing."""
    ARGS = ("int ts(int,double)", "ts", ["int", "double"])

    def trace(self, theta):
        spec = spec1(*self.ARGS)
        prog = run.build(HERE / "theta_subst.ll", spec, (), RT, FAM)
        with tempfile.TemporaryDirectory() as d:
            t, f, th = Path(d) / "t.jsonl", Path(d) / "s", Path(d) / "theta"
            f.write_text(drivers.sample_file(spec, [run.canonical_sample(spec, {"call": 0, "args": [0, 0.5]})]))
            env = dict(os.environ, CQE_TRACE=str(t), CQD_SAMPLES=str(f))
            env.pop("CQE_THETA", None)
            if theta is not None:
                th.write_text(theta)
                env["CQE_THETA"] = str(th)
            subprocess.run([str(prog)], env=env, check=True, capture_output=True)
            # the runner's shot frames (core.c, cq-e2i9) are not events of the sample
            return [e for e in (json.loads(l) for l in t.read_text().splitlines() if l.strip())
                    if e["ev"] not in ("shot", "shot_end")]

    @staticmethod
    def ry(ev):
        return [(e["ev"], e["h"], e["v"]) for e in ev if e["ev"] in ("ry", "ry_qangle")]

    def test_no_schedule_is_the_identity(self):
        ev = self.trace(None)
        self.assertEqual(self.ry(ev), [("ry", 1, "0x5"), ("ry", 2, "0x0"), ("ry", 3, "0x0"), ("ry_qangle", 5, "0x9")])
        self.assertFalse([e for e in ev if e["ev"] in ("violation", "theta_unmatched")])

    def test_reaches_by_width_and_angle(self):
        # schedule order differs from the gate order: the match is by width and angle, earliest first
        ev = self.trace("0x4008000000000000 i32 0x2a\n0x4000000000000000 i8 0x7\n0x3ff0000000000000 i1 0x1\n"
                        "0x3fe0000000000000 i8 0xff\n0x3fe0000000000000 i8 0x11\n")
        self.assertEqual(self.ry(ev), [("ry", 1, "0xff"), ("ry", 2, "0x1"), ("ry", 3, "0x7"), ("ry_qangle", 5, "0x2a")])
        self.assertEqual([e["v"] for e in ev if e["ev"] == "measure"], ["0xff", "0x7", "0x2a"])
        self.assertEqual([e["v"] for e in ev if e["ev"] == "ret"], [hex(0xff + 7 + 0x2a)])
        self.assertFalse([e for e in ev if e["ev"] in ("violation", "theta_unmatched")])

    def test_control_zero_takes_nothing_and_misses_are_logged(self):
        ev = self.trace("0x3fe0000000000000 i8 0x3\n0x3ff0000000000000 i1 0x0\n0x4000000000000000 i8 0x7\n")
        self.assertEqual(self.ry(ev), [("ry", 1, "0x3"), ("ry", 2, "0x0"), ("ry", 3, "0x0"), ("ry_qangle", 5, "0x9")])
        miss = [e for e in ev if e["ev"] == "theta_unmatched"]
        self.assertEqual([(e["h"], e["w"], e["angle"]) for e in miss], [(5, "i32", "0x4008000000000000")])

    def test_angle_a_few_ulps_off_takes_its_reach(self):
        # no exact angle: the nearest untaken reach of the width within THETA_NEAR_ULPS (logged)
        ev = self.trace("0x3fe0000000000003 i8 0x2a\n0x3ff0000000000000 i1 0x0\n0x4000000000000000 i8 0x7\n"
                        "0x4108000000000000 i32 0x1\n")
        self.assertEqual(self.ry(ev), [("ry", 1, "0x2a"), ("ry", 2, "0x0"), ("ry", 3, "0x0"), ("ry_qangle", 5, "0x9")])
        self.assertEqual([(e["h"], e["reach"]) for e in ev if e["ev"] == "theta_near"], [(1, "0x3fe0000000000003")])
        self.assertEqual([e["h"] for e in ev if e["ev"] == "theta_unmatched"], [5])   # far off: kept

    def test_wide_and_fp_values(self):
        ev = self.trace("0x3fe0000000000000 i8 0x1ff\n0x3ff0000000000000 i1 0x3\n0x4000000000000000 i8 0x80\n"
                        "0x4008000000000000 i32 0x123456789\n")
        self.assertEqual(self.ry(ev), [("ry", 1, "0xff"), ("ry", 2, "0x1"), ("ry", 3, "0x80"),
                                       ("ry_qangle", 5, "0x23456789")])


class ThetaPreAndUnprep(ThetaSubstitution):
    """cq-3o3v: a firing Ry's event carries "pre", its target's value before the gate (before the
    substitution); a firing Ry that takes no reach and is the adjoint of the last Ry on a rail
    nothing wrote since puts that Ry's pre-value back after it is logged (CR rule 10's un-prep)."""
    ARGS = ("int tu(int,double)", "tu", ["int", "double"])

    def trace(self, theta):
        spec = spec1(*self.ARGS)
        prog = run.build(HERE / "theta_unprep.ll", spec, (), RT, FAM)
        with tempfile.TemporaryDirectory() as d:
            t, f, th = Path(d) / "t.jsonl", Path(d) / "s", Path(d) / "theta"
            f.write_text(drivers.sample_file(spec, [run.canonical_sample(spec, {"call": 0, "args": [0, 0.5]})]))
            env = dict(os.environ, CQE_TRACE=str(t), CQD_SAMPLES=str(f))
            env.pop("CQE_THETA", None)
            if theta is not None:
                th.write_text(theta)
                env["CQE_THETA"] = str(th)
            subprocess.run([str(prog)], env=env, check=True, capture_output=True)
            return [e for e in (json.loads(l) for l in t.read_text().splitlines() if l.strip())
                    if e["ev"] not in ("shot", "shot_end")]

    def test_pre_and_unprep(self):
        ev = self.trace("0x3fe0000000000000 i32 0x2a\n0x3fd0000000000000 i32 0x10\n"
                        "0x3fe8000000000000 i32 0x7\n0x3fe8000000000000 i32 0x9\n")
        self.assertEqual([(e["h"], e["pre"], e["v"]) for e in ev if e["ev"] == "ry"],
                         [(1, "0x3", "0x2a"), (1, "0x2a", "0x2a"), (2, "0x3", "0x10"), (2, "0x11", "0x11"),
                          (3, "0x3", "0x7"), (3, "0x7", "0x9")])
        self.assertEqual([e["v"] for e in ev if e["ev"] == "measure"], ["0x3", "0x11", "0x9"])

    def test_no_schedule_no_unprep(self):
        ev = self.trace(None)
        self.assertEqual([e["v"] for e in ev if e["ev"] == "measure"], ["0x3", "0x2", "0x3"])

    # the inherited cases are theta_subst.ll's
    test_no_schedule_is_the_identity = test_reaches_by_width_and_angle = None
    test_control_zero_takes_nothing_and_misses_are_logged = test_angle_a_few_ulps_off_takes_its_reach = None
    test_wide_and_fp_values = None


class HandlerOrder(unittest.TestCase):
    """M1 (cq-mgi) multi-handler dispatch through the real core (cq-f69), with multifam.c's three
    handlers for mul: first acceptor wins, a decline's writes are discarded, -1 ends the search,
    all declining is no_family, a duplicate registration is a no-op."""
    ARGS = ("int v(int,double)", "v", ["int", "double"])

    def run_m1(self, ll, x0):
        return run.run_sample(HERE / ll, spec1(*self.ARGS), {"call": 0, "args": [x0, 0.5]}, "ours",
                              rt_sources=RT, extra_sources=[HERE / "multifam.c"])

    def test_first_acceptor_and_discarded_writes(self):
        for x0 in (0, 7, -3, 0x12345678):
            with self.subTest(x0=x0):
                r = self.run_m1("m1_order.ll", x0)
                self.assertEqual(r.violations, [])
                self.assertEqual([int(m["v"], 16) for m in r.measured],
                                 [(x0 * 3) & 0xFF, (x0 * 5) & 0xFFFFFFFF])

    def test_fail_ends_the_search(self):
        r = self.run_m1("m1_fail_stops.ll", 7)
        self.assertEqual([v["what"] for v in r.violations], ["fail"])
        self.assertEqual([m["v"] for m in r.measured], ["0x0"])  # mf_c (7*3+1) never ran

    def test_all_decline_is_no_family(self):
        r = self.run_m1("m1_all_decline.ll", 7)
        self.assertEqual([v["what"] for v in r.violations], ["no_family"])
        self.assertIn("every registered handler declined", r.violations[0]["msg"])


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


class FpBitPatternArgs(unittest.TestCase):
    """cq-a4mf: a sample's '0x...' value is the exact bit pattern (drivers.c_value), so 0.5 given as
    its pattern reaches the lowered program as 0.5, at every fp width."""
    CTYPES = ["_Float16", "float", "double", "long double"]
    HALF = ["0x3800", "0x3f000000", "0x3fe0000000000000", "0x3ffe8000000000000000"]

    def test_encode_arg_is_the_bit_pattern(self):
        for c, v in zip(self.CTYPES, self.HALF):
            self.assertEqual(run.encode_arg(c, v), ("bits", int(v, 16)), c)
        self.assertEqual(run.encode_arg("int", "0xffffffff"), ("bits", 0xffffffff))
        self.assertEqual(run.encode_arg("double", "0x1p-1"), ("bits", 0x3fe0000000000000))

    def test_half_reaches_the_lowered_program(self):
        r = go("fp_args.ll", "int fpargs(_Float16,float,double,long double)", "fpargs", self.CTYPES, self.HALF)
        self.assertEqual(r.violations, [])
        self.assertEqual([int(m["v"], 16) for m in r.measured], [int(v, 16) for v in self.HALF])
        self.assertEqual([m["v"] for m in r.measured][2], hex(run._fp_bits(0.5, 64)))


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
                "cq_template_uadd_sat_i32|i32|i32,i32",
                "cq_template_fshl_i32_qll|i32|i32,i32,i32", "cq_template_is_fpclass_f64_hl|i32|i32,i32",
                "cqrt_qram_store_i32_hl_controlled|void|i32,i32,i64,i32", "cqrt_qram_swap_i1|void|i32,i32,i32",
                "cqrt_qram_load_i32_hl_unc|void|i32,i32,i64", "cqrt_qram_alloc_i8|i32|i32",
                "cqrt_ry_i32_qangle_controlled|void|i32,i32,i32", "cqrt_copy_i7_unc|void|i32,i32", "cqrt_abort_i1|void|i32",
                # cq-9ge: W = bf16, LLVM type bfloat
                "cq_template_fadd_bf16_hl|i32|i32,bfloat", "cq_template_bitcast_bf16_to_i16_l|i32|bfloat",
                "cq_template_bitcast_i16_to_bf16_unc|void|i32,i32", "cqrt_alloc_bf16|i32|bfloat",
                "cqrt_measure_bf16|bfloat|i32",
                ]
        rc, out = self.classify(good)
        self.assertEqual(rc, 0, out)
        bad = ["cq_template_icmp_foo_i32|i32|i32,i32", "cq_template_add_i0|i32|i32,i32", "cq_template_add_f128|i32|i32,i32",
               "cq_template_add_i32_hl_unc_rm|void|i32,i32,i32", "cqrt_cnot|void|i32,i32", "cq_template_select_i8_lh|i32|i8,i32",
               "cq_template_fadd_bf32|i32|i32,i32", "cq_template_fadd_b16|i32|i32,i32",
               # retired (CR §0, ABI §0)
               "cq_template_qrom_load_f64_s|i32|ptr,i64,i64,i32", "cq_template_qrom_load_i32|i32|ptr,i64,i32",
               "cqrt_qram_size|i32|i32", "cqrt_qram_free|void|i32", "cqrt_qram_realloc_i32|i32|i32,i32",
               "cqrt_qram_alloc_host_i32|i32|ptr,i64", "cqrt_tape_write_str_lit|void|i32,ptr",
               "cqrt_tape_str_begin|void|i32", "cqrt_tape_str_end|void|i32",
               "cqrt_clone_register|void|ptr,ptr,ptr,ptr", "cqrt_clone_resolve|ptr|ptr,i32"]
        rc, out = self.classify(bad)
        self.assertIn(f"failed {len(bad)}", out)


def _bf16_value(b):
    return struct.unpack("<f", struct.pack("<I", b << 16))[0]


_BF16_FINITE = [_bf16_value(b) for b in range(0x7F80)]  # +0 .. max, increasing


def _bf16_round(x):
    """Fraction -> nearest bf16 bit pattern, ties to even, overflow to Inf (IEEE)."""
    sign = 0x8000 if x < 0 else 0
    m = abs(x)
    lo = bisect.bisect_right(_BF16_FINITE, m) - 1  # largest finite <= m (Fractions compare exactly)
    vlo = Fraction(_BF16_FINITE[lo])
    if vlo == m:
        return sign | lo
    vhi = Fraction(2) ** 128 if lo == 0x7F7F else Fraction(_BF16_FINITE[lo + 1])
    dlo, dhi = m - vlo, vhi - m
    return sign | (lo if dlo < dhi or (dlo == dhi and lo % 2 == 0) else lo + 1)


def _bf16_add(a, b):
    """CR §2 fadd at bf16: the first NaN operand quieted; Inf - Inf the default NaN 0xFFC0."""
    for x in (a, b):
        if (x & 0x7FFF) > 0x7F80:
            return x | 0x0040
    fa, fb = _bf16_value(a), _bf16_value(b)
    if math.isinf(fa) or math.isinf(fb):
        if math.isinf(fa) and math.isinf(fb) and fa != fb:
            return 0xFFC0
        return a if math.isinf(fa) else b
    s = Fraction(fa) + Fraction(fb)
    if s == 0:
        return 0x8000 if (a == 0x8000 and b == 0x8000) else 0
    return _bf16_round(s)


class Bf16(unittest.TestCase):
    """cq-9ge: bf16 rails (width token bf16, bits 16, kind 'f'), fadd_bf16 with handle and bfloat
    literal operands, and bitcasts bf16<->i16 and bf16->f16 with handle and literal operands, through
    the real core, dispatcher, tmpl_fp.c and tmpl_int.c."""

    SAMPLES = [0x0000, 0x8000, 0x3F80, 0xBF80, 0x7F7F, 0xFF7F, 0x7F80, 0xFF80, 0x7FC1, 0x7F81, 0xFF81, 0x0001,
               0x8001, 0x007F, 0x4049, 0xC2F6, 0x3B80, 0x3B81, 0xBB80, 0x4B80, 0x4B81, 0x1234, 0xABCD]

    def run_bf16(self, rt_sources):
        spec = spec1("int v(int)", "v", ["int"])
        rng = random.Random(9)
        for x in self.SAMPLES + [rng.randrange(0x10000) for _ in range(12)]:
            with self.subTest(x=hex(x)):
                r = run.run_sample(HERE / "bf16.ll", spec, {"call": 0, "args": [x]}, "ours",
                                   rt_sources=rt_sources)
                self.assertEqual(r.violations, [])
                want = [_bf16_add(x, x), _bf16_add(x, 0x3F80), x, 0x4049, x, 0x1234, x]
                self.assertEqual([int(m["v"], 16) for m in r.measured], want)
                self.assertEqual(freed(r), 1)  # the bitcast forward/_unc pair's rail

    def test_core_dispatch_fp_int(self):
        self.run_bf16(RT + [REPO / "checker" / "rt" / "tmpl_fp.c", REPO / "checker" / "rt" / "tmpl_int.c"])

    def test_default_runtime(self):
        self.run_bf16(None)

    def test_rail_width_token(self):
        t = trace_of("bf16.ll", "int v(int)", "v", ["int"], [0x3F80])
        self.assertEqual([e["w"] for e in t if e["ev"] == "alloc"], ["bf16", "i16"])
        self.assertEqual([e["w"] for e in t if e["ev"] == "measure"], ["bf16", "bf16", "i16", "i16", "bf16", "bf16", "f16"])


class StubgenCorpus(unittest.TestCase):
    """stubgen covers every cqrt_*/cq_template_* declared in the pinned corpus."""

    def test_corpus(self):
        lowered = sorted(SPEC.glob("examples/*/*.lowered.ll"))
        self.assertTrue(lowered, f"no corpus under {SPEC}")
        lines, failures, nsym = set(), [], 0
        with tempfile.TemporaryDirectory() as d:
            for ll in lowered:
                text = ll.read_text()
                declared = set(re.findall(r"^declare [^@]*@((?:cqrt|cq_template|__cq_q)_[A-Za-z0-9_.]+)\(", text,
                                          re.M))
                ctexts = [p.read_text() for p in ll.parent.glob("*.O1.ll")]
                csigs = stubgen.c_signatures(ctexts)
                declared = {n for n in declared
                            if not n.startswith(stubgen.CLONE_PREFIX) or stubgen.clone_fn(n) in csigs}
                try:
                    out, names = stubgen.generate([text], ctexts)
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
                    if name.startswith(stubgen.CLONE_PREFIX):
                        continue  # declared clones: StandIn below
                    lines.add(f"{name}|{ret}|{','.join(t for t, _ in params)}")
        rc, out = Parser().classify(sorted(lines))
        print(f"\nstubgen corpus: {len(lowered)} lowered files, {nsym} stubs, {len(lines)} distinct declarations; "
              f"{out.strip().splitlines()[-1]}", file=sys.stderr)
        self.assertEqual(failures, [])
        self.assertEqual(rc, 0, out)


# ---- rule 27 declared clones: one stand-in on both sides (cq-rft) ----------------------------

# The C side: externs nothing defines, probes returning their values (the C oracle models each extern
# with checker/rt/cq_standin.h through OracleInstr.cpp `stubs` and cqo_rt.c `__cqo_mix`).
STANDIN_C = r"""
int e_i(int, int);
double e_d(double, signed char, long long);
long double e_l(long double, short);
unsigned char e_b(_Bool, float);
long long e_w(long long, int *, unsigned);
_Float16 e_h(_Float16, int *, int);
int pi(int a, int b) { return e_i(a, b); }
double pd(double a, signed char b, long long c) { return e_d(a, b, c); }
long double pl(long double a, short b) { return e_l(a, b); }
unsigned char pb(_Bool a, float b) { return e_b(a, b); }
long long pw(long long x, unsigned u) { int c[2] = {1, 2}; return e_w(x, c, u); }
_Float16 ph(float a, int n) { int c[2] = {n, 3}; return e_h((_Float16)a, c, n); }
"""
STANDIN_PROTOS = ("int pi(int,int); double pd(double,signed char,long long); long double pl(long double,short); "
                  "unsigned char pb(_Bool,float); long long pw(long long,unsigned); _Float16 ph(float,int)")
STANDIN_CALLS = [("pi", ["int", "int"]), ("pd", ["double", "signed char", "long long"]),
                 ("pl", ["long double", "short"]), ("pb", ["_Bool", "float"]),
                 ("pw", ["long long", "unsigned"]), ("ph", ["float", "int"])]
STANDIN_SAMPLES = [
    (0, [5, 7]), (0, [-1, 0]), (0, [-2147483648, 2147483647]),
    (1, [0.5, -3, 1 << 40]), (1, ["nan", 127, -1]), (1, ["-0.0", -128, 0]),
    (2, [1.25, -2]), (2, ["inf", 32767]),
    (3, [1, 3.5]), (3, [0, "-inf"]),
    (4, [-1, 7]), (4, [-987654321, 4294967295]),
    (5, [1.5, 9]), (5, [-65504.0, -1]),
]

# The lowered side: each probe calls several declared clones of its extern (quantum and classical
# digits, _ctl), records the forward results, runs each twin and frees. The trace's tmpl events
# carry the clone results; every twin must leave 0.
STANDIN_LL = r"""
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @pi(i32 %a, i32 %b) {
  %ha = call i32 @cqrt_alloc_i32(i32 %a)
  %hb = call i32 @cqrt_alloc_i32(i32 %b)
  %p = call i32 @cqrt_alloc_i1(i1 1)
  %r1 = call i32 @__cq_q_e_i_10(i32 %ha, i32 %b)
  %r2 = call i32 @__cq_q_e_i_01(i32 %a, i32 %hb)
  %r3 = call i32 @__cq_q_e_i_11_t_ctl(i32 %p, i32 %ha, i32 %hb, i32 2)
  call void @__cq_q_e_i_10_unc(i32 %r1, i32 %ha, i32 %b)
  call void @__cq_q_e_i_01_unc(i32 %r2, i32 %a, i32 %hb)
  call void @__cq_q_e_i_11_t_ctl_unc(i32 %p, i32 %r3, i32 %ha, i32 %hb, i32 2)
  call void @cqrt_free(i32 %r1)
  call void @cqrt_free(i32 %r2)
  ret i32 0
}

define double @pd(double %a, i8 %b, i64 %c) {
  %ha = call i32 @cqrt_alloc_f64(double %a)
  %hb = call i32 @cqrt_alloc_i8(i8 %b)
  %hc = call i32 @cqrt_alloc_i64(i64 %c)
  %r1 = call i32 @__cq_q_e_d_111_t(i32 %ha, i32 %hb, i32 %hc, i32 4)
  %r2 = call i32 @__cq_q_e_d_100(i32 %ha, i8 %b, i64 %c)
  call void @__cq_q_e_d_111_t_unc(i32 %r1, i32 %ha, i32 %hb, i32 %hc, i32 4)
  call void @__cq_q_e_d_100_unc(i32 %r2, i32 %ha, i8 %b, i64 %c)
  call void @cqrt_free(i32 %r2)
  ret double 0.0
}

define x86_fp80 @pl(x86_fp80 %a, i16 %b) {
  %ha = call i32 @cqrt_alloc_f80(x86_fp80 %a)
  %hb = call i32 @cqrt_alloc_i16(i16 %b)
  %r1 = call i32 @__cq_q_e_l_11_t(i32 %ha, i32 %hb, i32 4)
  call void @__cq_q_e_l_11_t_unc(i32 %r1, i32 %ha, i32 %hb, i32 4)
  ret x86_fp80 0xK00000000000000000000
}

define zeroext i8 @pb(i1 zeroext %a, float %b) {
  %ha = call i32 @cqrt_alloc_i1(i1 %a)
  %hb = call i32 @cqrt_alloc_f32(float %b)
  %r1 = call i32 @__cq_q_e_b_10(i32 %ha, float %b)
  %r2 = call i32 @__cq_q_e_b_01(i1 %a, i32 %hb)
  call void @__cq_q_e_b_10_unc(i32 %r1, i32 %ha, float %b)
  call void @__cq_q_e_b_01_unc(i32 %r2, i1 %a, i32 %hb)
  call void @cqrt_free(i32 %r1)
  call void @cqrt_free(i32 %r2)
  ret i8 0
}

define i64 @pw(i64 %x, i32 %u) {
  %hx = call i32 @cqrt_alloc_i64(i64 %x)
  %c = alloca [2 x i32]
  %r1 = call i32 @__cq_q_e_w_100(i32 %hx, ptr %c, i32 %u)
  call void @__cq_q_e_w_100_unc(i32 %r1, i32 %hx, ptr %c, i32 %u)
  call void @cqrt_free(i32 %r1)
  ret i64 0
}

define half @ph(float %a, i32 %n) {
  %t = fptrunc float %a to half
  %ht = call i32 @cqrt_alloc_f16(half %t)
  %hn = call i32 @cqrt_alloc_i32(i32 %n)
  %c = alloca [2 x i32]
  %ca = ptrtoint ptr %c to i64
  %hc = call i32 @cqrt_alloc_i64(i64 %ca)
  %r1 = call i32 @__cq_q_e_h_111_t(i32 %ht, i32 %hc, i32 %hn, i32 4)
  call void @__cq_q_e_h_111_t_unc(i32 %r1, i32 %ht, i32 %hc, i32 %hn, i32 4)
  ret half 0.0
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i16(i16)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare i32 @cqrt_alloc_f16(half)
declare i32 @cqrt_alloc_f32(float)
declare i32 @cqrt_alloc_f64(double)
declare i32 @cqrt_alloc_f80(x86_fp80)
declare void @cqrt_free(i32)
declare i32 @__cq_q_e_i_10(i32, i32)
declare void @__cq_q_e_i_10_unc(i32, i32, i32)
declare i32 @__cq_q_e_i_01(i32, i32)
declare void @__cq_q_e_i_01_unc(i32, i32, i32)
declare i32 @__cq_q_e_i_11_t_ctl(i32, i32, i32, i32)
declare void @__cq_q_e_i_11_t_ctl_unc(i32, i32, i32, i32, i32)
declare i32 @__cq_q_e_d_111_t(i32, i32, i32, i32)
declare void @__cq_q_e_d_111_t_unc(i32, i32, i32, i32, i32)
declare i32 @__cq_q_e_d_100(i32, i8, i64)
declare void @__cq_q_e_d_100_unc(i32, i32, i8, i64)
declare i32 @__cq_q_e_l_11_t(i32, i32, i32)
declare void @__cq_q_e_l_11_t_unc(i32, i32, i32, i32)
declare i32 @__cq_q_e_b_10(i32, float)
declare void @__cq_q_e_b_10_unc(i32, i32, float)
declare i32 @__cq_q_e_b_01(i1, i32)
declare void @__cq_q_e_b_01_unc(i32, i1, i32)
declare i32 @__cq_q_e_w_100(i32, ptr, i32)
declare void @__cq_q_e_w_100_unc(i32, i32, ptr, i32)
declare i32 @__cq_q_e_h_111_t(i32, i32, i32, i32)
declare void @__cq_q_e_h_111_t_unc(i32, i32, i32, i32, i32)
"""

STANDIN_NCLONES = {"pi": 3, "pd": 2, "pl": 1, "pb": 2, "pw": 1, "ph": 1}


def standin_reference(name, args):
    """cq_standin.h restated in Python, over (C type, bits) pairs: a third, independent reading."""
    P, h = 0x100000001b3, 0xcbf29ce484222325
    for b in name.encode():
        h = ((h ^ b) * P) & (2**64 - 1)
    for bits, v in args:
        for w in range((bits + 63) // 64):
            h = ((h ^ ((v >> (64 * w)) & (2**64 - 1))) * P) & (2**64 - 1)
    return h


class StandIn(unittest.TestCase):
    """cq-rft: the evaluator's declared clone stand-in gives the C oracle's value for the same callee and
    arguments (CR §6: one deterministic stand-in on both sides), its twin leaves 0 (a table twin frees the rail, §1.4), and both sides
    agree with cq_standin.h restated in Python."""

    @classmethod
    def setUpClass(cls):
        os.environ["CQ_ROOTS_EXTRA"] = ",".join(set(re.findall(r"\b(e_\w+)\(", STANDIN_C)))  # these tests' rule 27 library
        cls.addClassCleanup(os.environ.pop, "CQ_ROOTS_EXTRA", None)
        from cqcheck import oracle
        cls.oracle = oracle
        cls.tmp = Path(tempfile.mkdtemp(prefix="cq-standin."))
        c = cls.tmp / "standin.c"
        c.write_text(STANDIN_C)
        cls.o1 = cls.tmp / "standin.O1.ll"
        subprocess.run([str(LLVM / "clang"), "-target", "x86_64-apple-macosx16.0.0", "-O1", "-S", "-emit-llvm",
                        str(c), "-o", str(cls.o1)], check=True)
        cls.lowered = cls.tmp / "standin.lowered.ll"
        cls.lowered.write_text(STANDIN_LL)
        cls.spec = DriverSpec("standin", [p.strip() + ";" for p in STANDIN_PROTOS.split(";")], "",
                              [{"fn": fn, "args": [{"ctype": t, "quantum": False} for t in ts]}
                               for fn, ts in STANDIN_CALLS])

    def c_values(self):
        samples = [{"call": ci, "args": ["0x%x" % run.encode_arg(t, v)[1] for t, v in zip(STANDIN_CALLS[ci][1], a)]}
                   for ci, a in STANDIN_SAMPLES]
        out = []
        for r in self.oracle.run_samples(self.o1, self.spec, samples):
            self.assertFalse(r.failed, (r.sample, r.reason, r.notes))
            out.append(int(next(e["v"] for e in r.events if e["ev"] == "ret"), 16))
        return out

    def evaluator_values(self):
        prog = run.build(self.lowered, self.spec, (), RT, FAM, self.o1)
        out = []
        for ci, a in STANDIN_SAMPLES:
            ev = run_prog(prog, self.spec, {"call": ci, "args": list(a)})
            viol = [e for e in ev if e["ev"] == "violation"]
            self.assertEqual(viol, [], (ci, a))
            vals = [int(e["v"], 16) for e in ev if e["ev"] == "tmpl" and e["sym"].startswith("__cq_q_")]
            self.assertEqual(len(vals), STANDIN_NCLONES[STANDIN_CALLS[ci][0]], (ci, a, ev))
            self.assertEqual(len(set(vals)), 1, f"clones of one callee disagree: {ci} {a} {vals}")
            uncs = [e for e in ev if e["ev"] == "unc" and e["sym"].startswith("__cq_q_")]
            self.assertEqual(len(uncs), len(vals))
            self.assertTrue(all(int(e["residue"], 16) == 0 for e in uncs), uncs)
            out.append(vals[0])
        return out

    def test_both_sides_identical(self):
        c, e = self.c_values(), self.evaluator_values()
        self.assertEqual([hex(v) for v in e], [hex(v) for v in c])
        # e_i(5, 7) by the Python restatement: name bytes, then two 32-bit words, low 32 bits
        self.assertEqual(c[0], standin_reference("e_i", [(32, 5), (32, 7)]) & 0xFFFFFFFF)
        # e_l(1.25L, -2): the x87 pattern of 1.25 is two words; result low 80 bits of a 64-bit h
        f80 = (0x3FFF << 64) | 0xA000000000000000
        self.assertEqual(c[6], standin_reference("e_l", [(80, f80), (16, (-2) & 0xFFFF)]))
        # the pointer argument of e_w is never mixed
        self.assertEqual(c[10], standin_reference("e_w", [(64, 2**64 - 1), (32, 7)]))

    def test_stubgen_leaves_unknown_callees_undefined(self):
        text = STANDIN_LL + "declare i32 @__cq_q_absent_1(i32, i32)\n"
        out, names = stubgen.generate([text], [self.o1.read_text()])
        self.assertIn("__cq_q_e_i_11_t_ctl_unc", names)
        self.assertNotIn("__cq_q_absent_1", names)  # no C declaration: left to the link
        self.assertIn('c"e_w|i64|i64,ptr,i32\\00"', out)

    def test_malformed_clone_is_a_violation(self):
        # a K argument missing: the evaluator rejects the call rather than guessing
        bad = STANDIN_LL.replace("@__cq_q_e_l_11_t(i32 %ha, i32 %hb, i32 4)", "@__cq_q_e_l_11_t(i32 %ha, i32 %hb)") \
                        .replace("declare i32 @__cq_q_e_l_11_t(i32, i32, i32)", "declare i32 @__cq_q_e_l_11_t(i32, i32)")
        ll = self.tmp / "standin_bad.ll"
        ll.write_text(bad)
        r = run.run_sample(ll, self.spec, {"call": 2, "args": [1.25, -2]}, "ours", rt_sources=RT,
                           extra_sources=FAM, c_module=self.o1)
        self.assertIn("malformed_call", [v["what"] for v in r.violations])


class Totalize(unittest.TestCase):
    """cq-ltoq: the lowered module's classical div/rem, shifts, fp -> int, cttz and maxnum compute the
    CR §2 table (the C oracle's rows), not x86's trap or its own answer."""
    CALLS = [  # fn, C prototype, ctypes, args, expected ret (hex, at the return's C width)
        ("t_udiv", "unsigned t_udiv(unsigned,unsigned)", ["unsigned", "unsigned"], [7, 0], 0xffffffff),
        ("t_urem", "unsigned t_urem(unsigned,unsigned)", ["unsigned", "unsigned"], [7, 0], 7),
        ("t_urem", "unsigned t_urem(unsigned,unsigned)", ["unsigned", "unsigned"], [7, 3], 1),
        ("t_sdiv", "int t_sdiv(int,int)", ["int", "int"], [5, 0], 0xffffffff),
        ("t_sdiv", "int t_sdiv(int,int)", ["int", "int"], [-5, 0], 1),
        ("t_sdiv", "int t_sdiv(int,int)", ["int", "int"], [-2 ** 31, -1], 0x80000000),
        ("t_srem", "int t_srem(int,int)", ["int", "int"], [-2 ** 31, -1], 0),
        ("t_srem", "int t_srem(int,int)", ["int", "int"], [-9, 0], 0xfffffff7),
        ("t_shl", "int t_shl(int,int)", ["int", "int"], [3, 33], 6),
        ("t_ashr", "long t_ashr(long,long)", ["long", "long"], [-256, 68], 0xfffffffffffffff0),
        ("t_fptosi", "int t_fptosi(double)", ["double"], ["nan"], 0x80000000),
        ("t_fptoui", "unsigned long t_fptoui(double)", ["double"], ["nan"], 0x8000000000000000),
        ("t_fptoui", "unsigned long t_fptoui(double)", ["double"], [1.5e19], 15000000000000000000),
        ("t_fptoui80", "unsigned t_fptoui80(long double)", ["long double"], [-1.0], 0xffffffff),
        ("t_cttz", "int t_cttz(int)", ["int"], [0], 32),
        ("t_maxnum", "double t_maxnum(double,double)", ["double", "double"], ["nan", 2.0], 0x4000000000000000),
    ]

    def test_rows(self):
        protos, calls, idx = [], [], {}
        for fn, proto, ctypes, _, _ in self.CALLS:
            if fn not in idx:
                idx[fn] = len(calls)
                protos.append(proto)
                calls.append({"fn": fn, "args": [{"ctype": c, "quantum": False} for c in ctypes]})
        spec = DriverSpec(example="chk-core", protos=protos, setup="", calls=calls)
        samples = [{"call": idx[fn], "args": args} for fn, _, _, args, _ in self.CALLS]
        rs = run.run_samples(HERE / "totalize.ll", spec, samples, "ours", rt_sources=RT, extra_sources=FAM)
        for (fn, _, _, args, want), r in zip(self.CALLS, rs):
            self.assertEqual(r.violations, [], (fn, args))
            self.assertEqual(int(r.outputs["ret"][0]["v"]["v"], 16), want, (fn, args))

    def test_safe_constants_stay(self):
        text = "define i32 @f(i32 %a) {\n  %r = udiv i32 %a, 3\n  %s = shl nuw i32 %r, 31\n  %t = sdiv i32 %s, -1\n" \
               "  ret i32 %t\n}\n"
        out = run.totalize_module(text)
        self.assertIn("%r = udiv i32 %a, 3", out)
        self.assertIn("%s = shl nuw i32 %r, 31", out)
        self.assertIn("%t = call i32 @__cqe_tot.sdiv.i32(i32 %s, i32 -1)", out)

    def test_vector_is_unimplemented(self):
        text = "define <2 x i32> @f(<2 x i32> %a, <2 x i32> %b) {\n  %r = udiv <2 x i32> %a, %b\n  ret <2 x i32> %r\n}\n"
        with self.assertRaises(Exception):
            run.totalize_module(text)


class DefaultEnv(unittest.TestCase):
    """cq-6ady (owner ruling on cq-0r1i): in a lowered module that touches the fp environment, a plain
    fp operation rounds to nearest and raises no flag; a constrained one sees the live mode."""

    def test_plain_and_constrained(self):
        protos = ["double d_up(double,double)", "int d_flags(double,double)", "double d_constrained(double,double)"]
        calls = [{"fn": f, "args": [{"ctype": "double", "quantum": False}] * 2}
                 for f in ("d_up", "d_flags", "d_constrained")]
        spec = DriverSpec(example="chk-core", protos=protos, setup="", calls=calls)
        tiny = "0x3c30000000000000"  # 2^-60: 1 + tiny is inexact
        samples = [{"call": 0, "args": [1.0, tiny]}, {"call": 1, "args": [1.0, 3.0]},
                   {"call": 2, "args": [1.0, tiny]}]
        rs = run.run_samples(HERE / "default_env.ll", spec, samples, "ours", rt_sources=RT, extra_sources=FAM)
        for r in rs:
            self.assertEqual(r.violations, [])
        ret = [int(r.outputs["ret"][0]["v"]["v"], 16) for r in rs]
        self.assertEqual(ret[0], 0x3ff0000000000000)   # nearest, not upward
        self.assertEqual(ret[1], 0)                    # no INEXACT from the plain fdiv
        self.assertEqual(ret[2], 0x3ff0000000000001)   # the constrained fadd rounds upward

    def test_untouched_module_is_left_alone(self):
        text = "define double @f(double %a) {\n  %r = fadd double %a, 1.0\n  ret double %r\n}\n"
        self.assertFalse(run.touches_fenv(text))
        out = run.default_env_module(run.totalize_module(text + "declare i32 @fesetround(i32)\n"))
        self.assertIn("call void @__cqe_fpdfl_enter()\n  %r = fadd double %a, 1.0\n  call void @__cqe_fpdfl_leave()",
                      out)


class HandleValues(unittest.TestCase):
    """cq-06bi (CQ_spec f684858, CR §1.1, BACKEND_ABI §1, §1.14): handles are classical values the
    program compares, selects and stores; handle 0 is never allocated and means "no rail"; the rule 27
    clone registry."""
    ARGS = ("int v(int,double)", "v", ["int", "double"])

    def test_handles_compare_select_store(self):
        for x0 in (4, 5):
            ev = trace_of("handle_values.ll", *self.ARGS, [x0, 0.5])
            self.assertEqual([e for e in ev if e["ev"] == "violation"], [])
            self.assertNotIn(0, [e["h"] for e in ev if e["ev"] == "alloc"])
            self.assertEqual(len([e for e in ev if e["ev"] == "free"]), 2 if x0 % 2 else 1)
            self.assertEqual([e for e in ev if e["ev"] == "ret"][0]["v"], hex(8 + x0))


class HandleReturn(unittest.TestCase):
    """cq-n6a0: an entry whose lowered return is a rail handle (CR §1.1) reports the rail's value as its
    ret, not the handle number; a classical return is untouched."""

    def test_ret_is_the_rail_value(self):
        protos = ["int hret(int,double,int)", "int cret(int,double,int)"]
        calls = [{"fn": f, "args": [{"ctype": "int", "quantum": True}, {"ctype": "double", "quantum": False},
                                    {"ctype": "int", "quantum": False}]} for f in ("hret", "cret")]
        spec = DriverSpec(example="chk-core", protos=protos, setup="", calls=calls)
        samples = [{"call": 0, "args": [40, 0.5, 2]}, {"call": 0, "args": [7, 0.5, 100]},
                   {"call": 1, "args": [40, 0.5, 2]}]
        rs = run.run_samples(HERE / "handle_ret.ll", spec, samples, "ours", rt_sources=RT, extra_sources=FAM)
        for r in rs:
            self.assertEqual(r.violations, [])
        self.assertEqual([int(r.outputs["ret"][0]["v"]["v"], 16) for r in rs], [42, 107, 42])
        self.assertEqual(rs[0].outputs["ret"][0]["v"]["w"], "i32")

    def test_static_analysis(self):
        text = subprocess.run([str(LLVM / "llvm-link"), "-S", str(HERE / "handle_ret.ll"), "-o", "-"],
                              capture_output=True, text=True, check=True).stdout
        self.assertEqual(run.handle_returning_fns(text), ["hret"])
        if (SPEC / "examples" / "161_opaque_callee").is_dir():
            ll = SPEC / "examples" / "161_opaque_callee" / "opaque_callee.lowered.ll"
            text = subprocess.run([str(LLVM / "llvm-link"), "-S", str(ll), "-o", "-"], capture_output=True,
                                  text=True, check=True).stdout
            self.assertEqual(run.handle_returning_fns(text), ["opaque_callee"])

    def test_dead_handle_is_a_violation(self):
        r = RunResult(side="ours", sample={}, outputs={"ret": [{"call": 0, "fn": "f", "v": {"w": "i32", "v": "0x5"}}]},
                      measured=[], rotations=[], kept=[{"h": 4, "w": "i32", "v": "0x1", "role": "garbage"}],
                      clean=[], violations=[])
        self.assertEqual([v["what"] for v in run.resolve_handle_rets(r, ["f"]).violations], ["ret_handle"])


class ExitRoles(unittest.TestCase):
    """cq-tt2j: the exit roles CR §6 item 1's leak rule reads (rt/core.c exit_role)."""

    def test_roles(self):
        spec = DriverSpec(example="chk-core", protos=["int lk(int,double,double,int)"], setup="",
                          calls=[{"fn": "lk", "args": [{"ctype": "int", "quantum": True},
                                                       {"ctype": "double", "quantum": False},
                                                       {"ctype": "double", "quantum": True},
                                                       {"ctype": "int", "quantum": False}]}])
        rs = run.run_samples(HERE / "exit_roles.ll", spec, [{"call": 0, "args": [3, 0.5, 2.0, 7]}], "ours")
        r = rs[0]
        self.assertEqual(r.violations, [])
        live = {k["h"]: (k["role"], k.get("known")) for k in kept_mod.expand(r.kept)}   # one entry per rail
        # handles in creation order: x y a b e e2 k h cnd md (z measured)
        self.assertEqual(live[1][0], "frozen")
        self.assertEqual(live[2][0], "frozen")
        self.assertEqual(live[3], ("garbage", False))  # a handle in memory is nothing (flat memory)
        self.assertEqual(live[4], ("garbage", False))
        self.assertEqual(live[5][0], "fenv_flags")
        self.assertEqual(live[6][0], "fenv_flags")
        self.assertEqual(live[7], ("seed", True))
        self.assertEqual(live[8], ("garbage", False))
        self.assertEqual(live[9], ("garbage", False))
        self.assertEqual(live[10][0], "fenv_mode")

    def test_frozen_image(self):
        # cq-qhow: CR rule 19, a rule-6 image of a rotated register is FROZEN at exit, across the call
        spec = DriverSpec(example="chk-core", protos=["int use(int,double,int)"], setup="",
                          calls=[{"fn": "use", "args": [{"ctype": "int", "quantum": True},
                                                        {"ctype": "double", "quantum": False},
                                                        {"ctype": "int", "quantum": False}]}])
        r = run.run_samples(HERE / "frozen_image.ll", spec, [{"call": 0, "args": [3, 0.5, 4]}], "ours")[0]
        self.assertEqual(r.violations, [])
        live = {k["h"]: k["role"] for k in kept_mod.expand(r.kept)}
        # handles in creation order: x g r t s (x, t freed)
        self.assertEqual(live, {2: "garbage", 3: "frozen", 5: "garbage"})

    def test_rule6_image(self):
        # cq-o9mx (rulings 2 A): a rule-6 clean's operands are rule6_image; an ordinary result, the operand of an
        # un-copied temp and a bus load copy stay garbage (rule6_image.ll names them)
        spec = DriverSpec(example="chk-core", protos=["int img(int,int)"], setup="",
                          calls=[{"fn": "img", "args": [{"ctype": "int", "quantum": True},
                                                        {"ctype": "int", "quantum": False}]}])
        r = run.run_samples(HERE / "rule6_image.ll", spec, [{"call": 0, "args": [3, 4]}], "ours")[0]
        self.assertEqual(r.violations, [])
        roles = sorted((k["v"], k["role"]) for k in kept_mod.expand(r.kept))
        vals = {"s": 3 + 1 + 3 + 4, "vv": 4, "g": 22, "q": 5, "l": 3, "s2": 3 + 8}
        self.assertEqual({v: role for v, role in roles if role != "frozen"},
                         {hex(vals["s"]): "rule6_image", hex(vals["vv"]): "rule6_image", hex(vals["g"]): "garbage",
                          hex(vals["q"]): "garbage", hex(vals["l"]): "garbage", hex(vals["s2"]): "rule6_image"})

    def test_kept_copy_of_a_table_result(self):
        # rule 19: the copy of a candidate's result is kept; an ordinary copy is not
        text = ("define void @f(ptr %fp, i32 %x) {\n  %r = call i32 %fp(i32 %x)\n  %c = call i32 @cqrt_alloc_i32(i32 0)\n"
                "  call void @cqrt_copy_i32(i32 %r, i32 %c)\n  call void @cqrt_copy_i32(i32 %x, i32 %c)\n  ret void\n}\n")
        out = run.kept_copies_module(text)
        self.assertEqual(out.count("call void @cqe__set_store_kept(i32 %c)"), 1)
        self.assertLess(out.index("cqrt_copy_i32(i32 %r"), out.index("set_store_kept(i32 %c)"))
        self.assertLess(out.index("set_store_kept(i32 %c)"), out.index("cqrt_copy_i32(i32 %x"))

    def test_kept_result_no_twin(self):
        # rule 18: a callee with no twin leaves its rail result with the caller; one with a twin stays a leak if not zeroed
        text = ("define i32 @w(i32 %x) {\n  %r = call i32 @cq_template_not_i32(i32 %x)\n  ret i32 %r\n}\n"
                "define i32 @t(i32 %x) {\n  %r = call i32 @cq_template_not_i32(i32 %x)\n  ret i32 %r\n}\n"
                "define void @t_unc(i32 %r, i32 %x) {\n  ret void\n}\n"
                "define void @f(i32 %x) {\n  %a = call i32 @w(i32 %x)\n  %b = call i32 @t(i32 %x)\n  ret void\n}\n")
        out = run.kept_results_module(text, run.handle_returning_fns(text))
        self.assertEqual(out.count("call void @cqe__set_store_kept(i32 %a)"), 1)
        self.assertNotIn("set_store_kept(i32 %b)", out)
        self.assertNotIn("set_store_kept(i32 %r)", out)

    def test_ctl_measure_named(self):
        text = ("define i32 @p_t_ctl(i32 %c, i32 %v) {\n  %m = call i32 @cqrt_measure_i32(i32 %v)\n  ret i32 %m\n}\n"
                "define i32 @p_t(i32 %v) {\n  %m = call i32 @cqrt_measure_i32(i32 %v)\n  ret i32 %m\n}\n")
        out = run.ctl_measures_module(text)
        self.assertEqual(out.count("call void @cqd_out_ctl_measure(i32 %v)"), 1)
        self.assertLess(out.index("cqd_out_ctl_measure"), out.index("define i32 @p_t("))


class HostClone(unittest.TestCase):
    """cq-aou6: a declared clone whose fn the host defines (libm, also through an llvm.<fn>.f64 intrinsic
    of the C module) computes the host's fn, as the C oracle links it; its twin XORs it out; K only on a table clone."""

    def test_libm_values(self):
        spec = DriverSpec(example="chk-core", protos=["double hx(double,double)"], setup="",
                          calls=[{"fn": "hx", "args": [{"ctype": "double", "quantum": True},
                                                       {"ctype": "double", "quantum": False}]}])
        xs = [(0.5, 2.0), (-1.25, 3.0), (2.0, -0.5)]
        os.environ["CQE_COMPACT"] = "0"     # the diagnostics trace: every free event, with its value
        try:
            rs = run.run_samples(HERE / "host_clone.ll", spec, [{"call": 0, "args": list(a)} for a in xs], "ours",
                                 rt_sources=RT, extra_sources=FAM, c_module=HERE / "host_clone.O1.ll")
        finally:
            os.environ.pop("CQE_COMPACT", None)
        for (x, y), r in zip(xs, rs):
            self.assertEqual(r.violations, [], (x, y))
            self.assertEqual([int(m["v"], 16) for m in r.measured],
                             [run._fp_bits(math.exp(x), 64), run._fp_bits(math.atan2(x, y), 64)])
            self.assertEqual([c["v"] for c in r.clean if "freed" not in c], ["0x0"])   # pow's rail, XORed out by its twin
            self.assertEqual(freed(r), 1)

    def test_stubgen_intrinsic_signature_and_pointer(self):
        text = (HERE / "host_clone.ll").read_text()
        out, _ = stubgen.generate([text], [(HERE / "host_clone.O1.ll").read_text()])
        self.assertIn("declare double @exp(double)", out)
        self.assertIn("call void @cqe_standin_host(", out)
        bad = text.replace("@__cq_q_exp_1(i32", "@__cq_q_strlen_1(i32")
        with self.assertRaises(stubgen.StubError):
            stubgen.generate([bad], ["declare i64 @strlen(ptr)"])


class HostOutput(unittest.TestCase):
    """cq-e4jk: outputs["stdout"] is the process's output followed by the tape's end-of-shot text;
    outputs["effects"] the {"ev":"effect"} lines in the C program's order (run._effects_in_order);
    outputs["tape"] the shot's event sequence; outputs["deviation"] rule 16's stated deviation."""

    def test_tape_shot_and_effect_events(self):
        fmt = {"seq": 0, "kind": "fmt", "t": 1, "pred": 1, "class": "deferred", "performed": True, "fmt": "big %d\n",
               "fields": [], "text": "big 5\n"}
        rm = {"seq": 1, "kind": "effect", "t": 1, "pred": 1, "class": "deferred", "performed": True, "name": "remove",
              "fields": [{"k": "lit", "w": "i64", "v": "0x1000", "cap": "/tmp/cq_x"}]}
        off = {"seq": 2, "kind": "effect", "t": 1, "pred": 0, "class": "deferred", "performed": False, "name": "raise",
               "fields": [{"k": "lit", "w": "i32", "v": "0x6"}]}
        rais = {"seq": 3, "kind": "effect", "t": 1, "pred": 1, "class": "input", "performed": True, "name": "fgets",
                "fields": [{"k": "rail", "h": 9, "w": "i32", "v": "0x1e"}], "r": {"h": 12, "w": "i64", "v": "0x0"}}
        shot = {"ev": "tape", "op": "shot", "aborted": False, "abort_seq": -1, "stdout": "big 5\n\u00c3\u00a9",
                "deviation": True, "events": [fmt, rm, off, rais, {"seq": 4, "kind": "abort", "f": 3, "fv": "0x0"}]}
        direct = {"ev": "effect", "seq": -1, "kind": "effect", "class": "host", "pred": 1, "performed": True, "when": "call",
                  "name": "unlink", "fields": [{"k": "lit", "w": "i64", "v": "0x2000", "cap": "/a"}]}
        ev = [dict(rais, ev="effect", when="call"), direct, dict(fmt, ev="effect", when="end"),
              dict(rm, ev="effect", when="end"), shot, {"ev": "exit", "live": []}]
        r = run._result("ours", {}, ev, "pre\n", 0, [])
        self.assertEqual(r.outputs["stdout"], "pre\nbig 5\n\u00e9")
        # the sequence order: the deferred remove (seq 1) before the input performed at its call (seq 3); the
        # direct call behind what its call followed; the format entry in stdout only
        self.assertEqual(r.outputs["effects"], [
            {"name": "remove", "args": [{"w": "i64", "v": "0x1000", "cap": "/tmp/cq_x"}]},
            {"name": "fgets", "args": [{"w": "i32", "v": "0x1e"}]},
            {"name": "unlink", "args": [{"w": "i64", "v": "0x2000", "cap": "/a"}]}])
        self.assertTrue(r.outputs["deviation"])
        self.assertEqual([e.get("name", e.get("fmt", e["kind"])) for e in r.outputs["tape"]],
                         ["big %d\n", "remove", "raise", "fgets", "abort"])
        self.assertEqual(r.outputs["tape"][3]["r"], {"w": "i64", "v": "0x0"})
        self.assertNotIn("h", r.outputs["tape"][3]["fields"][0])
        r = run._result("ours", {}, [{"ev": "exit", "live": []}], "", 0, [])
        self.assertEqual((r.outputs["stdout"], r.outputs["effects"]), ("", []))

    def test_memory_and_table_lines(self):
        ev = [{"ev": "out_mem", "name": "x", "w": "i32", "v": "0x5"},
              {"ev": "out_mem", "table": "object", "name": "x", "addr": "0x1000", "size": 4},
              {"ev": "out_mem", "table": "region", "name": "heap", "lo": "0x1", "hi": "0x2"}, {"ev": "exit", "live": []}]
        r = run._result("ours", {}, ev, "", 0, [])
        self.assertEqual(r.outputs["mem"], [{"name": "x", "w": "i32", "v": "0x5"}])
        self.assertEqual(r.outputs["objects"], [{"name": "x", "addr": "0x1000", "size": 4}])
        self.assertEqual(r.outputs["regions"], [{"name": "heap", "lo": "0x1", "hi": "0x2"}])

    def test_direct_stream_call_is_the_stand_in(self):
        # rulings Q8: every direct host call goes to a wrapper; what the driver line defines stays
        text = ("declare i32 @putchar(i32)\ndeclare i32 @ext_fill(i32)\ndeclare i32 @printf(ptr, ...)\n"
                "define i32 @g() {\n  %r = call i32 @putchar(i32 65)\n  %s = call i32 @ext_fill(i32 1)\n  ret i32 %r\n}\n")
        out = run.host_effects_module(text, ["ext_fill"])
        self.assertIn("call i32 @cqd_fx_putchar(i32 65)", out)
        self.assertIn("define i32 @cqd_fx_putchar(i32 %a0)", out)
        self.assertIn("call i32 @ext_fill(i32 1)", out)
        self.assertIn("declare i32 @printf(ptr, ...)", out)

    def test_host_effects_module_renames_declared_only(self):
        text = ("declare i32 @remove(ptr)\ndefine i32 @g() {\n  %r = call i32 @remove(ptr @.cq.effect.remove)\n"
                "  %s = call i32 @remove_cond(i32 1)\n  %t = call i32 @raise(i32 6)\n  ret i32 %r\n}\n"
                "define i32 @raise(i32 %s) {\n  ret i32 0\n}\n")
        out = run.host_effects_module(text)
        self.assertIn("declare i32 @__cqe_fx_remove(ptr)", out)
        self.assertIn("call i32 @__cqe_fx_remove(ptr @.cq.effect.remove)", out)
        self.assertIn("@remove_cond(i32 1)", out)
        self.assertIn("call i32 @raise(i32 6)", out)   # defined by the module: its own

    def test_direct_effect_and_stdout_end_to_end(self):
        r = run.run_sample(HERE / "host_fx.ll", spec1("int fx(int)", "fx", ["int"]), {"call": 0, "args": [5]},
                           "ours", rt_sources=RT + [REPO / "checker" / "rt" / "host_fx.c"], extra_sources=FAM)
        self.assertEqual(r.violations, [])
        self.assertEqual([(e["name"], e["args"][0]["cap"]) for e in r.outputs["effects"]], [("remove", "/nonexistent/cq_e4jk\n")])
        self.assertEqual(r.outputs["stdout"], "v=5\n")


RT_ALL = sorted((REPO / "checker" / "rt").glob("*.c"))


def build_harness(c_file, exe):
    """A C test harness linked with every evaluator source (the core, the dispatcher, all families)."""
    subprocess.run([str(LLVM / "clang"), "-std=c17", "-O1", "-w", "-target", "x86_64-apple-macosx", "-I",
                    str(REPO / "checker" / "rt"), str(c_file), *map(str, RT_ALL), "-lm", "-o", str(exe)], check=True)


def _round_mag(v, p, mode, neg):
    """|v| (a positive int) rounded to p significant bits: mode 'ne', 'up', 'down', 'zero' (IEEE, on the
    signed value -v when neg)."""
    s = v.bit_length() - p
    if s <= 0:
        return v
    q, r = v >> s, v & ((1 << s) - 1)
    half = 1 << (s - 1)
    inc = {"ne": r > half or (r == half and q & 1), "zero": False,
           "up": r != 0 and not neg, "down": r != 0 and neg}[mode]
    return (q + bool(inc)) << s


def _f80_of(mag, neg):
    if mag == 0:
        return (0x8000 if neg else 0), 0
    L = mag.bit_length()
    return (0x8000 if neg else 0) | (L - 1 + 16383), (mag >> (L - 64) if L >= 64 else mag << (64 - L))


class WideIntToF80(unittest.TestCase):
    """cq-off6, cq-cqcj: sitofp/uitofp iN -> f80, N > 128. LLVM 19 at -O1 (ExpandLargeFpConvert, read
    from llc -print-after=expand-large-fp-convert) rounds |v| to 113 bits to nearest even in integer
    code, then calls __trunctfxf2: two roundings, adopted (CR §2, the neighbour a double rounding lands
    on); the second is the library's, IEEE in the template's mode. uitofp with the top bit set comes
    back negative natively (a miscompile); CR §2 (cq-cqcj) overrides that value: the non-negative value
    rounded once at f80's 64-bit significand, in the mode for _rm (cq-6d9d, cq-xyqx)."""
    MODES = {"ne": 0x000, "down": 0x400, "up": 0x800, "zero": 0xC00}

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.exe = Path(cls.tmp.name) / "wide_itofp"
        build_harness(HERE / "wide_itofp.c", cls.exe)
        rnd = random.Random(0x0FF6)
        cls.cases = [(200, 2**198 + 2**135 + 2**134 - 1),  # the review repro (chk-h3 big3.c)
                     (129, 0x1ad40d14ea5bac7990000000000000080)]  # top-bit uitofp (chkfp-n1 probe3)
        for _ in range(3000):
            N = rnd.choice((129, 192, 200, 256))
            L = rnd.randint(max(1, N - 80), N)
            v = (1 << (L - 1)) | rnd.getrandbits(L - 1)
            for lo in (L - 65, L - 114):  # the f80 and fp128 round positions: ties and near-ties
                if lo > 4 and rnd.random() < 0.6:
                    w = rnd.randint(2, min(lo, 12))
                    pat = rnd.choice((1 << (w - 1), (1 << (w - 1)) - 1, (1 << w) - 1, 0, (1 << (w - 1)) + 1))
                    v = (v & ~(((1 << w) - 1) << (lo - w + 1))) | (pat << (lo - w + 1))
            cls.cases.append((N, v))
        for _ in range(400):  # the f80 round bits [L-113, L-65] as 0111..1 or 1000..0: a near-tie at 113 bits
            N = rnd.choice((129, 192, 200, 256))
            L = rnd.randint(120, N)
            v = (1 << (L - 1)) | rnd.getrandbits(L - 1)
            win = rnd.choice(((1 << 48) - 1, 1 << 48))
            v = (v & ~(((1 << 49) - 1) << (L - 113))) | (win << (L - 113))
            cls.cases.append((N, v))

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def run_h(self, mode=None):
        p = subprocess.run([str(self.exe)] + ([str(self.MODES[mode])] if mode else []),
                           input="".join(f"{N} {v:x}\n" for N, v in self.cases), capture_output=True, text=True,
                           env=dict(os.environ, CQE_TRACE="/dev/null"), check=True)
        rows = [l.split() for l in p.stdout.splitlines()]
        self.assertEqual(len(rows), 2 * len(self.cases))
        return rows

    def model(self, N, v, sgn, mode):
        neg = sgn and v >> (N - 1) & 1
        mag = (1 << N) - v if neg else v
        if not sgn and v >> (N - 1) & 1:  # CR §2 (cq-cqcj): one rounding, never negative
            return _f80_of(_round_mag(mag, 64, mode, False), False)
        return _f80_of(_round_mag(_round_mag(mag, 113, "ne", neg), 64, mode, neg), neg)

    def test_native_nearest(self):
        rows = self.run_h()
        double = top_double = 0
        for i, (N, v) in enumerate(self.cases):
            for j, sgn in enumerate((0, 1)):
                n_, k, ese, em, nse, nm = rows[2 * i + j]
                ev, nat = (int(ese, 16), int(em, 16)), (int(nse, 16), int(nm, 16))
                neg = sgn and v >> (N - 1) & 1
                single = _f80_of(_round_mag((1 << N) - v if neg else v, 64, "ne", neg), neg)
                if not sgn and v >> (N - 1) & 1:
                    # LLVM 19's uitofp with the top bit set: negative, the double-rounded magnitude
                    # (a miscompile). Not adopted (cq-cqcj): one rounding, non-negative (cq-6d9d).
                    self.assertEqual(nat[0] & 0x8000, 0x8000, (N, hex(v)))
                    self.assertEqual((nat[0] & 0x7FFF, nat[1]),
                                     _f80_of(_round_mag(_round_mag(v, 113, "ne", 0), 64, "ne", 0), 0))
                    self.assertEqual(ev, single, (N, hex(v), "u top"))
                    top_double += ev != (nat[0] & 0x7FFF, nat[1])
                    continue
                self.assertEqual(ev, nat, (N, hex(v), "su"[1 - sgn]))
                self.assertEqual(ev, self.model(N, v, sgn, "ne"))
                double += ev != single
        self.assertEqual(rows[0][2:4], ["40c5", "8000000000000002"])
        self.assertTrue(rows[2][3].endswith("63cd"), rows[2])  # once rounded; LLVM's double gives ...63cc
        self.assertGreater(double, 50)  # the double rounding is exercised, not only agreed on
        self.assertGreaterEqual(top_double, 5)  # top-bit uitofp: single rounding differs from LLVM's double (seeded: 5)

    def test_uitofp_top_bit_is_never_negative(self):
        """cq-cqcj (CR §2 at 744da1b): native gives c07f 8000000000000000 for uitofp i129 2^128;
        CR §2 gives the non-negative value rounded once, in the mode for _rm (cq-6d9d)."""
        for mode in (None, "down", "up", "zero"):
            p = subprocess.run([str(self.exe)] + ([str(self.MODES[mode])] if mode else []),
                               input=f"129 {2**128:x}\n129 {2**129 - 1:x}\n", capture_output=True, text=True,
                               env=dict(os.environ, CQE_TRACE="/dev/null"), check=True)
            u = [l.split()[2:4] for l in p.stdout.splitlines() if l.split()[1] == "u"]
            # 2^129 - 1: rounded once at 64 bits (cq-6d9d), so the mode decides; LLVM's 113-bit
            # nearest-even step would give 2^129 in every mode
            top = ["4080", "8000000000000000"] if mode in (None, "up") else ["407f", "ffffffffffffffff"]
            self.assertEqual(u, [["407f", "8000000000000000"], top], mode)

    def test_rm_second_rounding_in_the_mode(self):
        for mode in ("down", "up", "zero"):
            rows = self.run_h(mode)
            for i, (N, v) in enumerate(self.cases):
                for j, sgn in enumerate((0, 1)):
                    r = rows[2 * i + j]
                    self.assertEqual((int(r[2], 16), int(r[3], 16)), self.model(N, v, sgn, mode),
                                     (N, hex(v), "su"[1 - sgn], mode))


class TmplCall:
    """tmpl_call.c built once: runtime symbols called through the real dispatcher."""
    _tmp = None

    @classmethod
    def call(cls, lines):
        if cls._tmp is None:
            cls._tmp = tempfile.TemporaryDirectory()
            build_harness(HERE / "tmpl_call.c", Path(cls._tmp.name) / "tmpl_call")
        t = Path(cls._tmp.name) / "trace.jsonl"
        p = subprocess.run([str(Path(cls._tmp.name) / "tmpl_call")], input="".join(l + "\n" for l in lines),
                           capture_output=True, text=True, env=dict(os.environ, CQE_TRACE=str(t)))
        bad = [e for e in (json.loads(l) for l in t.read_text().splitlines() if l.strip()) if e["ev"] == "violation"]
        return (p.returncode if not bad else bad), p.stdout.split()


_FMT16 = {"f16": (5, 10), "bf16": (8, 7)}


def _f16_value(fmt, b):
    e, m = _FMT16[fmt]
    E, M, bias = (b >> m) & ((1 << e) - 1), b & ((1 << m) - 1), (1 << (e - 1)) - 1
    v = Fraction(M, 1 << m) * Fraction(2) ** (1 - bias) if E == 0 else (1 + Fraction(M, 1 << m)) * Fraction(2) ** (E - bias)
    return -v if b >> (e + m) else v


def _f16_round(fmt, x, sign_if_zero=0):
    """x (a Fraction) rounded once, to nearest even, to the 16-bit format's bit pattern (overflow: Inf)."""
    e, m = _FMT16[fmt]
    bias = (1 << (e - 1)) - 1
    s = 1 if x < 0 or (x == 0 and sign_if_zero) else 0
    x = abs(x)
    ulp = Fraction(2) ** (1 - bias - m)  # the subnormal quantum
    if x >= Fraction(2) ** (1 - bias):
        k = x.numerator.bit_length() - x.denominator.bit_length() + 1
        while Fraction(2) ** k > x:
            k -= 1
        ulp = Fraction(2) ** (k - m)
    q = x / ulp
    n = q.numerator // q.denominator
    if q - n > Fraction(1, 2) or (q - n == Fraction(1, 2) and n % 2):
        n += 1
    v = n * ulp
    if v == 0:
        return s << (e + m)
    k = v.numerator.bit_length() - v.denominator.bit_length() + 1
    while Fraction(2) ** k > v:
        k -= 1
    if k > bias:
        return (s << (e + m)) | (((1 << e) - 1) << m)
    if k < 1 - bias:
        return (s << (e + m)) | int(v / Fraction(2) ** (1 - bias - m))
    return (s << (e + m)) | ((k + bias) << m) | int((v / Fraction(2) ** k - 1) * (1 << m))


class Fma16(unittest.TestCase):
    """cq-q4cz: fma at f16 and bf16 is one IEEE rounding (CR §2 fma row). LLVM 19 -O1 promotes
    llvm.fma.f16 (clang's __builtin_fmaf16) to fmaf then __truncsfhf2, two roundings (clang 19 -O1 -S,
    measured); llvm.fma is IEEE fusedMultiplyAdd by LangRef and fmaf16 by C, so that double rounding is
    not adopted (CR §2: a value C fixes exactly is never taken from a miscompile)."""

    def test_review_repro(self):
        rc, out = TmplCall.call(["cq_template_fma_bf16 i32|i32,i32,i32 h:bf16:980e h:bf16:7f60 h:bf16:802b"])
        self.assertEqual((rc, out), (0, ["d7f9"]))  # once rounded; via f32 it would be d7f8

    def test_random_against_exact(self):
        rnd = random.Random(0x4C2)
        for fmt in ("f16", "bf16"):
            e, m = _FMT16[fmt]
            def fin():  # a finite operand (no Inf, no NaN)
                while True:
                    b = rnd.getrandbits(16)
                    if (b >> m) & ((1 << e) - 1) != (1 << e) - 1:
                        return b

            cases = [(fin(), fin(), fin()) for _ in range(600)]
            want = []
            for a, b, c in cases:
                va, vb, vc = (_f16_value(fmt, x) for x in (a, b, c))
                r = va * vb + vc
                prod_neg = (a ^ b) >> 15
                zero_sign = prod_neg & (c >> 15)  # exact zero: -0 only if both addends are -0 (RNE)
                want.append(_f16_round(fmt, r, zero_sign))
            rc, out = TmplCall.call([f"cq_template_fma_{fmt} i32|i32,i32,i32 h:{fmt}:{a:x} h:{fmt}:{b:x} h:{fmt}:{c:x}"
                                     for a, b, c in cases])
            self.assertEqual(rc, 0)
            for (a, b, c), w, g in zip(cases, want, out):
                self.assertEqual(int(g, 16), w, (fmt, hex(a), hex(b), hex(c)))



class Bf16Memory(unittest.TestCase):
    """cq-7n88: the bus accepts the bf16 access width (2 cells, a 2-byte fp value, CR §1.3)."""

    def test_bus_bf16(self):
        addr = 0x1000
        rc, out = TmplCall.call(["=cqrt_qram_alloc_i8 i32|i32 l:0",
                                 # an unmapped page: the store makes its cells QUANTUM (§2), the load reads them
                                 f"cqrt_qram_store_bf16_hl void|i32,i64,i32 l:51000000 l:{addr:x} h:bf16:3f80",
                                 f"cqrt_qram_load_bf16_hl i32|i32,i64 l:51000000 l:{addr:x}",
                                 f"cqrt_qram_load_bf16_hl i32|i32,i64 l:51000000 l:{addr + 2:x}"])
        self.assertEqual((rc, out), (0, ["51000000", "void", "3f80", "0"]))


if __name__ == "__main__":
    unittest.main()
