#!/usr/bin/env python3
"""Track F injection (mutation) matrix over the NEW ACCEPT fixtures.

A fixture that cannot be made to fail pins nothing (Rule 12(c): validate by
MUTATION and record the MISSED count, never by re-reading the prefixes). Each
mutation is applied to the LOWERED OUTPUT and every RUN-line FileCheck prefix is
re-run against it; a mutation is CAUGHT iff at least one prefix goes red.
It doubles as the vacuity check: a negative that names something the module can
never contain would show up here as a MISSED injection of that very thing.
"""
import re, subprocess, sys, os
R   = "/Users/sorenwilkening/Desktop/CQ_f2phi"
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

# name -> (regex to find an anchor line, what to do)
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
def mut_sub(a, b):
    def f(t):
        return t.replace(a, b, 1) if a in t else None
    return f
def mut_resub(pat, repl):
    """Width-GENERIC regex substitution. Added 2026-09-14 (round-2 doc round):
    M9/M10 were spelled for the i1 bool fixture only and read `N/A` — i.e. HOLE
    — on the i32 round-2 fixtures, and PROTOCOL S3 says a mutator reading N/A is
    a hole, not a pass. `None` when the pattern is absent, exactly as before."""
    def f(t):
        new, n = re.subn(pat, repl, t, count=1, flags=re.M)
        return new if n else None
    return f

# Mutations that are legitimately INAPPLICABLE to a fixture whose shape does not
# contain the construct (as opposed to a harness that cannot reach a construct
# that IS there). Reported as `n/a-shape`, never as a HOLE — collapsing the two
# is how a real hole hides behind a benign one.
SHAPE_SPECIFIC = {"M11 the prep's cancelling Ry loses its sign (additivity broken)"}

MUTS = {
 # the f8eu pattern: an uncontrolled Ry on the CONDITION register after the free
 "M1 uncontrolled ry on the condition register":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)'),
 "M2 extra alloc (breaks ACNT)":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  %inj = call i32 @cqrt_alloc_i32(i32 7)'),
 "M3 extra free (breaks FCNT)":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  call void @cqrt_free(i32 %out3)'),
 "M4 extra x (breaks XCNT)":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  call void @cqrt_x(i32 %h6)'),
 "M5 extra cnot (breaks CNCNT)":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  call void @cqrt_cnot(i32 %h, i32 %h6)'),
 "M6 a cswap appears (pure negative)":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  call void @cqrt_cswap(i32 %h, i32 %h5, i32 %h6)'),
 "M7 an Rz appears (pure negative — the retired tensored gate)":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  call void @cqrt_rz_i1(i32 %h6, double 5.000000e-01)'),
 "M8 a surviving cq_theta intrinsic (pure negative)":
   mut_insert_after(r'^\s*call void @cqrt_free\(i32 %h_cmp\)',
                    '  %inj2 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)'),
 # WIDTH-GENERIC since 2026-09-14: `icmp_sgt_i32_hl_unc` / `ry_i1_controlled`
 # were the bool fixture's spellings and made these two read N/A on every i32
 # accept fixture.
 "M9 the _unc strip deleted":
   mut_delete(r'^\s*call void @cq_template_icmp_\w+_unc'),
 "M10 the controlled-Ry control moved off the flag onto the target":
   mut_resub(r'@cqrt_ry_(\w+)_controlled\(i32 (%\w+), i32 (%\w+),',
             r'@cqrt_ry_\1_controlled(i32 \3, i32 \2,'),
 "M11 the prep's cancelling Ry loses its sign (additivity broken)":
   mut_sub("@cqrt_ry_i1_controlled(i32 %h, i32 %h5, double -5.000000e-01)",
           "@cqrt_ry_i1_controlled(i32 %h, i32 %h5, double 5.000000e-01)"),
 "M12 the flag's free deleted":
   mut_delete(r'^\s*call void @cqrt_free\(i32 %h_cmp\)'),
}

missed = na = tot = 0
# ⚠ AN EMPTY ARGV USED TO PRINT `0 mutations, MISSED 0, N/A 0`, WHICH READS AS A
# PASS. Measured 2026-09-14 (the fix round: the gate was re-run with no fixture
# and reported a clean line). A runner that reports green on no input is the
# PROTOCOL S3 "a named negative can be VACUOUS" hole in a runner's spelling.
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
