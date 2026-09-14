#!/usr/bin/env python3
"""Track D injection (mutation) matrix — Rule 12's "validate by MUTATION, not by
re-reading the prefixes".

For each ACCEPT fixture: lower it once, then apply a fixed family of textual
mutations to the LOWERED IR and re-run EVERY `--check-prefix` the fixture's RUN
lines name. A mutation that no block rejects is MISSED — the fixture would have
stayed green with that gate injected, which is exactly how the three shipped
fixture-hygiene defects got in.

Textual mutation is deliberate: FileCheck reads text, so a mutant need not be
valid IR to be a faithful test of what the prefixes can SEE.
"""
import re, subprocess, sys, os
REPO = "/Users/sorenwilkening/Desktop/CQ_3d8q"
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

    def first(pat):
        for i, l in enumerate(lines):
            if re.search(pat, l):
                return i
        return None
    out = {}
    i = first(r"call void @cqrt_ry_")
    if i is not None:
        out["drop_first_ry"] = "".join(lines[:i] + lines[i + 1:])
        out["dup_first_ry"] = "".join(lines[:i] + [lines[i], lines[i]] + lines[i + 1:])
        out["swap_angle"] = "".join(lines[:i] +
                                    [re.sub(r"double [-0-9.e+]+", "double 4.200000e-01", lines[i])] +
                                    lines[i + 1:])
        out["ry_to_controlled"] = "".join(
            lines[:i] + [lines[i].replace("@cqrt_ry_", "@cqrt_ry_x_controlled_")] + lines[i + 1:])
        h = re.search(r"\(i32 (%[\w.]+)", lines[i])
        if h:
            g = h.group(1)
            out["extra_x"] = "".join(lines[:i + 1] + [f"  call void @cqrt_x(i32 {g})\n"] + lines[i + 1:])
            out["extra_free"] = "".join(lines[:i + 1] + [f"  call void @cqrt_free(i32 {g})\n"] + lines[i + 1:])
            out["extra_ry"] = "".join(lines[:i + 1] +
                                      [f"  call void @cqrt_ry_i32(i32 {g}, double 7.700000e-01)\n"] +
                                      lines[i + 1:])
    a = first(r"= call i32 @cqrt_alloc_")
    if a is not None:
        out["extra_alloc"] = "".join(lines[:a + 1] +
                                     [lines[a].replace("= call", "_dup = call", 1)] + lines[a + 1:])
        out["drop_alloc"] = "".join(lines[:a] + lines[a + 1:])
    m = first(r"@cqrt_measure_")
    if m is not None:
        out["drop_measure"] = "".join(lines[:m] + lines[m + 1:])
        out["dup_measure"] = "".join(lines[:m] + [lines[m], lines[m]] + lines[m + 1:])
    r = first(r"ret ")
    if r is not None:
        out["leftover_theta"] = "".join(
            lines[:r] + ["  %zz = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)\n"] + lines[r:])
    return out


tot = missed = 0
for f in sys.argv[1:]:
    text = open(f).read()
    p = subprocess.run([OPT, "-load-pass-plugin", PLUGIN, "-passes=cq-lowering", "-S", f],
                       capture_output=True, text=True)
    if p.returncode != 0:
        print(f"SKIP (declines, not an accept fixture): {os.path.basename(f)}")
        continue
    pfx = prefixes(text)
    base = p.stdout
    for name, mut in mutants(base).items():
        tot += 1
        caught = False
        for x in pfx:
            args = [FC, f] + ([] if x == "CHECK" else [f"--check-prefix={x}"])
            if subprocess.run(args, input=mut, capture_output=True, text=True).returncode != 0:
                caught = True
                break
        if not caught:
            missed += 1
            print(f"  MISSED  {os.path.basename(f)}  <- {name}")
print(f"injection matrix: {tot} mutations over {len(sys.argv)-1} fixtures, {missed} MISSED")
