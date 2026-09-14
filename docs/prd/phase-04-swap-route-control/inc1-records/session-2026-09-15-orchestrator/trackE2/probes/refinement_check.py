#!/usr/bin/env python3
"""Track E2 — THE REFINEMENT MEASUREMENT (obligation (c)).

The claim bd `fve8`'s accept rests on, in the same form bd `z9t1` shipped it:

    SUBJECT(module with a whole-value `undef`/`poison` measure operand)
      ==bytes==
    ORACLE(the same module with that ONE token written as the type's zero)

over a stated POPULATION, MEASURED, never asserted. Any divergence is a
STOP-and-report: it returns the ruling to the owner.

Usage:  refinement_check.py <stage-1 .ll> ...
Each argument must already be a stage-1 module (a `.c` probe is compiled by the
caller, so this script never guesses clang flags).

⚠ SELF-CHECKS (CLAUDE.md L10 — an instrument's failure mode is to report a PASS):
  * no argument           -> exit 2, never "0 modules, 0 divergences";
  * a module with no whole-value undef/poison measure operand -> reported as
    NOPOP and counted, never silently skipped into a clean total;
  * a twin that is byte-identical to its base (i.e. the rewrite did nothing)
    -> HARNESS BUG, exit non-zero.
⚠ Lowered-IR hashes are NOT compared across sweeps (PROTOCOL S3, the temp
`ModuleID`): both binaries read files written into the SAME temp directory with
the SAME basename, and only `; ModuleID` / `source_filename` are stripped.
"""
import os
import re
import subprocess
import sys
import tempfile

ORACLE = "/Users/sorenwilkening/Desktop/CQ_lang/build"
SUBJECT = "/Users/sorenwilkening/Desktop/CQ_E2/build"

ZERO = {
    "i1": "false", "i8": "0", "i16": "0", "i32": "0", "i64": "0", "i128": "0",
    "half": "0xH0000", "float": "0.000000e+00", "double": "0.000000e+00",
    "x86_fp80": "0xK00000000000000000000",
}

# `call <retty> @cq_measure_<sfx>(<argty> [attrs...] undef|poison)`
CALL = re.compile(
    r"(@cq_measure_[A-Za-z0-9_]+\(\s*)([A-Za-z0-9_]+)((?:\s+\w+(?:\([^)]*\))?)*\s+)"
    r"(undef|poison)(\s*\))")


def twin(text):
    """Rewrite every whole-value undef/poison measure operand to the type's zero."""
    n = [0]

    def rep(m):
        ty = m.group(2)
        if ty not in ZERO:
            return m.group(0)
        n[0] += 1
        return m.group(1) + ty + m.group(3) + ZERO[ty] + m.group(5)

    return CALL.sub(rep, text), n[0]


def normalize(path):
    """Reprint the module through the LLVM-19 parser.

    ⚠ LOAD-BEARING, not tidiness. The POPULATION is defined on the module the
    PASS SEES, and the parser constant-folds on the way in: `ptrtoint (ptr undef
    to i32)` is reprinted as plain `i32 undef` and IS a whole-value member,
    while `ptrtoint (ptr @g to i32)` survives and is NOT. A twin built from the
    raw source text would miss the first and report a phantom divergence.
    `verify` transforms nothing; the folding happens in `LLParser`.
    """
    p = subprocess.run(["/usr/local/opt/llvm@19/bin/opt", "-passes=verify",
                        "-S", path], capture_output=True, text=True)
    if p.returncode != 0:
        raise SystemExit(f"ERROR: {path} does not parse: {p.stderr[:200]}")
    return p.stdout


def lower(build, src, out, err):
    p = subprocess.run(
        [f"{build}/ir-pass/cq-opt", "-load-pass-plugin",
         f"{build}/ir-pass/libCQPass.so", "-passes=cq-lowering", "-S", src,
         "-o", out], capture_output=True, text=True)
    open(err, "w").write(p.stderr)
    return p.returncode


def body(path):
    if not os.path.exists(path):
        return None
    keep = [l for l in open(path)
            if not l.startswith("; ModuleID") and not l.startswith("source_filename")]
    return "".join(keep)


def main(argv):
    if len(argv) < 2:
        print("ERROR: no module given — '0 modules, 0 divergences' is a HOLE, "
              "not a pass.", file=sys.stderr)
        return 2
    pop = nopop = same = diff = ad = 0
    for f in argv[1:]:
        text = normalize(f)
        tw, n = twin(text)
        if n == 0:
            nopop += 1
            print(f"NOPOP   {os.path.basename(f)}  (no whole-value undef/poison "
                  f"measure operand — not in the population)")
            continue
        assert tw != text, f"twin rewrite was a no-op on {f} — harness bug"
        pop += 1
        with tempfile.TemporaryDirectory() as T:
            b = "m.ll"
            open(f"{T}/{b}", "w").write(text)
            open(f"{T}/twin_{b}", "w").write(tw)
            rs = lower(SUBJECT, f"{T}/{b}", f"{T}/s.ll", f"{T}/s.err")
            ro = lower(ORACLE, f"{T}/twin_{b}", f"{T}/o.ll", f"{T}/o.err")
            # ⚠ A SUBJECT DECLINE IS NOT AUTOMATICALLY AN `A->D`, and the first
            # spelling of this branch said it was. A module that declines on
            # BOTH binaries for a reason that has nothing to do with `undef`
            # (`e2w`: `value-arm swap-route under quantum control`) was reported
            # as `A->D !!`, i.e. as a finding against this change, when its
            # written-zero TWIN declines identically. The label is decided by
            # asking the TWIN, never by the subject's exit code alone.
            if rs != 0 and ro != 0:
                pop -= 1
                nopop += 1
                se = open(f"{T}/s.err").read().strip()
                oe = open(f"{T}/o.err").read().strip()
                tag = "same string" if se.split(": ")[-1] == oe.split(": ")[-1] \
                    else "DIFFERENT strings"
                print(f"D-BOTH  {os.path.basename(f)}  the module and its twin "
                      f"BOTH decline ({tag}) — outside the refinement "
                      f"population: {se.split(': ')[-1][:90]}")
                continue
            if rs != 0:
                ad += 1
                print(f"SUBJ-DECLINE !! {os.path.basename(f)}  the undef module "
                      f"is REFUSED where its written-zero twin COMPILES: "
                      f"{open(f'{T}/s.err').read().strip()[:120]}")
                continue
            if ro != 0:
                diff += 1
                print(f"DIVERGE {os.path.basename(f)}  the written-zero TWIN "
                      f"declines on the ORACLE: "
                      f"{open(f'{T}/o.err').read().strip()[:120]}")
                continue
            bs, bo = body(f"{T}/s.ll"), body(f"{T}/o.ll")
            if bs == bo:
                same += 1
                print(f"IDENT   {os.path.basename(f)}  ({n} operand(s) rewritten)")
            else:
                diff += 1
                print(f"DIVERGE {os.path.basename(f)}")
                for l in __import__("difflib").unified_diff(
                        bo.splitlines(), bs.splitlines(),
                        "ORACLE(zero twin)", "SUBJECT(undef)", lineterm="", n=1):
                    print("    " + l)
    print(f"refinement: population {pop} module(s) "
          f"({nopop} outside the population), {same} BYTE-IDENTICAL, "
          f"{diff} DIVERGENCE(S), {ad} SUBJ-DECLINE")
    return 1 if (diff or ad or pop == 0) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
