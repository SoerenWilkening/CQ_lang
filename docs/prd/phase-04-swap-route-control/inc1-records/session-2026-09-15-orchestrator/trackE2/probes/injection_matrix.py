#!/usr/bin/env python3
"""Track E2 injection (mutation) matrix — Rule 12's "validate by MUTATION, not by
re-reading the prefixes".

For each ACCEPT fixture: lower it once with the SUBJECT binary, then apply a
family of textual mutations to the LOWERED IR and re-run EVERY `--check-prefix`
the fixture's own RUN lines name, with the SAME FileCheck command line lit runs
(no extra flags, none dropped — PROTOCOL S3: a harness that runs a WEAKER
command than lit measures itself, not the fixtures). A mutation no block rejects
is MISSED.

Textual mutation is deliberate: FileCheck reads text, so a mutant need not be
valid IR to be a faithful test of what the prefixes can SEE.

⚠ TWO SELF-CHECKS, because an instrument's failure mode is to report a PASS
(CLAUDE.md L10, six measured instances in one session):
  * called with NO fixture argument it EXITS NON-ZERO instead of printing
    "0 mutations, 0 MISSED";
  * a fixture that yields ZERO mutants is reported as a HOLE and exits
    non-zero — "checked 0" is not a pass.
"""
import os
import re
import subprocess
import sys

REPO = "/Users/sorenwilkening/Desktop/CQ_E2"
FC = "/usr/local/opt/llvm@19/bin/FileCheck"
OPT = f"{REPO}/build/ir-pass/cq-opt"
PLUGIN = f"{REPO}/build/ir-pass/libCQPass.so"


def prefixes(text):
    out = []
    for line in text.splitlines():
        if "%filecheck %s <" in line and "--check-prefix" not in line:
            out.append("CHECK")
        m = re.search(r"--check-prefix=(\w+)", line)
        if m:
            out.append(m.group(1))
    return out or ["CHECK"]


def mutants(ir):
    lines = ir.splitlines(keepends=True)
    out = {}

    def at(pred):
        for i, l in enumerate(lines):
            if pred(l):
                return i
        return None

    def sub_line(i, new):
        return "".join(lines[:i] + [new] + lines[i + 1:])

    def insert_after(i, new):
        return "".join(lines[:i + 1] + [new] + lines[i + 1:])

    # ── the RAUW-TARGET family: the defect this whole rule turns on. If the
    # implementation RAUW'd to the OPERAND instead of the type's zero, each of
    # these is what the lowered module would look like.
    for ty, zero in (("i1", "false"), ("i32", "0"), ("i64", "0"),
                     ("double", "0.000000e+00")):
        i = at(lambda l, t=ty, z=zero: l.strip() == f"ret {t} {z}")
        if i is not None:
            out[f"rauw_operand_ret_{ty}"] = sub_line(i, f"  ret {ty} undef\n")
            out[f"wrong_value_ret_{ty}"] = sub_line(
                i, f"  ret {ty} {'true' if ty == 'i1' else '7'}\n")
    i = at(lambda l: "add nsw i32" in l and l.rstrip().endswith(", 0"))
    if i is not None:
        out["rauw_operand_add"] = sub_line(i, lines[i].rstrip()[:-1] + "undef\n")

    # ── the CLASSICAL-BRANCH-MINTS-A-RAIL family (Rule 3 / the f64-angle
    # miscompile family): a rail, a rotation or a measurement gate minted for a
    # measure the taint analysis says is CLASSICAL.
    anchor = at(lambda l: l.startswith("entry:"))
    if anchor is not None:
        out["mint_rail_i32"] = insert_after(
            anchor, "  %zz = call i32 @cqrt_alloc_i32(i32 0)\n")
        out["mint_rail_i64"] = insert_after(
            anchor, "  %zz = call i32 @cqrt_alloc_i64(i32 0)\n")
        out["mint_rail_f64"] = insert_after(
            anchor, "  %zz = call i32 @cqrt_alloc_f64(double 0.000000e+00)\n")
        out["mint_measure_i32"] = insert_after(
            anchor, "  %zz = call i32 @cqrt_measure_i32(i32 %h)\n")
        out["mint_measure_i64"] = insert_after(
            anchor, "  %zz = call i64 @cqrt_measure_i64(i32 %h)\n")
        out["mint_measure_f64"] = insert_after(
            anchor, "  %zz = call double @cqrt_measure_f64(i32 %h)\n")
        out["mint_ry"] = insert_after(
            anchor, "  call void @cqrt_ry_i32(i32 %h, double 7.700000e-01)\n")
        out["mint_x"] = insert_after(anchor, "  call void @cqrt_x(i32 %h)\n")
        out["mint_free"] = insert_after(anchor, "  call void @cqrt_free(i32 %h)\n")
        # Rule 1's checked postcondition: a surviving front-end intrinsic.
        out["leftover_measure_intrinsic"] = insert_after(
            anchor, "  %zz = call i32 @cq_measure_si32(i32 0)\n")
        out["leftover_theta_intrinsic"] = insert_after(
            anchor, "  %zz = call i32 @cq_theta_si32(i32 0, double 1.0)\n")

    # ── the QUANTUM-STREAM family: only reachable in a fixture that has one.
    for pat, name in ((r"= call i32 @cqrt_alloc_", "alloc"),
                      (r"call void @cqrt_ry_", "ry"),
                      (r"= call i32 @cqrt_measure_", "measure")):
        i = at(lambda l, p=pat: re.search(p, l) and not l.startswith("declare"))
        if i is not None:
            out[f"drop_{name}"] = "".join(lines[:i] + lines[i + 1:])
            out[f"dup_{name}"] = "".join(lines[:i] + [lines[i], lines[i]] + lines[i + 1:])
    i = at(lambda l: "@cqrt_ry_" in l and "double" in l and not l.startswith("declare"))
    if i is not None:
        out["swap_angle"] = sub_line(
            i, re.sub(r"double [-0-9.e+]+", "double 4.200000e-01", lines[i]))

    # ── a body that DISAPPEARS (the MOD prefix's subject: this is a lowering,
    # not a deletion) and a WARNING on the stream (the owner ruled twice that
    # this family must compile SILENTLY).
    i = at(lambda l: l.startswith("define ") and "@f_beside_quantum" in l)
    if i is None:
        i = at(lambda l: l.startswith("define "))
    if i is not None:
        # ⚠ MUST actually change the line. The first spelling here was
        # `lines[i].replace("@f_", "@zzz_", 1)`, which is a NO-OP on a fixture
        # whose function is not named `@f_*` — a mutant identical to the
        # original, scored MISSED against a fixture that catches it. That is
        # PROTOCOL S3's "a harness that lies in the MISSED direction", caught
        # here by the rule that a mutant which equals its base is a HARNESS BUG.
        renamed = re.sub(r"@(\w+)\(", r"@zzz_\1(", lines[i], count=1)
        assert renamed != lines[i], f"rename_body did not mutate: {lines[i]!r}"
        out["rename_body"] = sub_line(i, renamed)
    out["warning_on_stream"] = "warning: cq lowering: something\n" + ir
    for k, v in out.items():
        assert v != ir, f"mutant {k} is identical to its base — harness bug"
    return out


def main(argv):
    if len(argv) < 2:
        print("ERROR: no fixture given. A matrix invoked with no argument would "
              "print '0 mutations, 0 MISSED', which is a HOLE, not a pass.",
              file=sys.stderr)
        return 2
    tot = missed = holes = 0
    for f in argv[1:]:
        text = open(f).read()
        p = subprocess.run([OPT, "-load-pass-plugin", PLUGIN,
                            "-passes=cq-lowering", "-S", f],
                           capture_output=True, text=True)
        if p.returncode != 0:
            print(f"SKIP (declines, not an accept fixture): {os.path.basename(f)}")
            continue
        pfx = prefixes(text)
        muts = mutants(p.stdout)
        if not muts:
            print(f"  HOLE  {os.path.basename(f)}  <- 0 mutants generated")
            holes += 1
            continue
        n = c = 0
        for name, mut in muts.items():
            tot += 1
            n += 1
            caught = False
            for x in pfx:
                args = [FC, f] + ([] if x == "CHECK" else [f"--check-prefix={x}"])
                if subprocess.run(args, input=mut, capture_output=True,
                                  text=True).returncode != 0:
                    caught = True
                    break
            if caught:
                c += 1
            else:
                missed += 1
                print(f"  MISSED  {os.path.basename(f)}  <- {name}")
        print(f"  checked {n} mutants over prefixes {pfx} in "
              f"{os.path.basename(f)}: {c} caught, {n - c} MISSED")
    print(f"injection matrix: {tot} mutations over {len(argv) - 1} fixtures, "
          f"{missed} MISSED, {holes} HOLE(s)")
    return 1 if (missed or holes or tot == 0) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
