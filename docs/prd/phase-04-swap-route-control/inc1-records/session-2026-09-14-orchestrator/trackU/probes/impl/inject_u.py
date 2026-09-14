#!/usr/bin/env python3
"""Track U injection (mutation) matrix — bd z9t1.

Rule 12: a fixture set is validated by MUTATION, not by re-reading the prefixes.
Each mutation is applied to the LOWERED IR the fixture's RUN line FileChecks; a
mutation that no prefix reddens is a MISSED — a hole in the accept's pins.

DERIVED from `$PREV/trackM/probes/impl/inject.py` (Rule 14 — the generic gate
mutations are that file's, verbatim, with REPO retargeted). THREE mutations are
new and they are the ones that matter for this change, because they are the
failure modes the RULE itself could have:

  * `seed-reverted-to-undef`  — the normalizer silently stops firing. Every
    accept must catch this or its NOUNDEF prefix is theatre.
  * `seed-value-flipped`      — the normalizer fires but picks a value other
    than zero. This is the oracle's own observed failure (`cqrt_alloc_i1(1)`,
    a value the program never wrote), so a fixture that cannot see it pins
    nothing about WHICH constant was chosen.
  * `controlled-angle-sign-flipped` — the additivity spelling of a negated
    controlled Ry (`ry(θ); ry_controlled(−θ)`) inverted into `+θ`, i.e. the arm
    fired on the wrong branch. Same symbol multiset, opposite unitary.
"""
import re, subprocess, sys, os, tempfile
LLVM='/usr/local/opt/llvm@19/bin'
REPO='/Users/sorenwilkening/Desktop/CQ_undef'
FIX=sys.argv[1:]

def prefixes(t):
    """prefix -> the EXTRA FileCheck flags its own RUN line carries.

    *** THE HARNESS MUST REPRODUCE THE RUN LINE, NOT JUST ITS PREFIX. *** The
    first version of this file invoked `FileCheck <fixture> --check-prefix=X` and
    dropped everything else on the line — and it then reported 45 MISSED against
    fixtures whose `--implicit-check-not` DOES catch every one of them (verified
    by hand, exit 1). A harness that runs a weaker command than lit does is not a
    measurement of the fixtures; it is a measurement of itself (PROTOCOL S3: a
    mutation harness that reports the wrong thing is a HOLE, not a pass)."""
    runs=[]
    cur=None
    for line in t.splitlines():
        m=re.match(r';\s*RUN:\s?(.*)$', line)
        if m is None:
            continue
        body=m.group(1).rstrip()
        if cur is None: cur=body
        else: cur=cur+' '+body
        if cur.endswith('\\'): cur=cur[:-1]; continue
        runs.append(cur); cur=None
    out={}
    for r in runs:
        if '%filecheck' not in r: continue
        pm=re.search(r'--check-prefix=([A-Za-z0-9_]+)', r)
        pfx=pm.group(1) if pm else 'CHECK'
        extra=[]
        for im in re.finditer(r"--implicit-check-not=('[^']*'|\"[^\"]*\"|\S+)", r):
            v=im.group(1)
            if v[:1] in "'\"" and v[:1]==v[-1:]: v=v[1:-1]
            extra.append('--implicit-check-not='+v)
        out[pfx]=extra
    if not out: out['CHECK']=[]
    return out

def lower(f):
    o=subprocess.run([f'{REPO}/build/ir-pass/cq-opt','-load-pass-plugin',
        f'{REPO}/build/ir-pass/libCQPass.so','-passes=cq-lowering','-S',f],
        capture_output=True, text=True)
    return o.stdout if o.returncode==0 else None

def check(fixture, ir, pfx, extra):
    """True == the fixture still PASSES on this IR (mutation NOT caught by pfx)."""
    with tempfile.NamedTemporaryFile('w',suffix='.ll',delete=False) as t:
        t.write(ir); n=t.name
    r=subprocess.run([f'{LLVM}/FileCheck',fixture,f'--check-prefix={pfx}']+extra,
                     stdin=open(n), capture_output=True, text=True)
    os.unlink(n)
    return r.returncode==0

# --- the three z9t1-specific mutations ---------------------------------------
UNDEF={'i1':'i1 undef','i8':'i8 undef','i16':'i16 undef','i32':'i32 undef',
       'i64':'i64 undef','f16':'half undef','f32':'float undef',
       'f64':'double undef','f80':'x86_fp80 undef'}
ZERO={'i1':'i1 false','i8':'i8 0','i16':'i16 0','i32':'i32 0','i64':'i64 0',
      'f16':'half 0xH0000','f32':'float 0.000000e+00','f64':'double 0.000000e+00',
      'f80':'x86_fp80 0xK00000000000000000000'}
ONE={'i1':'i1 true','i8':'i8 1','i16':'i16 1','i32':'i32 1','i64':'i64 1',
     'f16':'half 0xH3C00','f32':'float 1.000000e+00','f64':'double 1.000000e+00',
     'f80':'x86_fp80 0xK3FFF8000000000000000'}

def _alloc_sites(ir):
    return list(re.finditer(r'call i32 @cqrt_alloc_(\w+)\(([^)]*)\)', ir))

def m_seed_undef(ir):
    """1. THE RULE STOPS FIRING: a normalized seed reverted to `undef`."""
    for m in _alloc_sites(ir):
        w=m.group(1)
        if w in ZERO and m.group(2)==ZERO[w]:
            return ir[:m.start()]+f'call i32 @cqrt_alloc_{w}({UNDEF[w]})'+ir[m.end():]
    return None

def m_seed_flipped(ir):
    """2. THE RULE PICKS THE WRONG VALUE: zero seed -> one. This is literally
       what the oracle's stage-3 materialised (`cqrt_alloc_i1(1)`)."""
    for m in _alloc_sites(ir):
        w=m.group(1)
        if w in ZERO and m.group(2)==ZERO[w]:
            return ir[:m.start()]+f'call i32 @cqrt_alloc_{w}({ONE[w]})'+ir[m.end():]
    return None

def m_ctl_angle_sign(ir):
    """3. THE ADDITIVITY PAIR INVERTED: `ry_controlled(f,h,-θ)` -> `+θ`, i.e.
       the controlled arm fires on the wrong component of the flag."""
    m=re.search(r'call void @cqrt_ry_(\w+)_controlled\(i32 (%[\w.]+), i32 (%[\w.]+), double (-?)([\d.e+-]+)\)', ir)
    if not m: return None
    sign='' if m.group(4)=='-' else '-'
    return ir[:m.start()]+f'call void @cqrt_ry_{m.group(1)}_controlled(i32 {m.group(2)}, i32 {m.group(3)}, double {sign}{m.group(5)})'+ir[m.end():]

# --- the generic gate mutations (Track M's, verbatim) ------------------------
def m_x_on_user(ir):
    """4. an injected `cqrt_x` ON A USER REGISTER (the non-negotiable)."""
    m=re.search(r'call void @cqrt_ry_\w+\(i32 (%[\w.]+), double', ir)
    if not m: return None
    return ir.replace(m.group(0), f'call void @cqrt_x(i32 {m.group(1)})\n  '+m.group(0), 1)

def m_extra_free(ir):
    """5. an extra `cqrt_free` on the ROTATED rail (a dirty free — Rule 6)."""
    m=re.search(r'call void @cqrt_ry_\w+\(i32 (%[\w.]+), double[^)]*\)', ir)
    if not m: return None
    return ir.replace(m.group(0), m.group(0)+f'\n  call void @cqrt_free(i32 {m.group(1)})', 1)

def m_extra_ry(ir):
    """6. an extra UNCONTROLLED `cqrt_ry` on the rail."""
    m=re.search(r'(call void @cqrt_ry_(\w+)\(i32 (%[\w.]+), double[^)]*\))', ir)
    if not m: return None
    return ir.replace(m.group(1), m.group(1)+f'\n  call void @cqrt_ry_{m.group(2)}(i32 {m.group(3)}, double 1.000000e-01)', 1)

def m_cswap(ir):
    """7. a `cqrt_cswap` (the retired route) injected."""
    m=re.search(r'(  call void @cqrt_ry_\w+\(i32 (%[\w.]+), double[^)]*\))', ir)
    if not m: return None
    return ir.replace(m.group(1), f'  call void @cqrt_cswap(i32 {m.group(2)}, i32 {m.group(2)}, i32 {m.group(2)})\n'+m.group(1),1) \
           + '\ndeclare void @cqrt_cswap(i32, i32, i32)\n'

def m_cnot_unbalanced(ir):
    """8. THE CNOT COPY PAIR UNBALANCED (one `cqrt_cnot` removed) — the ancilla
       never returns to |0> and its free is dirty."""
    ms=list(re.finditer(r'  call void @cqrt_cnot\(i32 %[\w.]+, i32 %[\w.]+\)(?:, !dbg !\d+)?\n', ir))
    if len(ms)<2: return None
    last=ms[-1]
    return ir[:last.start()]+ir[last.end():]

def m_copies_swapped(ir):
    """9. THE TWO `copy_<W>_controlled` SWAPPED (polarity) — identical symbol
       multiset, inverted answer; invisible to a count-only CHECK."""
    ms=list(re.finditer(r'  call void @cqrt_copy_(\w+)_controlled\(i32 (%[\w.]+), i32 (%[\w.]+), i32 (%[\w.]+)\)(?:, !dbg !\d+)?\n', ir))
    if len(ms)<2: return None
    a,b=ms[0],ms[1]
    return ir[:a.start()]+b.group(0)+ir[a.end():b.start()]+a.group(0)+ir[b.end():]

def m_extra_measure(ir):
    """10. A MEASUREMENT THE USER DID NOT WRITE (Rule 5, the hard invariant)."""
    m=re.search(r'(  %[\w.]+ = call \w+ @cqrt_measure_(\w+)\(i32 (%[\w.]+)\)(?:, !dbg !\d+)?\n)', ir)
    if not m: return None
    return ir.replace(m.group(1), m.group(1)+f'  %mINJ = call i32 @cqrt_measure_i32(i32 {m.group(3)})\n', 1) \
           + '\ndeclare i32 @cqrt_measure_i32(i32)\n'

MUT=[('seed-reverted-to-undef',m_seed_undef),('seed-value-flipped',m_seed_flipped),
     ('controlled-angle-sign-flipped',m_ctl_angle_sign),('x-on-user-register',m_x_on_user),
     ('extra-free-on-rotated-rail',m_extra_free),('extra-uncontrolled-ry',m_extra_ry),
     ('cqrt_cswap-injected',m_cswap),('cnot-pair-unbalanced',m_cnot_unbalanced),
     ('two-copies-swapped',m_copies_swapped),('extra-measurement',m_extra_measure)]

tot=miss=skip=0
print(f"{'fixture':<58} {'mutation':<30} verdict")
for f in FIX:
    t=open(f).read(); pfx=prefixes(t); ir=lower(f)
    if ir is None: print(f"{os.path.basename(f):<58} -- LOWERING FAILED (decline fixture?)"); continue
    for name,fn in MUT:
        mut=fn(ir)
        if mut is None or mut==ir:
            skip+=1; print(f"{os.path.basename(f):<58} {name:<30} N/A (shape absent)"); continue
        tot+=1
        caught=[p for p in sorted(pfx) if not check(f, mut, p, pfx[p])]
        if caught: print(f"{os.path.basename(f):<58} {name:<30} caught by {','.join(caught)}")
        else: miss+=1; print(f"{os.path.basename(f):<58} {name:<30} *** MISSED ***")
print(f"\nTOTAL applied {tot}   MISSED {miss}   N/A {skip}")
