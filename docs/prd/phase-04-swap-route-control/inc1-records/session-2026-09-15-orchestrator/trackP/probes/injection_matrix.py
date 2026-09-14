#!/usr/bin/env python3
"""Track P' (2026-09-15) injection (mutation) matrix over the THREE NEW ACCEPT fixtures.

Adapted from `trackF/probes/injection_matrix.py` (same session). A fixture that
cannot be made to fail pins nothing (Rule 12(c): validate by MUTATION and record
the MISSED count, never by re-reading the prefixes). Each mutation is applied to
the LOWERED OUTPUT and every RUN-line FileCheck prefix is re-run against it; a
mutation is CAUGHT iff at least one prefix goes red. It doubles as the vacuity
check: a negative naming something the module can never contain shows up here as
a MISSED injection of that very thing.

⚠ THE SHARED `vacuity.py` IS NOT CITED (PROTOCOL S3 / bd `test_C_libtooling-jdec`):
it is hardcoded to a dead worktree and matches only handle-form negatives, and
even repaired it would print `checked 0`, which S3 calls a HOLE, not a pass.

⚠ ANCHORS ARE RESPELLED FOR THIS TRACK'S MODULES, and the respelling is the
lesson the F' version carries: an anchor naming `%h_cmp` (the compare fixture's
flag) does not exist in ANY of my three accepts — a φ-conditioned kickback mints
no flag at all — so every mutation keyed on it would read N/A, and a mutator
reading N/A is a HOLE, not a pass. The anchor here is the branch-phase gate
itself, which all three modules emit exactly once.

⚠ `SHAPE_SPECIFIC` vs HOLE: a mutation that is legitimately inapplicable because
the construct is absent from THAT module (the toffoli pair exists only in the
two-leaf tree; `PHI-NOT` cannot be carried by the rolled fixture, whose stream
MUST contain an induction phi) is reported `n/a-shape`. Collapsing that with a
harness that could not reach a construct which IS there is how a real hole hides
behind a benign one.
"""
import re, subprocess, sys, os
R   = "/Users/sorenwilkening/Desktop/CQ_P"
FC  = "/usr/local/opt/llvm@19/bin/FileCheck"
OPT = [R+"/build/ir-pass/cq-opt", "-load-pass-plugin", R+"/build/ir-pass/libCQPass.so",
       "-passes=cq-lowering", "-S"]

def prefixes(fixture):
    out = [None]
    for ln in open(fixture):
        m = re.search(r'--check-prefix=(\w+)', ln)
        if m: out.append(m.group(1))
    return out

def check(fixture, text):
    """True == every prefix still PASSES (the mutation was MISSED)."""
    for p in prefixes(fixture):
        cmd = [FC, fixture] + ([f"--check-prefix={p}"] if p else [])
        r = subprocess.run(cmd, input=text, capture_output=True, text=True)
        if r.returncode != 0:
            return False
    return True

def mut_insert_after(pat, ins):
    def f(t):
        m = re.search(pat, t, re.M)
        if not m: return None
        i = t.index("\n", m.end()) + 1
        return t[:i] + ins + "\n" + t[i:]
    return f
def mut_delete(pat):
    def f(t):
        m = re.search(pat, t, re.M)
        if not m: return None
        return t[:m.start()] + t[t.index("\n", m.end())+1:]
    return f
def mut_resub(pat, repl):
    def f(t):
        new, n = re.subn(pat, repl, t, count=1, flags=re.M)
        return new if n else None
    return f

# The branch-phase gate: present exactly once in every P' accept, whatever the
# condition shape. Everything hangs off it.
ANCHOR = r'^\s*call void @cqrt_rz_i1\(i32 %\w+, double [^)]+\), !cq\.branchphase'

SHAPE_SPECIFIC = {
  "M12 a toffoli of the two rail leaves is deleted",
  "M13 a toffoli's control is moved onto the ancilla it writes",
  "M14 the rolled gate is hoisted out of the loop body",
  "M15 a phi appears (pure negative)",
}

MUTS = {
 "M1 an extra cqrt_x appears (XCNT)":
   mut_insert_after(ANCHOR, '  call void @cqrt_x(i32 %h)'),
 "M2 an extra cqrt_free appears (FCNT)":
   mut_insert_after(ANCHOR, '  call void @cqrt_free(i32 %h1)'),
 "M3 an extra cqrt_alloc appears (ACNT)":
   mut_insert_after(ANCHOR, '  %inj = call i32 @cqrt_alloc_i32(i32 7)'),
 "M4 a SECOND branch phase appears (MDCNT/MDTAG)":
   mut_insert_after(ANCHOR, '  call void @cqrt_rz_i1(i32 %h1, double 1.000000e-01)'),
 "M5 a cswap appears (pure negative)":
   mut_insert_after(ANCHOR, '  call void @cqrt_cswap(i32 %h, i32 %h1, i32 %h1)'),
 "M6 a cnot appears (pure negative)":
   mut_insert_after(ANCHOR, '  call void @cqrt_cnot(i32 %h, i32 %h1)'),
 "M7 a multi-bit cqrt_rz appears (the retired tensored gate)":
   mut_insert_after(ANCHOR, '  call void @cqrt_rz_i32(i32 %h1, double 5.000000e-01)'),
 "M8 a surviving cq_theta intrinsic (pure negative)":
   mut_insert_after(ANCHOR, '  %inj2 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)'),
 "M9 a cq_template_ mint appears (MINT)":
   mut_insert_after(ANCHOR, '  %inj3 = call i32 @cq_template_add_i32_hl(i32 %h1, i32 1)'),
 "M10 the !cq.branchphase tag is dropped (MDTAG)":
   mut_resub(r'(call void @cqrt_rz_i1\(i32 %\w+, double [^)]+\)), !cq\.branchphase !\d+', r'\1'),
 "M11 the controlled prep's control and target are swapped":
   mut_resub(r'@cqrt_ry_(\w+)_controlled\(i32 (%\w+), i32 (%\w+),',
             r'@cqrt_ry_\1_controlled(i32 \3, i32 \2,'),
 "M12 a toffoli of the two rail leaves is deleted":
   mut_delete(r'^\s*call void @cqrt_toffoli\('),
 "M13 a toffoli's control is moved onto the ancilla it writes":
   mut_resub(r'@cqrt_toffoli\(i32 (%\w+), i32 (%\w+), i32 (%\w+)\)',
             r'@cqrt_toffoli(i32 \3, i32 \2, i32 \3)'),
 "M14 the rolled gate is hoisted out of the loop body":
   mut_resub(r'(\n\w+:[^\n]*\n(?:\s*%\w+ = phi i32[^\n]*\n))(\s*call void @cqrt_rz_i1\([^\n]*\n)',
             r"\2\1"),
 "M15 a phi appears (pure negative)":
   mut_insert_after(ANCHOR, '  %injp = phi i32 [ 0, %entry ]'),
 # ⚠ RESPELLED after its first run reported N/A on the two-leaf tree, where the
 # gate fires on the AND ancilla `%g` and not on `%h1`. A mutator reading N/A is a
 # HOLE, not a pass (PROTOCOL S3) — so the target is matched generically and only
 # the DESTINATION is pinned to the condition register.
 "M16 the branch phase fires on the CONDITION register instead of the answer":
   mut_resub(r'call void @cqrt_rz_i1\(i32 %\w+,', r'call void @cqrt_rz_i1(i32 %h,'),
 "M17 the prep's controlled Ry becomes UNCONTROLLED":
   mut_resub(r'call void @cqrt_ry_(\w+)_controlled\(i32 %\w+, i32 (%\w+), (double [^)]+)\)',
             r'call void @cqrt_ry_\1(i32 \2, \3)'),
}

missed = na = tot = 0
# ⚠ AN EMPTY ARGV MUST NOT PRINT A GREEN-LOOKING LINE (the 2026-09-14 hole).
if len(sys.argv) < 2:
    sys.exit("injection_matrix.py: no fixture given — refusing to print a "
             "green-looking line on an empty run. Usage: injection_matrix.py <fixture.ll>...")
for fixture in sys.argv[1:]:
    base = subprocess.run(OPT+[fixture], capture_output=True, text=True)
    if base.returncode != 0:
        print(f"  SKIP (not an accept): {os.path.basename(fixture)}"); continue
    assert check(fixture, base.stdout), "the UNMUTATED fixture must pass"
    print(f"== {os.path.basename(fixture)}")
    for name, f in MUTS.items():
        tot += 1
        t = f(base.stdout)
        if t is None:
            na += 1
            if name in SHAPE_SPECIFIC:
                print(f"   n/a-shape {name}   (the construct is absent from THIS module)")
            else:
                print(f"   N/A     {name}   <<<< HOLE (the harness could not apply it)")
            continue
        if check(fixture, t):
            missed += 1; print(f"   MISSED  {name}   <<<<")
        else:
            print(f"   caught  {name}")
print(f"\ninjection matrix: {tot} mutations, MISSED {missed}, N/A {na}")
