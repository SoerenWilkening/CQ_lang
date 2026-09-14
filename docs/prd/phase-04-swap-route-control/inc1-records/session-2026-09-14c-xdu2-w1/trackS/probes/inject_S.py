#!/usr/bin/env python3
"""Track S injection (mutation) matrix — Rule 12(c), bd `s82e` / owner ruling D4.

For each ACCEPT fixture named on the command line: lower it, apply each mutation
to the LOWERED stream, re-run EVERY FileCheck prefix the fixture declares (with
the RUN line's own flags), and report which prefixes caught it.
MISSED = a mutation no declared prefix rejects.

⚠ THREE L10 LESSONS ARE BUILT IN, because CLAUDE.md records this exact harness
family lying in the MISSED direction three times in one session:
  * NO FIXTURE ARGUMENT => exit non-zero. A matrix that prints
    "0 mutations, MISSED 0" on an empty invocation is reporting a pass on nothing.
  * EVERY MUTATION IS BOUNDED BY THE ENCLOSING `define`. One earlier spelling
    moved a mutation ACROSS A FUNCTION BOUNDARY and scored a false MISSED.
  * A MUTATION THAT DOES NOT APPLY IS `N/A`, AND `N/A` IS A HOLE, NOT A PASS —
    it is printed and counted separately, never folded into MISSED 0.
"""
import re, subprocess, sys, os, tempfile

REPO = "/Users/sorenwilkening/Desktop/CQ_s82e"
FC   = "/usr/local/opt/llvm@19/bin/FileCheck"
OPT  = f"{REPO}/build/ir-pass/cq-opt"
PASS = f"{REPO}/build/ir-pass/libCQPass.so"

def lower(f):
    r = subprocess.run([OPT, "-load-pass-plugin", PASS, "-passes=cq-lowering", "-S", f],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"FIXTURE DOES NOT ACCEPT: {f}\n{r.stderr[:400]}")
    return r.stdout

def prefixes(src):
    out = []
    for m in re.finditer(r"RUN:.*%filecheck\s+%s([^\n]*)", src):
        tail = m.group(1)
        p = re.search(r"--check-prefix=(\S+)", tail)
        extra = re.findall(r"(--implicit-check-not=\S+)", tail)
        out.append((p.group(1) if p else "CHECK", extra))
    # de-duplicate while preserving order (a fixture may FileCheck the same file twice)
    seen, uniq = set(), []
    for p, e in out:
        if (p, tuple(e)) in seen: continue
        seen.add((p, tuple(e))); uniq.append((p, e))
    return uniq

def check(fixture, ir, pfx, extra):
    with tempfile.NamedTemporaryFile("w", suffix=".ll", delete=False) as t:
        t.write(ir); p = t.name
    args = [FC, fixture] + list(extra)
    if pfx != "CHECK":
        args.append(f"--check-prefix={pfx}")
    with open(p) as fh:
        r = subprocess.run(args, stdin=fh, capture_output=True, text=True)
    os.unlink(p)
    return r.returncode == 0

def body_range(lines):
    """[start, end) of the FIRST `define` — every mutation stays inside it."""
    s = next((i for i, l in enumerate(lines) if l.startswith("define ")), None)
    if s is None: return None
    e = next((i for i in range(s, len(lines)) if lines[i].startswith("}")), None)
    return None if e is None else (s + 1, e)

# ── the mutations ───────────────────────────────────────────────────────────
def m_drop_unc(ir):
    """(a) DELETE the first `_unc` adjoint — the discharge the twin emits."""
    lines = ir.split("\n"); r = body_range(lines)
    if not r: return None
    for i in range(*r):
        if "_unc(" in lines[i]:
            del lines[i]; return "\n".join(lines)
    return None

def m_drop_free(ir):
    """(b) DELETE the first `cqrt_free` — Rule 6's pairing, gone."""
    lines = ir.split("\n"); r = body_range(lines)
    if not r: return None
    for i in range(*r):
        if "@cqrt_free(" in lines[i]:
            del lines[i]; return "\n".join(lines)
    return None

def m_sink_discharge(ir):
    """(c) MOVE the first `_unc` to just before the post-loop `ry` — i.e. OUT of
    the loop body, which is precisely the divergence bd `s82e` measures."""
    lines = ir.split("\n"); r = body_range(lines)
    if not r: return None
    src = next((i for i in range(*r) if "_unc(" in lines[i]), None)
    dst = next((i for i in range(*r) if re.search(r"@cqrt_ry_i32\(.*9\.0+e-01", lines[i])), None)
    if src is None or dst is None or src == dst: return None
    g = lines.pop(src)
    dst = dst - 1 if src < dst else dst
    lines.insert(dst, g); return "\n".join(lines)

def m_stray_ry(ir):
    """(d) INJECT an uncontrolled `cqrt_ry` on the user register after the loop."""
    lines = ir.split("\n"); r = body_range(lines)
    if not r: return None
    reg = next((m.group(1) for l in lines[r[0]:r[1]]
                for m in [re.search(r"(%\S+) = call i32 @cqrt_alloc_i32\(", l)] if m), None)
    if reg is None: return None
    for i in range(*r):
        if "@cqrt_measure_i32(" in lines[i]:
            lines.insert(i, f"  call void @cqrt_ry_i32(i32 {reg}, double 1.250000e-01)")
            return "\n".join(lines)
    return None

def m_drop_forward(ir):
    """(e) DELETE the first forward `cq_template_*` mint — the rail itself."""
    lines = ir.split("\n"); r = body_range(lines)
    if not r: return None
    for i in range(*r):
        if re.search(r"= call i32 @cq_template_\w+\(", lines[i]) and "_unc" not in lines[i]:
            del lines[i]; return "\n".join(lines)
    return None

def m_add_discharge(ir):
    """(f) INJECT a `_unc` + `cqrt_free` pair into a fixture that is supposed to
    LEAK. Exercises the pure-negative `LEAK` prefix, whose two `-NOT`s no other
    mutation can reach — the vacuity question for a negative is not "does a
    checker parse it" (the inherited handle-form checker matches NONE of these and
    would print `checked 0`, CLAUDE.md L10) but "can anything make it fail"."""
    lines = ir.split("\n"); r = body_range(lines)
    if not r: return None
    for i in range(*r):
        m = re.search(r"(%\S+) = call i32 @cq_template_lshr_i32_hl\(i32 (%\S+), i32 (\d+)\)", lines[i])
        if m:
            lines.insert(i + 2, f"  call void @cqrt_free(i32 {m.group(1)})")
            lines.insert(i + 2, f"  call void @cq_template_lshr_i32_hl_unc(i32 {m.group(1)}, i32 {m.group(2)}, i32 {m.group(3)})")
            return "\n".join(lines)
    return None

MUTS = [("a_drop_unc", m_drop_unc), ("b_drop_free", m_drop_free),
        ("c_sink_discharge", m_sink_discharge), ("d_stray_ry", m_stray_ry),
        ("e_drop_forward", m_drop_forward),
        ("f_add_discharge", m_add_discharge)]

def main(argv):
    if not argv:
        print("ERROR: no fixture argument. A matrix invoked with nothing to mutate "
              "reports a PASS on nothing (CLAUDE.md L10).", file=sys.stderr)
        return 2
    applied = missed = na = 0
    for fx in argv:
        src = open(fx).read(); pfx = prefixes(src); ir = lower(fx)
        print(f"\n=== {os.path.basename(fx)}  prefixes={[p for p,_ in pfx]}")
        for name, fn in MUTS:
            mut = fn(ir)
            if mut is None or mut == ir:
                print(f"  {name:18s} N/A  (mutation does not apply — A HOLE, not a pass)"); na += 1; continue
            applied += 1
            caught = [p for p, e in pfx if not check(fx, mut, p, e)]
            if caught: print(f"  {name:18s} caught by {caught}")
            else:      print(f"  {name:18s} ** MISSED **"); missed += 1
    print(f"\napplied {applied}, MISSED {missed}, N/A {na}")
    return 0
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
