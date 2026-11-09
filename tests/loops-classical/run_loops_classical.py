#!/usr/bin/env python3
"""tests/loops-classical (cq-w1-loops-classical): the module's probes through the real plugin.

For probes/loops.O1.ll (and slots.O1.ll, rule6.O1.ll) it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left; every entry with a loop pushes and pops (the reverse ran);
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
For rule6.O1.ll it also checks the kept rails at trip counts 2 and 3 (cq-b13w, CR rule 6 on carried values), and
for deferred.O1.ll likewise (cq-fx3s, cq-aqbw: the reverse loop deferred after the exit values' readers keeps no
which-path or garbage rail), and for measured_some.O1.ll likewise (cq-8lf8: a computed rail measured on an early
return only is not left as garbage on the loop path), and for memkeep.O1.ll on every sample (cq-djnk, cq-9o04: no
entangled rail of a loop that writes memory is left unmeasured at exit).
The owned examples' acceptance is `python3 -m cqcheck run <examples> --oracle both` (the bead).
Outputs go to build/tests/loops-classical/out/.
"""
import argparse
import concurrent.futures
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
PROBE = PROBES / "loops.O1.ll"
# cq-sujx: rule 20 slot cells loaded and stored per trip (58, 60 shapes).
SLOT_PROBE = PROBES / "slots.O1.ll"
SLOT_ENTRIES = ["s_reg", "s_qft", "s_int"]
# Shapes once stopped on (the text names the old stop); now each entry is §6-checked (owner ruling 2026-11-05).
FATAL = [(PROBES / "slots_fatal_crossgate.O1.ll", "loops-classical: a non-diagonal gate in a classically bounded loop on a rail"),
         # cq-vqid: a record deferred to the reverse loop reads a rail rotated later in the same trip.
         (PROBES / "fatal_undoneread.O1.ll", "loops-classical: a non-diagonal gate in a classically bounded loop on a rail that a "
          "record undone by the reverse loop reads"),
         # cq-pkjc: a quantum arm's classical conjunct (select(i != 0, q[i], false)) the trip does not establish.
         (PROBES / "fatal_armguard.O1.ll", "loops-classical: a block of a classically bounded loop body whose classical guard "
          "(rule 8: the classical factor of its predicate"),
         # cq-djnk (review loopscl-h2 p31, p30): a measured load reads one cell after the loop; the other instances the
         # loop stores are garbage (keeping the whole object leaked them).
         (PROBES / "fatal_keep_partial.O1.ll", "mem-slots: a rail a classically bounded loop stores into a slot "
          "cell is kept because a measured load after the loop may read it, but another write"),
         (PROBES / "fatal_keep_partial_ry.O1.ll", "mem-slots: a rail a classically bounded loop stores into a "
          "slot cell is kept because a measured load after the loop may read it, but another write"),
         # cq-9o04 (review loopscl-h2 p29): an Ry the reverse loop must precede, then a read of the QRAM it pops.
         (PROBES / "fatal_qram_barrier.O1.ll", "uncompute: a non-diagonal gate or an in-place write on a rail the "
          "deferred rule-14 reverse loop reads"),
         # cq-igqp: a carried register rotated in the trip on some paths only (its initial rail must be kept on the
         # others' complement), a record before the loop undone after it against the rotated initial rail, the
         # initial value read after the loop, a rotated seed of the loop.
         (PROBES / "fatal_carried_arm.O1.ll", "uncompute: a non-diagonal gate on some paths only precedes the "
          "resolution of an unchosen arm of a kept merged handle"),
         (PROBES / "fatal_carried_read.O1.ll", "uncompute: a barrier in another block lies between a rail and its "
          "uncompute"),
         (PROBES / "fatal_carried_sunk.O1.ll", "spine: %4, bound to the rail cq_theta rotates in place (a rail its "
          "operand's phi may name), is read after the rotation"),
         # cq-w3cd: a classical region nested in one quantum arm of a trip must rejoin before the other arm's code.
         (PROBES / "fatal_rejoin.O1.ll", "loops-classical: a classical branch nested in a quantum arm of a trip whose "
          "region does not close at one join")]
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
# cq-nqa6: a multi-exit case-3 loop (bound at the header, quantum exit at the latch) whose counter is read after it.
MXREAD_PROBE = PROBES / "mx_read.O1.ll"
MXREAD = ["p_find", "p_find2"]
# cq-igqp: a carried register rotated in place in the trip (classical bound; quantum bound and exit, the cutoff): the
# rail the header phi names on trip 0 is never uncomputed through and freed dirty.
CARRIED_PROBE = PROBES / "carried_rot.O1.ll"
CARRIED = ["p38", "p38_cut", "p38_cutx"]
NO_REVERSE = ["p38_cut", "p38_cutx"]   # a quantum bound: unrolled to the cutoff K, no reverse loop
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
# cq-djnk, cq-9o04: kept rails after a loop that writes memory (every sample): only the measured values and x.
MEMKEEP_PROBE = PROBES / "memkeep.O1.ll"
MEMKEEP = {"k_hist": [("measured", "i32"), ("measured", "i32")],
           "k_whole": [("frozen", "i32")] + [("measured", "i32")] * 4}
# cq-w3cd: a classical branch or switch nested in a quantum arm of a trip (rule 8), its mixed join (rule 9).
CARM_PROBE = PROBES / "carm.O1.ll"
CARM = ["a_diamond", "a_inner", "a_phase"]
# cq-w3cd: loops nested in a case-3 trip (rule 14: the inner chain seeded by the outer trip rail).
C3NEST_PROBE = PROBES / "c3nest.O1.ll"
C3NEST = ["n_inner1", "n_inner3", "n_phase"]
# cq-w3cd: a case-3 exit test with several quantum disjuncts (one flag, rule 8).
C3TWO_PROBE = PROBES / "c3two.O1.ll"
C3TWO = ["t_or", "t_bool", "t_do"]
# cq-mgkr: clone calls with a quantum result and libm intrinsics in a classically bounded trip (rule 18 in rule 14).
CALLS_PROBE = PROBES / "calls.O1.ll"
CALLS = ["lc_call", "lc_libm", "lc_chain"]
# cq-l56v: a quantum-exit loop nested in a classically bounded trip (rule 14 nested K-loops; musl __rem_pio2_large).
KNEST_PROBE = PROBES / "knest.O1.ll"
KNEST = ["k_in_c", "k_in_arm", "k_in_c3"]
# cq-l56v: a case-3 multi-exit loop whose exit arm branches (rule 8 flags, rule 9 selects), nested in a classical trip.
C3ARM_PROBE = PROBES / "c3arm.O1.ll"
C3ARM = ["arm_branch"]
MXNEST_PROBE = PROBES / "mxnest.O1.ll"
MXNEST = ["mx_nest"]
# cq-l56v: a classical value read after a case-3 loop (capture rail); a seed rotated by every trip (was a fatal probe).
C3IDX_PROBE = PROBES / "c3idx.O1.ll"
C3IDX = ["c3_index", "c3_mixed"]
SEED_PROBE = PROBES / "fatal_carried_seed.O1.ll"
SEED = ["p38_seed"]
# cq-j5mq: several classical exit edges into one exit block, also from a sub-loop.
EXIT_EDGES_PROBE = PROBES / "exit_edges.O1.ll"
EXIT_EDGES = ["two_exits", "arm_exits", "nested_exits"]
# cq-wyu4: a carried register read by a record the reverse loop undoes, rotated by a direct cq_theta later in the trip
# or in the next trip (the record kept on the runs where the gate acted after it, undone where none did).
ROT_READ_PROBE = PROBES / "rot_after_read.O1.ll"
ROT_READ = ["r_after", "r_before"]
# CR rule 14 with rules 8, 9: a classical exit into the exit arm (case 3, strlen's and strcpy's shape; case 1, cq-y7kw), the
# arm's loops, a sub-loop that also leaves its parent (printf_core's), a loop right after a loop, a guard's value at C.
EXIT_ARM_PROBE = PROBES / "exit_arm.O1.ll"
EXIT_ARM = ["pc5b", "pa2b", "pa1b", "pc4", "pa5", "pc3"]
# cq-os2bx (owner Q1): musl __fwritex's shape, an exit arm with a call and stores runs once after the loop.
ARM_ONCE_PROBE = PROBES / "arm_once.O1.ll"
ARM_ONCE = ["ao_write"]
ENTRIES = ["p_acc", "p_brk", "p_nest", "p_mod", "p_nb", "p_horner", "p_arm", "p_phase", "p_cjoin", "p_tphase", "p_bwb", "p_g2"]
ENTRY_LIMIT = 180   # cq-1dx6: an entry with no verdict by then is a reported failure, not a silent hang
JOBS = min(int(os.environ.get("CQCHECK_JOBS", "2")), 4)
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def check_probe(a, probe: Path, entries, out: Path) -> int:
    lowered = out / (probe.stem + ".lowered.ll")
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL cq-lower " + probe.name + ": " + (r.stderr.strip().splitlines() or ["?"])[0], flush=True)
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify " + probe.name + ": " + (v.stderr.strip().splitlines() or ["?"])[0], flush=True)
        return 1
    text = lowered.read_text()
    def one(e: str) -> int:
        b = body(text, e)
        why = []
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        if e not in MEASURED_SEC6 + NO_REVERSE and ("@cqrt_push(" not in b or "@cqrt_pop()" not in b):
            why.append("no push/pop: the reverse loop is missing")
        t0 = time.time()
        try:
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered", str(lowered),
                                "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker",
                               timeout=ENTRY_LIMIT)
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        except subprocess.TimeoutExpired:
            why.append(f"§6 against the C program: no verdict in {ENTRY_LIMIT} s")
        # cq-1dx6: every entry reports as it ends, with its time.
        print(("FAIL " if why else "ok   ") + f"{probe.stem} {e} {time.time() - t0:.0f}s" +
              ("" if not why else ": " + "; ".join(why)), flush=True)
        return bool(why)
    with concurrent.futures.ThreadPoolExecutor(max_workers=JOBS) as pool:
        return sum(pool.map(one, entries))


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
    ap.add_argument("--group", action="append", choices=["loops", "slots", "rule6", "deferred", "measured", "hoisted", "carry", "fatal", "triplocal", "qram", "mxread", "memkeep", "carried", "carm", "c3nest", "c3two", "calls", "knest", "c3arm", "mxnest", "c3idx", "seed", "exit_edges", "exit_arm", "rot_read", "arm_once"],
                    help="run only these probe groups (default: all)")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "loops-classical" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0
    want = set(a.group or (["loops"] if a.entry else ["loops", "slots", "rule6", "deferred", "measured", "hoisted", "carry", "fatal", "triplocal", "qram", "mxread", "memkeep", "carried", "carm", "c3nest", "c3two", "calls", "knest", "c3arm", "mxnest", "c3idx", "seed", "exit_edges", "exit_arm", "rot_read", "arm_once"]))
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
    if "mxread" in want:
        groups.append((MXREAD_PROBE, MXREAD))
    if "triplocal" in want:
        groups.append((TRIPLOCAL_PROBE, TRIPLOCAL))
    if "qram" in want:
        groups.append((QRAM_PROBE, QRAM))
    if "carry" in want:
        groups.append((CARRY_PROBE, CARRY))
    if "memkeep" in want:
        groups.append((MEMKEEP_PROBE, list(MEMKEEP)))
    if "carried" in want:
        groups.append((CARRIED_PROBE, CARRIED))
    for g, probe, entries in (("carm", CARM_PROBE, CARM), ("c3nest", C3NEST_PROBE, C3NEST), ("c3two", C3TWO_PROBE, C3TWO),
                                 ("calls", CALLS_PROBE, CALLS), ("knest", KNEST_PROBE, KNEST),
                                 ("c3arm", C3ARM_PROBE, C3ARM), ("mxnest", MXNEST_PROBE, MXNEST),
                                 ("c3idx", C3IDX_PROBE, C3IDX), ("seed", SEED_PROBE, SEED),
                                 ("exit_edges", EXIT_EDGES_PROBE, EXIT_EDGES), ("exit_arm", EXIT_ARM_PROBE, EXIT_ARM),
                                 ("rot_read", ROT_READ_PROBE, ROT_READ), ("arm_once", ARM_ONCE_PROBE, ARM_ONCE)):
        if g in want:
            groups.append((probe, entries))
    for probe, entries in groups:
        failures += check_probe(a, probe, entries, out)
    for group, probe, table in (("rule6", RULE6_PROBE, RULE6), ("deferred", DEFERRED_PROBE, DEFERRED),
                                 ("measured", MEASURED_PROBE, MEASURED)):
        if group not in want:
            continue
        for e, kept in table.items():
            why = check_kept(probe, out / (probe.stem + ".lowered.ll"), e, kept)
            print(("FAIL " if why else "ok   ") + e + " kept" + ("" if not why else ": " + why), flush=True)
            failures += bool(why)
    if "memkeep" in want:
        for e, kept in MEMKEEP.items():
            why = check_kept(MEMKEEP_PROBE, out / (MEMKEEP_PROBE.stem + ".lowered.ll"), e, kept, lambda args: True)
            print(("FAIL " if why else "ok   ") + e + " kept" + ("" if not why else ": " + why), flush=True)
            failures += bool(why)
    if "measured" in want:
        for e, kept in MEASURED_NONE.items():
            why = check_kept(MEASURED_PROBE, out / (MEASURED_PROBE.stem + ".lowered.ll"), e, kept,
                             lambda args: all(int(v, 16) == 0 for v in args))
            print(("FAIL " if why else "ok   ") + e + " kept (measured nowhere)" + ("" if not why else ": " + why))
            failures += bool(why)
    if "fatal" in want:
        # Owner ruling 2026-11-05: no stop for an unbuilt shape; these probes run on, and §6 judges every entry.
        for probe, _ in FATAL:
            entries = re.findall(r"^define (?!internal|private)[^\n]*@(\w+)\(", probe.read_text(), re.M)
            NO_REVERSE.extend(entries)
            failures += check_probe(a, probe, entries, out)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
