#!/usr/bin/env python3
"""rbattery.py BIN TAG — re-run BOTH Rule-13 round-1 reviewers' probe batteries (copied
verbatim into round2/r1A and round2/r1B/src; the reviewers' own dirs are never written)
through one cq-opt binary BIN, and print one line per probe:

  probe | verdict | warnings | 2b STRICT census | entangle.py Rule-8 findings | trace sha | twin verdict

Stage 1 is the committed `*.s1.ll` (the reviewers' own clang output) or the hand `.ll`.
A module with no `main` links against r1A's `main_slice.c` (`slice(atoi(argv[1]))`);
`a5_weak_twin` also links r1A's `a5_strong_twin.c` (the interposing object — the point of
that probe). Twin equivalence uses tools/trace_twin_equiv.py on BIN's own subject/twin
traces. Output traces under round2/out/<TAG>/. Run argument 5 throughout."""
import hashlib
import os
import re
import resource
import subprocess
import sys

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
L = '/usr/local/opt/llvm@19/bin'
HERE = os.path.dirname(os.path.abspath(__file__))
ENT = os.path.join(HERE, '..', 'tools', 'entangle.py')
EQ = os.path.join(W, 'tools', 'trace_twin_equiv.py')
BIN, TAG = sys.argv[1], sys.argv[2]
OUT = os.path.join(HERE, 'out', TAG)
os.makedirs(OUT, exist_ok=True)

# The nesting-depth probes (r1A's a2_d*/a3_d*) are COMPILE-ONLY: each Bennett level
# doubles the trace (a2_d9's is 140 MB, a2_d12's ~9 GB — measured, and the first
# battery run had to be stopped). For them the question is the opt time and the
# caller's discharge, both visible in the lowered IR.
COMPILE_ONLY = {'a2_d3', 'a2_d6', 'a2_d9', 'a2_d12', 'a3_d6', 'a3_d8', 'a3_d10', 'a3_d12'}
A = os.path.join(HERE, 'r1A')
B = os.path.join(HERE, 'r1B', 'src')
# (name, stage-1 file, twin stage-1 or None, extra C objects to link)
PROBES = []
for n in ['a0_writes_arg', 'a1_name_producer', 'a1b_name_unc', 'a1c_ccopy', 'a1d_direct_evil',
          'a1e_redefine_unc', 'a1f_evil_after_uncompute', 'c1_deadterm_hostile',
          'c2_deadterm_hostile_nomq', 'cyc_self_twin', 'm8_twin_unrecorded_helper',
          'm8_unrecorded_cqrt']:
    PROBES.append(('A:' + n, os.path.join(A, n + '.ll'), None, []))
PROBES.append(('A:a5_weak_twin', os.path.join(A, 'a5_weak_twin.ll'), None,
               [os.path.join(A, 'a5_strong_twin.c')]))
for n in ['a1c_c', 'a2_d3', 'a2_d6', 'a2_d9', 'a2_d12', 'a3_d6', 'a3_d8', 'a3_d10', 'a3_d12',
          'a4_mem', 'a4b_rot', 'd4']:
    PROBES.append(('A:' + n, os.path.join(A, n + '.s1.ll'), None, []))
for n, tw in [('b1_after_ry', 'b1T_after_ry'), ('b2_twoclones', 'b2T_twoclones'),
              ('b3_condcall', 'b3T_condcall'), ('b4_loopcall', 'b4T_loopcall'),
              ('b5_mc_inwindow', 'b5T_mc_inwindow'), ('comp_deadslot', 'compT_deadslot')]:
    PROBES.append(('A:' + n, os.path.join(A, n + '.s1.ll'), os.path.join(A, tw + '.s1.ll'), []))
for n in ['b0', 'b1', 'b14', 'b2', 'b2n', 'b3', 'b4', 'b5', 'b6', 'c1', 'c2', 'c3', 'c4', 'c5',
          'k2x', 'l1', 'l2', 'r2B_g12B', 'r2B_k2', 'r2B_k2F', 'r2B_k2T', 'v1', 'z1', 'z2']:
    tw = os.path.join(B, n + '_T.s1.ll')
    PROBES.append(('B:' + n, os.path.join(B, n + '.s1.ll'), tw if os.path.exists(tw) else None, []))


def objs(extra):
    res = []
    for c in extra:
        o = os.path.join(OUT, os.path.basename(c) + '.o')
        if not os.path.exists(o):
            subprocess.run([L + '/clang', '-O0', '-Wno-everything', '-c', c, '-o', o], check=True)
        res.append(o)
    return res


def side(tag, s1, extra):
    if not os.path.exists(s1) or os.path.getsize(s1) == 0:
        return {'v': 'EMPTY-INPUT'}
    base = os.path.join(OUT, tag.replace(':', '_'))
    s2 = base + '.s2.ll'
    t0 = resource.getrusage(resource.RUSAGE_CHILDREN).ru_utime
    try:
        p = subprocess.run([BIN, '-passes=cq-lowering', '-S', s1, '-o', s2], capture_output=True,
                           text=True, timeout=1800)
    except subprocess.TimeoutExpired:
        return {'v': 'TIMEOUT'}
    ut = resource.getrusage(resource.RUSAGE_CHILDREN).ru_utime - t0
    r = {'warn': p.stderr.count('warning:')}
    if p.returncode != 0:
        e = next((l.split('error:', 1)[1].strip() for l in p.stderr.splitlines() if 'error:' in l), '')
        r['v'] = f'DECLINE rc={p.returncode} {e[:70]}'
        return r
    fp = subprocess.run(['python3', W + '/tools/free_pairing_check.py', s2], capture_output=True, text=True)
    m = re.search(r'template rail mint\(s\) of which (\d+) left dirty.*?(\d+) verified, (\d+) violation\(s\), (\d+) unproven',
                  fp.stdout)
    r['2b'] = f'dirty={m.group(1)} viol={m.group(3)} unpr={m.group(4)}' if m else 'NO-CENSUS'
    if tag.split(':', 1)[1] in COMPILE_ONLY:
        ir = open(s2).read()
        body = ir[ir.find('@main('):]
        body = body[:body.find('\n}')]
        n = len(re.findall(r'call void @cq_template_\w+_unc', body))
        r['v'] = 'ACCEPT'
        r['compile_only'] = f'opt-user={ut:.2f}s uncs-in-main={n}'
        return r
    ex = [] if re.search(r'define [^@]*@main\(', open(s2).read()) else objs([os.path.join(A, 'main_slice.c')])
    ex += objs(extra)
    exe = base + '.exe'
    o = base + '.o'
    c = subprocess.run([L + '/clang', '-Wno-everything', '-c', s2, '-o', o], capture_output=True)
    lk = c if c.returncode else subprocess.run(
        [W + '/build/tests/e2e/cq_link.sh', '-o', exe, o] + ex +
        [W + '/build/runtime/libcq_templates.a', W + '/build/runtime/libcq_runtime.a'], capture_output=True)
    if os.path.exists(o):
        os.unlink(o)
    if lk.returncode:
        r['v'] = 'LINKFAIL'
        return r
    run = subprocess.run([exe, '5'], capture_output=True, text=True)
    os.unlink(exe)
    tr = base + '.trace'
    open(tr, 'w').write(run.stdout)
    r['trace'] = tr
    r['sha'] = hashlib.sha256(run.stdout.encode()).hexdigest()[:10]
    en = subprocess.run(['python3', ENT, '--quiet-controls', tr], capture_output=True, text=True)
    r['r8'] = len(re.findall(r'^\s+!! ', en.stdout, re.M))
    r['v'] = 'ACCEPT'
    return r


def fmt(r):
    if r.get('v') != 'ACCEPT':
        return f"{r.get('v')} warn={r.get('warn', '-')}"
    if 'compile_only' in r:
        return f"ACCEPT warn={r['warn']} {r['2b']} {r['compile_only']} (compile only)"
    return f"ACCEPT warn={r['warn']} {r['2b']} r8={r['r8']} trace={r['sha']}"


for name, s1, tw, extra in PROBES:
    a = side(name, s1, extra)
    line = f'{name:32s}| {fmt(a)}'
    if tw:
        b = side(name + '_TWIN', tw, extra)
        ev = 'n/a'
        if a.get('v') == 'ACCEPT' and b.get('v') == 'ACCEPT':
            e = subprocess.run(['python3', EQ, '--quiet-controls', a['trace'], b['trace']],
                               capture_output=True, text=True)
            ev = e.stdout.strip().splitlines()[-1].split(': ', 1)[-1].split(' (')[0]
        line += f' || twin: {fmt(b)} || {ev}'
    print(line, flush=True)
