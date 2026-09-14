#!/usr/bin/env python3
"""Track W injection (mutation) matrix — bd `test_C_libtooling-wx8g`.

Rule 12: a fixture set is validated by MUTATION, not by re-reading its prefixes.
Each mutation is applied to the LOWERED IR the fixture's RUN line FileChecks; a
mutation no prefix reddens is a MISSED — a hole in that accept's pins.

⚠ PROTOCOL.md S3: "a mutation harness that reports `n/a` is a HOLE, not a pass."
N/A is printed and counted separately, and every N/A is explained in IMPL_W.md.
"""
import re, subprocess, sys, os, tempfile
LLVM='/usr/local/opt/llvm@19/bin'
REPO='/Users/sorenwilkening/Desktop/CQ_wx8g'
FIX=sys.argv[1:]

def prefixes(t):
    p=set(['CHECK'])
    for m in re.finditer(r'--check-prefix=([A-Za-z0-9_]+)', t): p.add(m.group(1))
    return sorted(p)

def lower(f):
    o=subprocess.run([f'{REPO}/build/ir-pass/cq-opt','-load-pass-plugin',
        f'{REPO}/build/ir-pass/libCQPass.so','-passes=cq-lowering','-S',f],
        capture_output=True, text=True)
    return o.stdout if o.returncode==0 else None

def check(fixture, ir, pfx):
    """True == the fixture still PASSES on this IR (mutation NOT caught by pfx)."""
    with tempfile.NamedTemporaryFile('w',suffix='.ll',delete=False) as t:
        t.write(ir); n=t.name
    r=subprocess.run([f'{LLVM}/FileCheck',fixture,f'--check-prefix={pfx}'],
                     stdin=open(n), capture_output=True, text=True)
    os.unlink(n)
    return r.returncode==0

CRY = r'call void @cqrt_ry_(\w+)_controlled\(i32 (%[\w.]+), i32 (%[\w.]+), double ([^)]+)\)'

def m_alloc_hoisted(ir):
    """1. THE CENTRAL CLAUSE-(c2) HAZARD — the per-trip `cqrt_alloc` HOISTED out
       of the loop body to the function entry, so ONE rail is shared by every
       iteration instead of a fresh |SEED> per trip. Structurally plausible (an
       over-eager LICM of a mint with no loop-varying operand) and catastrophic:
       trip 2's `f=0` component then reads a rail trip 1 rotated.

       ⚠ IT MUST PICK AN ALLOC THAT IS *IN* THE LOOP. The first spelling took the
       FIRST `cqrt_alloc` in the module, which on every fixture here is the ENTRY
       block's — so it re-inserted the line where it already was and the harness
       reported `MISSED` (the mutation was a no-op) or `N/A`. A mutation harness
       that lies in the MISSED direction is worse than one that lies in the N/A
       direction, and both were present. An alloc is "in the loop" iff some
       `br label` precedes it (the entry block cannot have one before its own
       instructions)."""
    #
    # ⚠ AND IT MUST BE ASKED PER FUNCTION. The second spelling tested "some `br`
    # precedes this alloc" over the WHOLE MODULE, so in a two-function fixture
    # `@main`'s ENTRY alloc looked in-loop (a `br` from `@slice` precedes it) and
    # the mutation moved it ACROSS a function boundary — invalid IR that FileCheck
    # happily accepts, reported as a MISSED that was the harness's, not the
    # fixture's. Both bounds are now the enclosing `define … { … }`.
    for fm in re.finditer(r'\ndefine [^\n]*\{\n', ir):
        end = ir.find('\n}\n', fm.end())
        if end < 0: continue
        fn = ir[fm.end():end]
        for m in re.finditer(r'\n(\s*(%[\w.]+) = call i32 @cqrt_alloc_\w+\([^)]*\)(?:, !dbg !\d+)?)\n', fn):
            # ⚠ AND THE `br` TEST MUST ALLOW THE FUNCTION'S FIRST LINE, which has
            # no leading newline inside `fn` — the third spelling missed a loop
            # whose entry block is a bare `br label %loop` and reported N/A.
            if not re.search(r'(?:^|\n)\s*br ', fn[:m.start()]):
                continue      # entry-block alloc of THIS function — not per-trip.
            line = m.group(1).strip()
            fn2 = fn[:m.start()] + '\n' + fn[m.end():]
            return ir[:fm.end()] + '  ' + line + '\n' + fn2 + ir[end:]
    return None

def m_cry_uncontrolled(ir):
    """2. the controlled Ry made UNCONTROLLED — the arm fires on both branches."""
    m=re.search(CRY, ir)
    if not m: return None
    return ir.replace(m.group(0),
        f'call void @cqrt_ry_{m.group(1)}(i32 {m.group(3)}, double {m.group(4)})', 1)

def m_cry_swapped(ir):
    """3. CONTROL and TARGET swapped on the controlled Ry — identical symbol
       multiset, a completely different unitary. Invisible to a count-only CHECK."""
    m=re.search(CRY, ir)
    if not m: return None
    return ir.replace(m.group(0),
        f'call void @cqrt_ry_{m.group(1)}_controlled(i32 {m.group(3)}, i32 {m.group(2)}, double {m.group(4)})', 1)

def m_angle_negated(ir):
    """4. the rotation ANGLE sign-flipped."""
    m=re.search(CRY, ir)
    if not m: return None
    a=m.group(4).strip()
    na=a[1:] if a.startswith('-') else '-'+a
    return ir.replace(m.group(0),
        f'call void @cqrt_ry_{m.group(1)}_controlled(i32 {m.group(2)}, i32 {m.group(3)}, double {na})', 1)

def m_x_on_condition_rail(ir):
    """5. an injected `cqrt_x` ON THE CONDITION REGISTER — l4x4.b's
       non-negotiable ("never a `cqrt_x` on a user register"). The control of the
       controlled Ry IS the user's `_Bool`."""
    m=re.search(CRY, ir)
    if not m: return None
    ir2=ir.replace(m.group(0), f'call void @cqrt_x(i32 {m.group(2)})\n  '+m.group(0), 1)
    if '@cqrt_x(' not in ir.split('\ndefine')[0]:
        ir2 += '\ndeclare void @cqrt_x(i32)\n'
    return ir2

def m_free_condition_rail(ir):
    """6. a `cqrt_free` on the CONDITION REGISTER — a dirty free, i.e. a hidden
       measurement that collapses the user's `_Bool` (Rule 6)."""
    m=re.search(CRY, ir)
    if not m: return None
    ir2=ir.replace(m.group(0), m.group(0)+f'\n  call void @cqrt_free(i32 {m.group(2)})', 1)
    if '@cqrt_free(' not in ir.split('\ndefine')[0]:
        ir2 += '\ndeclare void @cqrt_free(i32)\n'
    return ir2

def m_drop_unc(ir):
    """7. one `_unc` DISCHARGE REMOVED — the leak the (c3) escape pair measures
       (19 vs 27 trace lines). Only applies where the body mints template rails."""
    ms=list(re.finditer(r'  call void @cq_template_\w+_unc\([^)]*\)(?:, !dbg !\d+)?\n', ir))
    if not ms: return None
    last=ms[-1]
    return ir[:last.start()]+ir[last.end():]

def m_drop_gate(ir):
    """8. the controlled Ry DELETED outright."""
    m=re.search(r'  '+CRY+r'(?:, !dbg !\d+)?\n', ir)
    if not m: return None
    return ir[:m.start()]+ir[m.end():]

def m_cswap(ir):
    """9. a `cqrt_cswap` injected — the RETIRED swap route (Key Prohibitions)."""
    m=re.search(CRY, ir)
    if not m: return None
    ir2=ir.replace(m.group(0),
        f'call void @cqrt_cswap(i32 {m.group(2)}, i32 {m.group(3)}, i32 {m.group(3)})\n  '+m.group(0), 1)
    return ir2+'\ndeclare void @cqrt_cswap(i32, i32, i32)\n'

MUT=[('alloc-hoisted-out-of-loop',m_alloc_hoisted),
     ('controlled-ry-uncontrolled',m_cry_uncontrolled),
     ('cry-control-target-swapped',m_cry_swapped),
     ('cry-angle-negated',m_angle_negated),
     ('x-on-condition-rail',m_x_on_condition_rail),
     ('free-on-condition-rail',m_free_condition_rail),
     ('unc-discharge-dropped',m_drop_unc),
     ('controlled-ry-deleted',m_drop_gate),
     ('cqrt_cswap-injected',m_cswap)]

tot=miss=skip=0
print(f"{'fixture':<62} {'mutation':<28} verdict")
for f in FIX:
    t=open(f).read(); pfx=prefixes(t); ir=lower(f)
    if ir is None:
        print(f"{os.path.basename(f):<62} -- LOWERING FAILED"); continue
    for name,fn in MUT:
        mut=fn(ir)
        if mut is None or mut==ir:
            skip+=1; print(f"{os.path.basename(f):<62} {name:<28} N/A (shape absent)"); continue
        tot+=1
        caught=[p for p in pfx if not check(f, mut, p)]
        if caught: print(f"{os.path.basename(f):<62} {name:<28} caught by {','.join(caught)}")
        else: miss+=1; print(f"{os.path.basename(f):<62} {name:<28} *** MISSED ***")
print(f"\nTOTAL applied {tot}   MISSED {miss}   N/A {skip}")
