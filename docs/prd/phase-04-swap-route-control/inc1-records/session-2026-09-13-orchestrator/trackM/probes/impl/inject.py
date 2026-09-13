#!/usr/bin/env python3
"""Track M injection (mutation) matrix.

Rule 12: a fixture set is validated by MUTATION, not by re-reading the prefixes.
Each mutation is applied to the LOWERED IR the fixture's RUN line FileChecks; a
mutation that no prefix reddens is a MISSED — a hole in the accept's pins."""
import re, subprocess, sys, os, tempfile
LLVM='/usr/local/opt/llvm@19/bin'
REPO='/Users/sorenwilkening/Desktop/CQ_mphi'
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

# --- the seven mutations -----------------------------------------------------
def m_x_on_user(ir):
    """1. an injected `cqrt_x` ON A USER REGISTER (the non-negotiable)."""
    m=re.search(r'call void @cqrt_cnot\(i32 (%[\w.]+), i32 %[\w.]+\)', ir)
    if not m: return None
    return ir.replace(m.group(0), f'call void @cqrt_x(i32 {m.group(1)})\n  '+m.group(0), 1)
def m_extra_free(ir):
    """2. an extra `cqrt_free` on the PREP RAIL (a dirty free — Rule 6)."""
    m=re.search(r'call void @cqrt_cnot\(i32 (%[\w.]+), i32 %[\w.]+\)', ir)
    if not m: return None
    return ir.replace(m.group(0), m.group(0)+f'\n  call void @cqrt_free(i32 {m.group(1)})', 1)
def m_extra_ry(ir):
    """3. an extra UNCONTROLLED `cqrt_ry` on the rail."""
    m=re.search(r'call void @cqrt_cnot\(i32 (%[\w.]+), i32 %[\w.]+\)', ir)
    if not m: return None
    return ir.replace(m.group(0), f'call void @cqrt_ry_i1(i32 {m.group(1)}, double 1.000000e-01)\n  '+m.group(0), 1)
def m_cswap(ir):
    """4. a `cqrt_cswap` (the retired route)."""
    m=re.search(r'(  call void @cqrt_x\(i32 (%[\w.]+)\))', ir)
    if not m: return None
    ir2=ir.replace(m.group(1), f'  call void @cqrt_cswap(i32 {m.group(2)}, i32 {m.group(2)}, i32 {m.group(2)})\n'+m.group(1),1)
    return ir2+'\ndeclare void @cqrt_cswap(i32, i32, i32)\n'
def m_rail_in_imm(ir):
    """5. a rail HANDLE promoted into a CLASSICAL IMMEDIATE slot (the §5.2
       prohibition: never `cqrt_alloc` a classical operand, pass the literal to
       the `_hl`/`_lh` template). Applied to whichever immediate the module has:
       a template's literal, or an allocator's seed."""
    m=re.search(r'(%[\w.]+) = call i32 @(cq_template_\w+_hl)\(i32 (%[\w.]+), i32 (-?\d+)\)', ir)
    if m:
        return ir.replace(m.group(0), f'{m.group(1)} = call i32 @{m.group(2)}(i32 {m.group(3)}, i32 {m.group(3)})', 1)
    m=re.search(r'(%[\w.]+) = call i32 @cqrt_alloc_i32\(i32 (\d+)\)', ir)
    if not m: return None
    prior=re.search(r'(%[\w.]+) = call i32 @cqrt_alloc_i1', ir)
    if not prior: return None
    return None
def m_cnot_unbalanced(ir):
    """6. THE CNOT COPY PAIR UNBALANCED (one `cqrt_cnot` removed) — the ancilla
       then never returns to |0> and its free is dirty."""
    ms=list(re.finditer(r'  call void @cqrt_cnot\(i32 %[\w.]+, i32 %[\w.]+\)(?:, !dbg !\d+)?\n', ir))
    if len(ms)<2: return None
    last=ms[-1]
    return ir[:last.start()]+ir[last.end():]
def m_copies_swapped(ir):
    """7. THE TWO `copy_<W>_controlled` SWAPPED (polarity) — identical symbol
       multiset, inverted answer; invisible to a count-only CHECK."""
    ms=list(re.finditer(r'  call void @cqrt_copy_(\w+)_controlled\(i32 (%[\w.]+), i32 (%[\w.]+), i32 (%[\w.]+)\)(?:, !dbg !\d+)?\n', ir))
    if len(ms)<2: return None
    a,b=ms[0],ms[1]
    return ir[:a.start()]+b.group(0)+ir[a.end():b.start()]+a.group(0)+ir[b.end():]

def m_gate_out_of_loop(ir):
    """8. F-M6 — A GATE MOVED OUT OF THE LOOP BODY. The rolled form's per-trip
       ancilla mint is hoisted to the function entry, so one ancilla is shared by
       every iteration instead of a fresh |0> per trip. Structurally plausible
       (an over-eager LICM of the emitter's own mint) and catastrophic: the second
       trip's copy would read a rail the first trip left dirty."""
    m=re.search(r'\n(\s*%bf[\w.]* = call i32 @cqrt_alloc_i1\(i1 false\)(?:, !dbg !\d+)?)\n', ir)
    if not m: return None
    line=m.group(1).strip()
    ir2=ir[:m.start()]+'\n'+ir[m.end():]
    d=re.search(r'\ndefine [^\n]*\{\n', ir2)
    if not d: return None
    return ir2[:d.end()]+'  '+line+'\n'+ir2[d.end():]

MUT=[('gate-hoisted-out-of-loop',m_gate_out_of_loop),('x-on-user-register',m_x_on_user),('extra-free-on-prep-rail',m_extra_free),
     ('extra-uncontrolled-ry',m_extra_ry),('cqrt_cswap-injected',m_cswap),
     ('rail-handle-in-imm-slot',m_rail_in_imm),('cnot-pair-unbalanced',m_cnot_unbalanced),
     ('two-copies-swapped',m_copies_swapped)]

tot=miss=skip=0
print(f"{'fixture':<58} {'mutation':<26} verdict")
for f in FIX:
    t=open(f).read(); pfx=prefixes(t); ir=lower(f)
    if ir is None: print(f"{os.path.basename(f):<58} -- LOWERING FAILED"); continue
    for name,fn in MUT:
        mut=fn(ir)
        if mut is None or mut==ir:
            skip+=1; print(f"{os.path.basename(f):<58} {name:<26} N/A (shape absent)"); continue
        tot+=1
        caught=[p for p in pfx if not check(f, mut, p)]
        if caught: print(f"{os.path.basename(f):<58} {name:<26} caught by {','.join(caught)}")
        else: miss+=1; print(f"{os.path.basename(f):<58} {name:<26} *** MISSED ***")
print(f"\nTOTAL applied {tot}   MISSED {miss}   N/A {skip}")
