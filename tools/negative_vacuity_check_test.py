#!/usr/bin/env python3
"""negative_vacuity_check_test.py — MUTANT VALIDATION of negative_vacuity_check.py.

Same argument as tools/free_pairing_check_test.py and
e2e-loop-twin-quarantine-selftest, one instrument over: A CHECKER NOBODY HAS
TRIED TO FOOL IS A CHECKER NOBODY SHOULD TRUST — and the specific thing this
one has to be fooled about is its own SILENCE. bd `test_C_libtooling-jdec` is
exactly that: the script it replaces printed `checked 0` and exited 0 on a
batch of 29 real negatives, which reads at a glance like `checked 29, 0
vacuous`. So the first and largest group here is not "does it find the defect"
but "does it REFUSE TO CLAIM A PASS when it found nothing to look at".

Layers
------
  1. HOLE — the harness must EXIT 2 (never 0, never 1) when nothing was
     actually evaluated: no arguments, a batch that matches no directive, an
     empty module, a missing compiler, a `--universe` that lowered to nothing.
  2. POSITIVE — a well-formed fixture must come back CLEAN (exit 0). This is
     what stops the checker being tightened into something that flags healthy
     fixtures, and it is where the three measured V2 false-positive shapes
     (quoted name, formal parameter, BASIC-BLOCK LABEL) are pinned.
  3. MUTANT — each planted vacuity must be reported with its own code.
  4. BINARY IDENTITY — the verdict line must carry the sha256 of the compiler
     it used. A gate result is a fact about a BINARY; the script this replaces
     hard-coded a worktree path that no longer exists, so its results were
     facts about nothing.

It runs the real `cq-opt` (it has to: V1/V2/V3 are questions about lowered
output), so it needs a built tree — and if there is none it says so and exits
2 rather than reporting a green.
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
TOOL = os.path.join(HERE, "negative_vacuity_check.py")
CQ_OPT = os.environ.get("CQ_OPT") or os.path.join(ROOT, "build", "ir-pass",
                                                  "cq-opt")
CQ_PASS = os.environ.get("CQ_PASS") or os.path.join(ROOT, "build", "ir-pass",
                                                    "libCQPass.so")

# A minimal ACCEPTING module: one theta, one measure. Lowered it becomes
# `cqrt_alloc_i32` + `cqrt_ry_i32` + `cqrt_measure_i32`, so a `-NOT` naming
# `@cqrt_cswap` is a live, non-vacuous negative and a `-NOT` naming `%h99` is
# not. ⚠ THE INTRINSIC SPELLING IS `cq_theta_si32`, NOT `cq_theta_i32` — the
# suffix is the `_Generic` tag, not the LLVM type. A module using the wrong
# spelling lowers to ITSELF through the passthrough early-out, exit 0, and
# every negative over it is vacuous. The first draft of this file did exactly
# that and the V3 control caught it, which is the selftest earning its keep on
# its own author.
ACCEPT_BODY = """\
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @f(i32 %x) {
entry:
  br label %head
head:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
"""

RUN_ACCEPT = ("; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering "
              "-S %s | %filecheck %s\n")


def fixture(run, directives, body=ACCEPT_BODY):
    return run + directives + body


# ---- layer 2: these must be CLEAN ------------------------------------------
POSITIVES = [
    ("live-symbol-negative", fixture(
        RUN_ACCEPT,
        "; CHECK: call i32 @cqrt_alloc_i32\n"
        "; CHECK-NOT: call void @cqrt_cswap\n")),
    # The three V2 shapes the inherited `^%x = ` regex got WRONG. Each was a
    # false VACUOUS before this file's widening; `%x` is a formal parameter,
    # `%head` is a basic-block label (measured on
    # ir-pass/test/control_phase_kickback_inloop.ll's `; C5-NOT: br label
    # %head`), and `%"q.1"` is a quoted SSA name.
    ("v2-formal-parameter-is-defined", fixture(
        RUN_ACCEPT,
        "; CHECK: call i32 @cqrt_alloc_i32\n"
        "; CHECK-NOT: call void @cqrt_x(i32 %x)\n")),
    ("v2-block-label-is-defined", fixture(
        RUN_ACCEPT,
        "; CHECK: call i32 @cqrt_alloc_i32\n"
        "; CHECK-NOT: br label %head\n")),
    ("v1-header-collision-is-SCOPED-out", fixture(
        RUN_ACCEPT,
        "; CHECK: call i32 @cqrt_alloc_i32\n"
        "; CHECK-NOT: cq_theta\n")),
]

# ---- layer 3: each planted vacuity, with its code --------------------------
MUTANTS = [
    ("V2-HANDLE-UNDEFINED", fixture(
        RUN_ACCEPT,
        "; CHECK: call i32 @cqrt_alloc_i32\n"
        "; CHECK-NOT: call void @cqrt_x(i32 %h99)\n")),
    # No positive directive above it, so FileCheck's region starts at the top
    # of the output and the `; ModuleID = '<path>'` line IS in range. The path
    # is a tempfile under .../negvac..., so the pattern is chosen to be in it.
    ("V1-MATCHES-HEADER", fixture(
        RUN_ACCEPT, "; CHECK-NOT: negvac\n")),
    ("V4-PREFIX-NEVER-RUN", fixture(
        RUN_ACCEPT,
        "; CHECK: call i32 @cqrt_alloc_i32\n"
        "; NOBODY-NOT: call void @cqrt_cswap\n")),
    ("V0-EMPTY-MODULE", RUN_ACCEPT + "; CHECK-NOT: call void @cqrt_cswap\n"),
]

# V3 needs a universe; kept apart because it takes extra arguments.
V3_MUTANT = fixture(
    RUN_ACCEPT,
    "; CHECK: call i32 @cqrt_alloc_i32\n"
    "; CHECK-NOT: @cqrt_teleport_i32\n")
# The control names a symbol the UNIVERSE MODULE ACTUALLY EMITS. (The first
# draft named `@cqrt_cswap`, which this compiler certainly can emit but the
# one-module universe does not — so the control failed, correctly. That is the
# rule working: V3's answer is about the UNIVERSE YOU GAVE IT, never about the
# compiler in general, and a one-module universe is a weak instrument. Said
# out loud here because a control that has to be weakened to pass is usually a
# finding about the rule, and this one is a finding about the CALLER.)
V3_CONTROL = fixture(
    RUN_ACCEPT,
    "; CHECK: call i32 @cqrt_alloc_i32\n"
    "; CHECK-NOT: @cqrt_ry_i32\n")
# The documented exclusion: a front-end intrinsic appears in NO lowered module
# BY CONSTRUCTION (`declineSurvivingIntrinsicCalls`), so V3 must not call it
# unreachable. Without this control the exclusion could be deleted unnoticed.
V3_FRONTEND_CONTROL = fixture(
    RUN_ACCEPT,
    "; CHECK: call i32 @cqrt_alloc_i32\n"
    "; CHECK-NOT: @cq_theta_si32\n")


def write(tmp, name, text):
    p = os.path.join(tmp, name)
    with open(p, "w") as fh:
        fh.write(text)
    return p


def run(args):
    r = subprocess.run([sys.executable, TOOL, "--cq-opt", CQ_OPT,
                        "--pass-plugin", CQ_PASS] + args,
                       capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def main():
    if not (os.path.exists(CQ_OPT) and os.path.exists(CQ_PASS)):
        print(f"negative_vacuity_check_test: no built compiler at {CQ_OPT} — "
              f"this selftest needs one, and reporting green without it would "
              f"be the exact defect it exists to catch", file=sys.stderr)
        return 2

    fails = []
    verbose = "-v" in sys.argv
    n_hole = n_pos = n_mut = 0
    tmp = tempfile.mkdtemp(prefix="negvac")

    # ---- layer 1: a HOLE is never a pass ---------------------------------
    holes = [
        ("no-arguments", []),
        ("nonexistent-fixture", [os.path.join(tmp, "there-is-no-such.ll")]),
    ]
    good = write(tmp, "ok.ll", POSITIVES[0][1])
    holes.append(("no-directive-matches",
                  [write(tmp, "nodirectives.ll",
                         RUN_ACCEPT + ACCEPT_BODY)]))
    holes.append(("universe-that-lowers-to-nothing",
                  [good, "--universe", os.path.join(tmp, "nothing*.ll")]))
    # A GENERATOR fixture: the compiler's input is `%t.gen.ll`, not `%s`.
    # Lowering `%s` would answer a question about a different module (and, for
    # the real instance in this tree — bd `ziuw`'s
    # lowering_predmux_purecallee_deep_chain.ll — would have manufactured a
    # V0-EMPTY-MODULE finding on a healthy fixture).
    holes.append(("generator-fixture-input-is-not-%s",
                  [write(tmp, "generated.ll",
                         "; RUN: %python gen.py > %t.gen.ll\n"
                         "; RUN: %cq-opt -load-pass-plugin %cq-pass "
                         "-passes=cq-lowering -S %t.gen.ll | %filecheck %s\n"
                         "; CHECK-NOT: call void @cqrt_cswap\n")]))
    for name, argv in holes:
        n_hole += 1
        rc, out = run(argv)
        if rc != 2:
            fails.append(f"HOLE {name}: expected exit 2, got {rc}\n{out}")
        elif verbose:
            print(f"  ok  hole      {name:36s} -> exit 2")
    # A missing compiler is also a hole, and must not be reported as clean.
    n_hole += 1
    r = subprocess.run([sys.executable, TOOL, "--cq-opt",
                        os.path.join(tmp, "no-such-binary"),
                        "--pass-plugin", CQ_PASS, good],
                       capture_output=True, text=True)
    if r.returncode != 2:
        fails.append(f"HOLE missing-compiler: expected exit 2, got "
                     f"{r.returncode}")
    elif verbose:
        print(f"  ok  hole      {'missing-compiler':36s} -> exit 2")

    # ---- layer 2: healthy fixtures are CLEAN ------------------------------
    for name, text in POSITIVES:
        n_pos += 1
        rc, out = run([write(tmp, name + ".ll", text)])
        if rc != 0:
            fails.append(f"POSITIVE {name}: expected a clean exit 0, got "
                         f"{rc}\n{out}")
        elif " 0 directive(s) evaluated" in out:
            fails.append(f"POSITIVE {name}: exited 0 having evaluated NOTHING "
                         f"— that is the bd jdec defect\n{out}")
        elif verbose:
            print(f"  ok  positive  {name:36s} -> clean")

    # ---- layer 3: each planted vacuity, by code ---------------------------
    # ⚠ WITH A UNIVERSE. (V2)/(V3) are decided against the batch's own lowered
    # outputs, and a ONE-module universe is too small to answer "the compiler
    # never emits this" — it can only answer "this one module does not". The
    # tool says UNDECIDABLE there rather than VACUOUS, which is the right
    # answer and would otherwise read here as a missing mutant.
    uni0 = write(tmp, "universe0.ll", POSITIVES[0][1])
    for code, text in MUTANTS:
        n_mut += 1
        rc, out = run([write(tmp, code.lower() + ".ll", text),
                       "--universe", uni0])
        # V0 is BOTH a finding and a hole (nothing could be evaluated), so it
        # exits 2; every other mutant exits 1. Both are "not a pass", which is
        # the property under test.
        want_rc = (1, 2) if code == "V0-EMPTY-MODULE" else (1,)
        if code not in out:
            fails.append(f"MUTANT {code}: not reported. exit={rc}\n{out}")
        elif rc not in want_rc:
            fails.append(f"MUTANT {code}: reported but exit={rc}, expected one "
                         f"of {want_rc}\n{out}")
        elif verbose:
            print(f"  ok  mutant    {code:36s} -> reported, exit {rc}")

    # A one-fixture run must NOT claim a vacuity it cannot decide.
    n_mut += 1
    rc, out = run([write(tmp, "lonely.ll", MUTANTS[0][1])])
    if "V2-HANDLE-UNDEFINED-UNDECIDABLE" not in out or rc != 0:
        fails.append(f"SMALL UNIVERSE: a single-fixture run must report the "
                     f"(V2) candidate UNDECIDABLE and exit 0, not claim it "
                     f"vacuous. exit={rc}\n{out}")
    elif verbose:
        print(f"  ok  control   {'one-fixture-universe-undecidable':36s} -> NOTE")

    # ---- layer 3b: V3, with its universe and both controls ----------------
    uni = write(tmp, "universe.ll", POSITIVES[0][1])
    # ⚠ (V3) IS A NOTE BY DEFAULT and only a verdict under
    # `--strict-unreachable` — see its docstring: run over the whole corpus it
    # produced 1116 findings and every one examined was FALSE, because a `-NOT`
    # naming something the compiler must never emit is PASSING, not vacuous.
    # The mutant is therefore checked under the strict flag; the two controls
    # are checked under it as well, so they still pin the rule rather than the
    # demotion.
    for name, text, want in (
            ("V3-UNREACHABLE-SYMBOL", V3_MUTANT, True),
            ("v3-control-emittable-symbol", V3_CONTROL, False),
            ("v3-control-frontend-intrinsic", V3_FRONTEND_CONTROL, False)):
        n_mut += 1
        rc, out = run([write(tmp, name + ".ll", text), "--universe", uni,
                       "--strict-unreachable"])
        got = "V3-UNREACHABLE-SYMBOL" in out
        if got != want:
            fails.append(f"V3 {name}: expected reported={want}, got {got}, "
                         f"exit={rc}\n{out}")
        elif verbose:
            print(f"  ok  v3        {name:36s} -> reported={got}")

    # (V3) MUST NOT be a verdict without the flag: the demotion is the finding
    # of record, so it gets its own control.
    n_mut += 1
    rc, out = run([write(tmp, "v3_default.ll", V3_MUTANT), "--universe", uni])
    if rc != 0 or "VACUOUS/V3" in out:
        fails.append(f"V3 default: (V3) must be a NOTE without "
                     f"--strict-unreachable, got exit={rc}\n{out}")
    elif verbose:
        print(f"  ok  control   {'v3-is-a-note-by-default':36s} -> exit 0")

    # ---- layer 4: the verdict names the BINARY ----------------------------
    n_mut += 1
    rc, out = run([good])
    if not re.search(r"\[cq-opt [0-9a-f]{16}\]", out):
        fails.append("BINARY IDENTITY: the verdict line does not carry the "
                     "sha256 of the compiler it used — a gate result is a fact "
                     f"about a BINARY\n{out}")
    elif verbose:
        print(f"  ok  identity  {'verdict names the binary':36s} -> ok")

    print(f"negative_vacuity_check_test: {n_hole} hole case(s), {n_pos} "
          f"positive(s), {n_mut} mutant(s)/control(s), {len(fails)} failure(s)")
    for f in fails:
        print("  FAIL " + f, file=sys.stderr)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
