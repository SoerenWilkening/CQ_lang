#!/usr/bin/env python3
"""tests/uncompute probes (cq-lshe, owner 2026-11-02 no stops): small programs through the real cq-lower plugin.

Each case names a probe (probes/<name>.O1.ll, clang -O1 of probes/<name>.c), its entry, extra opt flags and
what it must give:
  - "pass": cq-lower exits 0, plain cq-verify accepts the output, every regex in `match` occurs in the
    lowered module, and the entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle);
  - "fatal: <text>": cq-lower stops with that error.
Outputs go to build/tests/uncompute/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"

# (probe, entry, opt flags, expectation, regexes the lowered module must contain)
CASES = [
    # cq-dw87k (rule 6): y' with a clean-up guarded on one classical arm keeps its plain item on the other paths, which reads y: y is not
    # cleaned from y' (was: use-after-free on a phi incoming, since 8370d05).
    ("rule6_guarded_garbage_q", "e", [], "pass", []),
    ("rule6_guarded_garbage_xor", "e", [], "pass", []),
    ("rule6_guarded_garbage_two", "e", [], "pass", []),
    # cq-nbtxu (rule 6, both operands dead): a classical choice between updates of the same two rails: one is cleaned, the other kept.
    ("rule6_sel_sub_add", "e", [], "pass", []),
    ("rule6_sel_rsub_add", "e", [], "pass", []),
    ("rule6_merge_sub_xor", "e", [], "pass", []),
    ("rule6_merge_chain", "e", [], "pass", []),
    ("rule6_merge_three", "e", [], "pass", []),
    # CR rule 9: a kept classical select over two garbage arms keeps the chosen arm and cleans the other under
    # the select's condition (was: 'a kept role on a classical select over handles').
    ("kept_merge", "ks", [], "pass", [r"br i1 %cq\.not"]),
    # CR rule 2 (2026-11-02, cq-29ej: collapse is static; §1.3 a measured rail is never freed): a rail measured on
    # some classical paths only is lowered as unmeasured and the measurement reads a kept basis copy (cq-4lqy;
    # was: 'a rail measured on some paths only, ...'). pm_join and pm_loop lower and verify; their §6 run waits
    # on the checker's C oracle treating a value measured after a partial measurement as classical (bead below).
    ("partial_measure", "pm_ret", [], "pass", [r"call void @cqrt_copy_i32"]),
    ("partial_measure", "pm_join", [], "lower", [r"call void @cqrt_copy_i32"]),
    ("partial_measure", "pm_loop", [], "lower", [r"call void @cqrt_copy_i32"]),
    # CR §0, rule 5, §1.1 (cq-4lqy): a gate through a slot cell that may name an operand rail of pending garbage is
    # decided at run time by comparing handles (was: 'awaiting owner ruling: ... a gate through a slot cell').
    # ah_loop fails §6 with a leaked i1 rail: bead cq-asp1 (suspected mem-slots, a register cell copy overwritten).
    # CR rule 18 twin point (cq-4lqy): a live result of a clone call is copied out before the twin (was: 'a call
    # whose results are partly kept').
    ("copy_out", "co", [], "pass", [r"call void @__cq_q_two_1_unc"]),
    # CR rules 5 (sentence 3), 14: rails kept-stored in or around a loop (cq-mmdf3, cq-gr5vw, cq-ii0vf).
    *[("stored_loops", e, [], "pass", []) for e in (
        "sl_each", "sl_each_rot", "sl_each_meas", "sl_phi", "sl_walk", "sl_before", "sl_after", "sl_in", "sl_guard",
        "sl_trip", "sl_acc", "sl_phi_some", "sl_kloop", "sl_arm", "sl_arm_false",
        "sl_exit", "sl_exit_zero", "sl_exit_both", "sl_exit_twice", "sl_exit_nested", "sl_exit_kloop")],
    # CR §1.3 (cq-4lqy): a POP kept on some paths keeps the earlier POPs and the bus on the same paths.
    # kp, kq (a measured merge whose arm t is measured again as t * 7): bead cq-g72r (rule 2 collapse of t * 7 where
    # the merge measured t); listed once it is fixed.
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--case", action="append", help="run only these probes")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "uncompute" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0
    for probe, entry, flags, expect, match in CASES:
        if a.case and probe not in a.case:
            continue
        src = PROBES / (probe + ".O1.ll")
        lowered = out / (probe + "." + entry + ".lowered.ll")
        r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", *flags, "-S", str(src),
                            "-o", str(lowered)], capture_output=True, text=True)
        why = []
        if expect.startswith("fatal: "):
            if r.returncode == 0:
                why.append("cq-lower succeeded, expected " + expect)
            elif expect[len("fatal: "):] not in r.stderr:
                why.append("cq-lower: " + r.stderr.strip()[:400])
        elif r.returncode != 0:
            why.append("cq-lower: " + r.stderr.strip()[:400])
        else:
            v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                                str(lowered)], capture_output=True, text=True)
            if v.returncode != 0:
                why.append("cq-verify: " + v.stderr.strip()[:400])
            text = lowered.read_text()
            for m in match:
                if not re.search(m, text):
                    why.append("no match for " + m)
            c = subprocess.CompletedProcess([], 0, "PASS", "") if expect == "lower" else subprocess.run(
                [sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered", str(lowered),
                 "--entry", entry], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        print(("FAIL " if why else "ok   ") + probe + ":" + entry + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
