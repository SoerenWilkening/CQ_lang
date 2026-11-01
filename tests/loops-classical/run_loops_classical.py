#!/usr/bin/env python3
"""tests/loops-classical (cq-w1-loops-classical): the module's probes through the real plugin.

For probes/loops.O1.ll (and slots.O1.ll, rule6.O1.ll) it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left; every entry with a loop pushes and pops (the reverse ran);
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
For rule6.O1.ll it also checks the kept rails at trip counts 2 and 3 (cq-b13w, CR rule 6 on carried values), and
for deferred.O1.ll likewise (cq-fx3s, cq-aqbw: the reverse loop deferred after the exit values' readers keeps no
which-path or garbage rail), and for measured_some.O1.ll likewise (cq-8lf8: a computed rail measured on an early
return only is not left as garbage on the loop path).
The owned examples' acceptance is `python3 -m cqcheck run <examples> --oracle both` (the bead).
Outputs go to build/tests/loops-classical/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
PROBE = PROBES / "loops.O1.ll"
# cq-sujx: rule 20 slot cells loaded and stored per trip (58, 60 shapes).
SLOT_PROBE = PROBES / "slots.O1.ll"
SLOT_ENTRIES = ["s_reg", "s_qft", "s_int"]
# Probes cq-lower must stop on with cq::unimplemented carrying this text (nothing emitted).
FATAL = [(PROBES / "slots_fatal_crossgate.O1.ll", "a non-diagonal gate in a classically bounded loop on a rail"),
         # cq-vqid: a record deferred to the reverse loop reads a rail rotated later in the same trip.
         (PROBES / "fatal_undoneread.O1.ll", "a non-diagonal gate in a classically bounded loop on a rail that a "
          "record undone by the reverse loop reads"),
         # cq-pkjc: a quantum arm's classical conjunct (select(i != 0, q[i], false)) the trip does not establish.
         (PROBES / "fatal_armguard.O1.ll", "a block of a classically bounded loop body whose classical guard "
          "(rule 8: the classical factor of its predicate")]
# cq-b13w: CR rule 6 on carried values. Each entry's last parameter is the trip count; the kept rails (role, width)
# at n = 2 and n = 3 must be exactly the straight-line rule 6 multiset below.
RULE6_PROBE = PROBES / "rule6.O1.ll"
RULE6 = {"r_b3": [("frozen", "i32"), ("measured", "i32")],
         "r_c2": [("measured", "i32")],
         "r_sub": [("frozen", "i32"), ("measured", "i32")],
         "r_live": [("frozen", "i32"), ("measured", "i32"), ("measured", "i32")],
         "r_fneg": [("frozen", "f64"), ("measured", "f64")],
         "r_c3": [("frozen", "i32"), ("measured", "i32")]}
# cq-fx3s / cq-aqbw: the reverse loop deferred until after the readers of the loop's exit values (no copy-out).
DEFERRED_PROBE = PROBES / "deferred.O1.ll"
DEFERRED = {"f_arm": [("frozen", "i32"), ("measured", "i32")],
            "f_arm_brk": [("frozen", "i32"), ("measured", "i32")],
            "f_arm_phase": [("frozen", "i32"), ("measured", "i32")],
            "f_oracle": [("measured", "i32")]}
# cq-8lf8: y = 3x + 1 measured when n == 7 only; at n = 2, 3 the loop path keeps no garbage rail.
MEASURED_PROBE = PROBES / "measured_some.O1.ll"
# cq-ot39: a quantum loop invariant LICM hoisted into the guarded preheader (resolved on the loop's exit path).
HOISTED_PROBE = PROBES / "hoisted.O1.ll"
HOISTED = ["fk3", "fk1", "c4"]
# cq-r8-d (185): a guarded deferred reverse placed at the return after later loops (its guard and seed carried
# over joins whose phis are still being filled; SSAUpdater made them poison).
CARRY_PROBE = PROBES / "guard_carry.O1.ll"
CARRY = ["g_carry"]
MEASURED = {"m_r8": [("measured", "i32"), ("kept_entangled", "i32"), ("measured", "i32")],
            "m_r8b": [("measured", "i32"), ("measured", "i32")],
            "m_r8c": [("measured", "i32"), ("kept_entangled", "i32"), ("measured", "i32")]}
# cq-zpe8: measured on one arm and again after the join's loop; §6 only (the kept rails depend on the arm; the
# loop is classical, so no reverse loop).
MEASURED_SEC6 = ["m_join", "m_join2"]
# cq-50qq: m_join2 at c == d == 0 (measured nowhere): x alone is kept (frozen), y is cleaned under the classical flag.
MEASURED_NONE = {"m_join2": [("frozen", "i32")]}
# 176: a trip-local sub-loop (value(x) read by the oracle flag only) reversed inside its parent's trip.
TRIPLOCAL_PROBE = PROBES / "triplocal.O1.ll"
TRIPLOCAL = ["t_grover"]
# 72, 188: QRAM stores in a classically bounded trip (F1b: the reverse loop deferred after the array's later uses).
QRAM_PROBE = PROBES / "qram_trip.O1.ll"
QRAM = ["q_fill", "q_hist"]
ENTRIES = ["p_acc", "p_brk", "p_nest", "p_mod", "p_nb", "p_horner", "p_arm", "p_phase", "p_cjoin", "p_tphase", "p_bwb", "p_g2"]
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def check_probe(a, probe: Path, entries, out: Path) -> int:
    lowered = out / (probe.stem + ".lowered.ll")
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL cq-lower " + probe.name + ": " + r.stderr.strip())
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify " + probe.name + ": " + v.stderr.strip())
        return 1
    text = lowered.read_text()
    failures = 0
    for e in entries:
        b = body(text, e)
        why = []
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        if e not in MEASURED_SEC6 and ("@cqrt_push(" not in b or "@cqrt_pop()" not in b):
            why.append("no push/pop: the reverse loop is missing")
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered", str(lowered),
                            "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
        if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
            why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        print(("FAIL " if why else "ok   ") + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    return failures


def check_kept(probe: Path, lowered: Path, entry: str, want, pick=None) -> str:
    """'' when every sample with trip count 2 or 3 (or every sample `pick` accepts) keeps exactly `want`
    (role, width), else why not."""
    import collections
    import tempfile
    sys.path.insert(0, str(ROOT / "checker"))
    from cqcheck import run, sampling, user
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        lowp = work / f"user_{entry}.lowered.ll"
        lowp.write_text(lowered.read_text())
        spec, exdir = user.build_spec(probe.read_text(), entry, work, user.handle_cell_params(lowp, entry))
        c_module = next(exdir.glob("*.O1.ll"))
        ss = sampling.sample_set(spec, exdir, exempt_baseline=False)
        pick = pick or (lambda args: int(args[-1], 16) in (2, 3))
        chosen = [x for x in ss.samples if pick(x["args"])][:24]
        if not chosen:
            return "no sample selected"
        hist = collections.Counter()
        for r in run.run_samples(lowp, spec, chosen, "ours", 4, c_module=c_module):
            hist[tuple(sorted((k.get("role"), k.get("w")) for k in (r.kept or [])))] += 1
        if set(hist) != {tuple(sorted(want))}:
            return "kept rails " + str(dict(hist)) + ", want " + str(sorted(want))
    return ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append", help="check only these entries of loops.O1.ll")
    ap.add_argument("--group", action="append", choices=["loops", "slots", "rule6", "deferred", "measured", "hoisted", "carry", "fatal", "triplocal", "qram"],
                    help="run only these probe groups (default: all)")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "loops-classical" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0
    want = set(a.group or (["loops"] if a.entry else ["loops", "slots", "rule6", "deferred", "measured", "hoisted", "carry", "fatal", "triplocal", "qram"]))
    groups = []
    if "loops" in want:
        groups.append((PROBE, a.entry or ENTRIES))
    if "slots" in want:
        groups.append((SLOT_PROBE, SLOT_ENTRIES))
    if "rule6" in want:
        groups.append((RULE6_PROBE, list(RULE6)))
    if "deferred" in want:
        groups.append((DEFERRED_PROBE, list(DEFERRED)))
    if "measured" in want:
        groups.append((MEASURED_PROBE, list(MEASURED) + MEASURED_SEC6))
    if "hoisted" in want:
        groups.append((HOISTED_PROBE, HOISTED))
    if "triplocal" in want:
        groups.append((TRIPLOCAL_PROBE, TRIPLOCAL))
    if "qram" in want:
        groups.append((QRAM_PROBE, QRAM))
    for probe, entries in groups:
        failures += check_probe(a, probe, entries, out)
    for group, probe, table in (("rule6", RULE6_PROBE, RULE6), ("deferred", DEFERRED_PROBE, DEFERRED),
                                 ("measured", MEASURED_PROBE, MEASURED)):
        if group not in want:
            continue
        for e, kept in table.items():
            why = check_kept(probe, out / (probe.stem + ".lowered.ll"), e, kept)
            print(("FAIL " if why else "ok   ") + e + " kept" + ("" if not why else ": " + why))
            failures += bool(why)
    if "measured" in want:
        for e, kept in MEASURED_NONE.items():
            why = check_kept(MEASURED_PROBE, out / (MEASURED_PROBE.stem + ".lowered.ll"), e, kept,
                             lambda args: all(int(v, 16) == 0 for v in args))
            print(("FAIL " if why else "ok   ") + e + " kept (measured nowhere)" + ("" if not why else ": " + why))
            failures += bool(why)
    if "fatal" in want:
        for probe, msg in FATAL:
            r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                                str(out / (probe.stem + ".lowered.ll"))], capture_output=True, text=True)
            ok = r.returncode != 0 and "cq: unimplemented: loops-classical: " + msg in r.stderr
            print(("ok   " if ok else "FAIL ") + probe.name + ("" if ok else ": expected cq::unimplemented '" + msg +
                                                             "', got exit " + str(r.returncode) + " " +
                                                             r.stderr.strip()[-300:]))
            failures += not ok
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
