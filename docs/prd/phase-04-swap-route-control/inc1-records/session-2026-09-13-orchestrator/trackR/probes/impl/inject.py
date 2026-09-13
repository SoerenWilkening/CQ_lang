#!/usr/bin/env python3
"""R-1 injection (mutation) matrix — Rule 12(c).

For each ACCEPT fixture: lower it, apply each mutation to the LOWERED stream,
re-run EVERY FileCheck prefix the fixture declares, and report the prefixes that
caught it.  MISSED = a mutation no declared prefix rejects.
"""
import re, subprocess, sys, os, tempfile

REPO = "/Users/sorenwilkening/Desktop/CQ_rb9x"
FC   = "/usr/local/opt/llvm@19/bin/FileCheck"
OPT  = f"{REPO}/build/ir-pass/cq-opt"
PASS = f"{REPO}/build/ir-pass/libCQPass.so"

def lower(f):
    r = subprocess.run([OPT, "-load-pass-plugin", PASS, "-passes=cq-lowering", "-S", f],
                       capture_output=True, text=True)
    assert r.returncode == 0, (f, r.stderr[:400])
    return r.stdout

def prefixes(src):
    out = []
    for m in re.finditer(r"RUN:\s*%filecheck\s+%s(?:\s+--check-prefix=(\S+))?", src):
        out.append(m.group(1) or "CHECK")
    return out

def check(fixture, ir, pfx):
    with tempfile.NamedTemporaryFile("w", suffix=".ll", delete=False) as t:
        t.write(ir); p = t.name
    args = [FC, fixture]
    if pfx != "CHECK":
        args.append(f"--check-prefix={pfx}")
    with open(p) as fh:
        r = subprocess.run(args, stdin=fh, capture_output=True, text=True)
    os.unlink(p)
    return r.returncode == 0

# --- the mutations -----------------------------------------------------------
def m_ry_on_cond(ir):
    """(a) an uncontrolled cqrt_ry on the CONDITION register, AFTER the flag's free."""
    lines = ir.split("\n")
    reg = None
    for l in lines:
        m = re.search(r"(%\S+) = call i32 @cqrt_alloc_i32\(i32 0\)", l)
        if m: reg = m.group(1); break
    for i, l in enumerate(lines):
        if "@cqrt_free(" in l:
            lines.insert(i + 1, f"  call void @cqrt_ry_i32(i32 {reg}, double 5.000000e-01)")
            return "\n".join(lines)
    return None

def m_x_on_user(ir):
    """(b) a cqrt_x on a USER register (the prepped i1 rail)."""
    lines = ir.split("\n")
    rail = None
    for l in lines:
        m = re.search(r"(%\S+) = call i32 @cqrt_alloc_i1\(", l)
        if m: rail = m.group(1); break
    for i, l in enumerate(lines):
        if "@cqrt_ry_i1_controlled(" in l:
            lines.insert(i + 1, f"  call void @cqrt_x(i32 {rail})")
            return "\n".join(lines)
    return None

def m_extra_free(ir):
    """(c) an extra cqrt_free — of the PREPPED rail (the Rule-6 freeze violation)."""
    lines = ir.split("\n")
    rail = None
    for l in lines:
        m = re.search(r"(%\S+) = call i32 @cqrt_alloc_i1\(", l)
        if m: rail = m.group(1); break
    for i, l in enumerate(lines):
        if "@cqrt_ry_i1_controlled(" in l:
            lines.insert(i + 1, f"  call void @cqrt_free(i32 {rail})")
            return "\n".join(lines)
    return None

def m_swap_ctl(ir):
    """(d) the _controlled gate's CONTROL and TARGET swapped."""
    def rep(m):
        return f"call void @cqrt_ry_i1_controlled(i32 {m.group(2)}, i32 {m.group(1)}, double"
    out, n = re.subn(r"call void @cqrt_ry_i1_controlled\(i32 (%\S+), i32 (%\S+), double", rep, ir)
    return out if n else None

def m_swap_copies(ir):
    """(e) the peeled mux's two controlled COPIES swapped (arm value <-> straight-through)."""
    ops = re.findall(r"call void @cqrt_copy_i32_controlled\(i32 %\S+, i32 (%\S+), i32 %\S+\)", ir)
    if len(ops) != 2: return None
    a, b = ops
    # swap the two source-rail operands
    seen = []
    def rep(m):
        seen.append(1)
        src = b if len(seen) == 1 else a
        return f"call void @cqrt_copy_i32_controlled(i32 {m.group(1)}, i32 {src}, i32 {m.group(3)})"
    out, n = re.subn(r"call void @cqrt_copy_i32_controlled\(i32 (%\S+), i32 (%\S+), i32 (%\S+)\)", rep, ir)
    return out if n == 2 else None

MUT = [("a_uncontrolled_ry_on_cond", m_ry_on_cond),
       ("b_cqrt_x_on_user_register", m_x_on_user),
       ("c_extra_free_of_prepped_rail", m_extra_free),
       ("d_controlled_ctl_target_swapped", m_swap_ctl),
       ("e_peeled_mux_copies_swapped", m_swap_copies)]

fixtures = sys.argv[1:]
tot = missed = na = 0
for fx in fixtures:
    src = open(fx).read()
    pfx = prefixes(src)
    ir = lower(fx)
    base = [p for p in pfx if not check(fx, ir, p)]
    print(f"\n== {os.path.basename(fx)}   prefixes={len(pfx)} {pfx}")
    if base:
        print(f"   !! DIRTY — unmutated stream already fails: {base}")
    for name, fn in MUT:
        mir = fn(ir)
        if mir is None or mir == ir:
            print(f"   {name:34s} n/a (shape absent)"); na += 1; continue
        tot += 1
        caught = [p for p in pfx if not check(fx, mir, p)]
        if caught:
            print(f"   {name:34s} CAUGHT by {caught}")
        else:
            print(f"   {name:34s} *** MISSED ***"); missed += 1
print(f"\nfixtures={len(fixtures)} mutations={tot} MISSED={missed} n/a={na}")
