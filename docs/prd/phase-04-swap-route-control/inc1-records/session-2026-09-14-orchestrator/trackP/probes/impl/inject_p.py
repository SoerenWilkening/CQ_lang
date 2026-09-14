#!/usr/bin/env python3
"""Track P injection (mutation) matrix.

Rule 12: a fixture set is validated by MUTATION, not by re-reading its prefixes.
Each mutation is applied to the LOWERED IR the fixture's RUN line FileChecks; a
mutation that no prefix reddens is a MISSED — a hole in that accept's pins.

⚠ An N/A row is a HOLE in the MATRIX (the shape is absent from that fixture), not
a pass. Both counts are reported (PROTOCOL S3)."""
import re, subprocess, sys, os, tempfile
LLVM = '/usr/local/opt/llvm@19/bin'
REPO = os.environ.get('REPO', os.getcwd())
BUILD = os.environ.get('BUILD', REPO + '/build')
FIX = sys.argv[1:]

def prefixes(t):
    p = {'CHECK'}
    for m in re.finditer(r'--check-prefix=([A-Za-z0-9_]+)', t):
        p.add(m.group(1))
    return sorted(p)

def lower(f):
    o = subprocess.run([f'{BUILD}/ir-pass/cq-opt', '-load-pass-plugin',
                        f'{BUILD}/ir-pass/libCQPass.so', '-passes=cq-lowering', '-S', f],
                       capture_output=True, text=True)
    return o.stdout if o.returncode == 0 else None

def passes(fixture, ir, pfx):
    """True == the fixture still PASSES on this IR (mutation NOT caught by pfx)."""
    with tempfile.NamedTemporaryFile('w', suffix='.ll', delete=False) as t:
        t.write(ir); n = t.name
    r = subprocess.run([f'{LLVM}/FileCheck', fixture, f'--check-prefix={pfx}'],
                       stdin=open(n), capture_output=True, text=True)
    os.unlink(n)
    return r.returncode == 0

def _user_rail(ir):
    """The FIRST allocated rail — always a user register in these fixtures."""
    m = re.search(r'(%[\w.]+) = call i32 @cqrt_alloc_\w+\(', ir)
    return m.group(1) if m else None

def _first_rz(ir):
    return re.search(r'  call void @cqrt_rz_i1\(i32 (%[\w.]+), double ([^)]+)\)([^\n]*)\n', ir)

# ---- the mutations ---------------------------------------------------------
def m_x_on_user(ir):
    """1. an injected `cqrt_x` ON A USER REGISTER — the Rule-7 non-negotiable."""
    h = _user_rail(ir); m = _first_rz(ir)
    if not h or not m: return None
    return ir[:m.start()] + f'  call void @cqrt_x(i32 {h})\n' + ir[m.start():]

def m_extra_free(ir):
    """2. an extra `cqrt_free` on the USER rail — a dirty free (Rule 6)."""
    h = _user_rail(ir); m = _first_rz(ir)
    if not h or not m: return None
    return ir[:m.end()] + f'  call void @cqrt_free(i32 {h})\n' + ir[m.end():]

def m_extra_ry(ir):
    """3. an extra UNCONTROLLED `cqrt_ry` on the user rail (a stray rotation)."""
    h = _user_rail(ir); m = _first_rz(ir)
    if not h or not m: return None
    return ir[:m.start()] + f'  call void @cqrt_ry_i1(i32 {h}, double 1.000000e-01)\n' + ir[m.start():]

def m_cswap(ir):
    """4. a `cqrt_cswap` — the RETIRED route (Key Prohibitions)."""
    h = _user_rail(ir); m = _first_rz(ir)
    if not h or not m: return None
    return (ir[:m.start()] + f'  call void @cqrt_cswap(i32 {h}, i32 {h}, i32 {h})\n'
            + ir[m.start():] + '\ndeclare void @cqrt_cswap(i32, i32, i32)\n')

def m_drop_branchphase(ir):
    """5. THE `!cq.branchphase` RECORD DROPPED from the kickback gate. Without it
       the whole-DAG spine reads `cqrt_rz_i1(f, θ)` as an ordinary in-place
       rotation and emits `cqrt_rz_i1(f, −θ)`, cancelling the user's phase
       EXACTLY — the Rule-13 round-1 CONFIRMED miscompile F-L7-1."""
    m = _first_rz(ir)
    if not m or 'cq.branchphase' not in m.group(3): return None
    return ir[:m.start()] + f'  call void @cqrt_rz_i1(i32 {m.group(1)}, double {m.group(2)})\n' + ir[m.end():]

def m_negate_angle(ir):
    """6. THE KICKBACK ANGLE NEGATED — the wrong branch gets the phase."""
    m = _first_rz(ir)
    if not m: return None
    a = m.group(2).strip()
    a2 = a[1:] if a.startswith('-') else '-' + a
    return ir[:m.start()] + f'  call void @cqrt_rz_i1(i32 {m.group(1)}, double {a2}){m.group(3)}\n' + ir[m.end():]

def m_drop_rz(ir):
    """7. THE KICKBACK GATE REMOVED — the region becomes the identity."""
    m = _first_rz(ir)
    if not m: return None
    return ir[:m.start()] + ir[m.end():]

def m_rz_retargeted(ir):
    """8. THE KICKBACK MOVED OFF ITS ANCILLA ONTO THE USER'S REGISTER. Only
       meaningful where the flag IS an ancilla (a compound tree): the phase then
       rides the register instead of the conjunction, which is a DIFFERENT
       unitary and leaves every count identical."""
    h = _user_rail(ir); m = _first_rz(ir)
    if not h or not m or m.group(1) == h: return None
    return ir[:m.start()] + f'  call void @cqrt_rz_i1(i32 {h}, double {m.group(2)}){m.group(3)}\n' + ir[m.end():]

def m_toffoli_unbalanced(ir):
    """9. THE TOFFOLI PAIR UNBALANCED (the undo removed) — the node ancilla never
       returns to |0> and its free becomes a hidden measurement (Rule 6)."""
    ms = list(re.finditer(r'  call void @cqrt_toffoli\([^\n]*\n', ir))
    if len(ms) < 2: return None
    last = ms[-1]
    return ir[:last.start()] + ir[last.end():]

def m_copies_swapped(ir):
    """10. THE TWO `copy_<W>_controlled` SWAPPED (polarity) — identical symbol
        multiset, INVERTED answer; invisible to a count-only CHECK."""
    ms = list(re.finditer(r'  call void @cqrt_copy_(\w+)_controlled\([^\n]*\n', ir))
    if len(ms) < 2: return None
    a, b = ms[0], ms[1]
    return ir[:a.start()] + b.group(0) + ir[a.end():b.start()] + a.group(0) + ir[b.end():]

def m_drop_control(ir):
    """11. THE PREP's CONTROL DROPPED (`cqrt_ry_i1_controlled` -> `cqrt_ry_i1`).
        The state prep becomes unconditional: the φ then denotes a register the
        condition never gated."""
    m = re.search(r'  call void @cqrt_ry_(\w+)_controlled\(i32 %[\w.]+, i32 (%[\w.]+), double ([^)]+)\)([^\n]*)\n', ir)
    if not m: return None
    return ir[:m.start()] + f'  call void @cqrt_ry_{m.group(1)}(i32 {m.group(2)}, double {m.group(3)}){m.group(4)}\n' + ir[m.end():]

MUT = [('x-on-user-register', m_x_on_user),
       ('extra-free-on-user-rail', m_extra_free),
       ('extra-uncontrolled-ry', m_extra_ry),
       ('cqrt_cswap-injected', m_cswap),
       ('branchphase-record-dropped', m_drop_branchphase),
       ('kickback-angle-negated', m_negate_angle),
       ('kickback-gate-removed', m_drop_rz),
       ('kickback-retargeted-to-user-rail', m_rz_retargeted),
       ('toffoli-pair-unbalanced', m_toffoli_unbalanced),
       ('two-copies-swapped', m_copies_swapped),
       ('prep-control-dropped', m_drop_control)]

tot = miss = skip = 0
print(f"{'fixture':<56} {'mutation':<34} verdict")
for f in FIX:
    t = open(f).read(); pfx = prefixes(t); ir = lower(f)
    if ir is None:
        print(f"{os.path.basename(f):<56} -- LOWERING FAILED (decline fixture?)"); continue
    for name, fn in MUT:
        mut = fn(ir)
        if mut is None or mut == ir:
            skip += 1; print(f"{os.path.basename(f):<56} {name:<34} N/A (shape absent)"); continue
        tot += 1
        caught = [p for p in pfx if not passes(f, mut, p)]
        if caught:
            print(f"{os.path.basename(f):<56} {name:<34} caught by {','.join(caught)}")
        else:
            miss += 1; print(f"{os.path.basename(f):<56} {name:<34} *** MISSED ***")
print(f"\nTOTAL applied {tot}   MISSED {miss}   N/A {skip}")
