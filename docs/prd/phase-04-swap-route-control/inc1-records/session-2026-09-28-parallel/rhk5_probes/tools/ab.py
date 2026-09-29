#!/usr/bin/env python3
"""ab.py OPT_A OPT_B [--only lit|e2e|multi|probes] — the bd rhk5 corpus A/B.

Populations (each printed with its OWN denominator):
  lit     every ir-pass/test/*.ll
  e2e     every tests/e2e/*.c at its default CASE and every CASE of a matrix source
          (stage 1 once, `-include CQ.h`); a source that does not compile alone
          (a library TU, or needs another TU) is COUNTED and reported, not swept
  multi   every run_slice_multi.sh registration in tests/e2e/CMakeLists.txt, built
          exactly as that harness builds it (CQ TU with CQ.h, libs without, llvm-link)
  probes  every *.ll / 2-TU *.c pair under the prior review probe dirs this bead
          touches (session-2026-09-25 r2B/r3A/r3B vsfp) and rhk5_probes/src
Per item: opt exit code, stdout sha-256 (16 hex), first `error:` line, and whether
stderr carries a `warning:` (this bead's visible effect is removing a warning).
Mover kinds: D->A, A->D, STRING (both decline, different first error), STREAM
(both accept, different stdout); a WARN-only mover (same stdout, warning moved) is
reported as WARN. A 0-byte stage-1 file is REFUSED (the passthrough vacuity trap).
Workers: 4 (load discipline).
"""
import glob
import hashlib
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
L = '/usr/local/opt/llvm@19/bin'
P25 = W + '/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16'
RHK5 = W + '/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes'
A, B = sys.argv[1], sys.argv[2]
ONLY = sys.argv[sys.argv.index('--only') + 1] if '--only' in sys.argv else None
# RHK5_S1=<dir>: a PERSISTENT stage-1 cache shared by the null run and the real run
# (the stage-1 IR depends only on clang and the sources, never on OPT_A/OPT_B).
T = os.environ.get('RHK5_S1') or tempfile.mkdtemp(prefix='rhk5ab')
os.makedirs(T, exist_ok=True)


def run(opt, s1):
    if os.path.getsize(s1) == 0:
        return ('EMPTY', '', '', False)
    p = subprocess.run([opt, '-passes=cq-lowering', '-S', s1], capture_output=True, timeout=600)
    se = p.stderr.decode(errors='replace')
    err = [l for l in se.splitlines() if 'error:' in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split('error:', 1)[1].strip() if err else '', 'warning:' in se)


def cc(args):
    return subprocess.run([L + '/clang'] + args, capture_output=True).returncode == 0


def build_single(c, defs, tag):
    s1 = os.path.join(T, tag + '.s1.ll')
    if os.path.exists(s1) and os.path.getsize(s1) > 0 and os.path.getmtime(s1) > os.path.getmtime(c):
        return s1
    ok = cc(['-I' + W + '/include', '-include', 'CQ.h', '-O1', '-emit-llvm', '-S', '-Wno-everything']
            + defs + [c, '-o', s1])
    return s1 if ok and os.path.getsize(s1) > 0 else None


def build_multi(c, libs, tag):
    cq = os.path.join(T, tag + '.cq.ll')
    if not cc(['-I' + W + '/include', '-include', 'CQ.h', '-O1', '-emit-llvm', '-S', '-Wno-everything',
               c, '-o', cq]):
        return None
    parts = [cq]
    for i, lib in enumerate(libs):
        o = os.path.join(T, f'{tag}.lib{i}.ll')
        if not cc(['-I' + W + '/include', '-O1', '-emit-llvm', '-S', '-Wno-everything', lib, '-o', o]):
            return None
        parts.append(o)
    s1 = os.path.join(T, tag + '.s1.ll')
    if subprocess.run([L + '/llvm-link', '-S'] + parts + ['-o', s1], capture_output=True).returncode:
        return None
    return s1


def jobs_lit():
    return [('lit:' + os.path.basename(f), f) for f in sorted(glob.glob(W + '/ir-pass/test/*.ll'))]


def jobs_e2e():
    todo = []
    for c in sorted(glob.glob(W + '/tests/e2e/*.c')):
        src = open(c, errors='replace').read()
        cases = sorted(set(int(x) for x in re.findall(r'#define\s+CASE_\w+\s+(\d+)\b', src)))
        variants = [['-DCASE=%d' % k] for k in cases] if cases and '#ifndef CASE' in src else [[]]
        for d in variants:
            todo.append((c, d, os.path.basename(c) + ('' if not d else ':' + d[0][7:])))
    with ThreadPoolExecutor(4) as ex:
        built = list(ex.map(lambda t: (t[2], build_single(t[0], t[1], 'e2e_' + t[2].replace(':', '_'))),
                            todo))
    out = [('e2e:' + tag, s1) for tag, s1 in built if s1]
    return out, len(built) - len(out)


def jobs_multi():
    cm = open(W + '/tests/e2e/CMakeLists.txt').read()
    out, skipped = [], 0
    for m in re.finditer(r'run_slice_multi\.sh"\s*\n(.*?)\)', cm, re.S):
        block = m.group(1)
        paths = re.findall(r'"\$\{CMAKE_CURRENT_SOURCE_DIR\}/([^"]+)"', block)
        srcs = [p for p in paths if p.endswith('.c')]
        libsm = re.search(r'\.c"\s*\n\s*"([^"]*)"\s*\n\s*"\$<TARGET_FILE:cq_runtime>', block)
        if not srcs:
            skipped += 1
            continue
        cqsrc = W + '/tests/e2e/' + srcs[0]
        libs = []
        if libsm and libsm.group(1).strip():
            libs = [W + '/tests/e2e/' + os.path.basename(x.replace('${CMAKE_CURRENT_SOURCE_DIR}/', ''))
                    for x in libsm.group(1).split()]
        tag = os.path.basename(cqsrc)
        s1 = build_multi(cqsrc, libs, 'multi_' + tag)
        if s1:
            out.append(('multi:' + tag, s1))
        else:
            skipped += 1
    return out, skipped


def jobs_probes():
    out, skipped = [], 0
    dirs = [P25 + '/review_r3A_vsfp/probes/src', P25 + '/review_r3B_vsfp/probes/src',
            P25 + '/review_r2B_vsfp/probes/src', RHK5 + '/src']
    for d in dirs:
        rel = os.path.relpath(d, W + '/docs/prd')
        for f in sorted(glob.glob(d + '/*.ll')):
            if '.s2.ll' in f or '.caller.ll' in f or '.lib.ll' in f:
                continue
            if f.endswith('.s1.ll') and os.path.exists(f[:-6] + '.c'):
                continue  # rebuilt from source below
            out.append(('probe:' + rel + '/' + os.path.basename(f), f))
        for c in sorted(glob.glob(d + '/*.c')):
            if c.endswith('.lib.c'):
                continue
            lib = c[:-2] + '.lib.c'
            tag = rel.replace('/', '_') + '_' + os.path.basename(c)
            s1 = build_multi(c, [lib], 'pr_' + tag) if os.path.exists(lib) else \
                build_single(c, [], 'pr_' + tag)
            if s1:
                out.append(('probe:' + rel + '/' + os.path.basename(c), s1))
            else:
                skipped += 1
    return out, skipped


def main():
    pops = []
    if ONLY in (None, 'lit'):
        pops.append(('lit', jobs_lit(), 0))
    if ONLY in (None, 'e2e'):
        j, s = jobs_e2e()
        pops.append(('e2e', j, s))
    if ONLY in (None, 'multi'):
        j, s = jobs_multi()
        pops.append(('multi', j, s))
    if ONLY in (None, 'probes'):
        j, s = jobs_probes()
        pops.append(('probes', j, s))
    print(f'A={A}\nB={B}', flush=True)
    total_mov = 0
    for name, jobs, skipped in pops:
        def one(j):
            tag, s1 = j
            return tag, run(A, s1), run(B, s1)
        with ThreadPoolExecutor(4) as ex:
            res = list(ex.map(one, jobs))
        mov = [(t, a, b) for t, a, b in res if a != b]
        nA = sum(1 for _, a, _ in res if a[0] == 0)
        nB = sum(1 for _, _, b in res if b[0] == 0)
        wA = sum(1 for _, a, _ in res if a[3])
        wB = sum(1 for _, _, b in res if b[3])
        print(f'[{name}] denominator {len(jobs)} swept, {skipped} not buildable alone (NOT swept); '
              f'accepts A={nA} B={nB}; warned A={wA} B={wB}; movers {len(mov)}', flush=True)
        for t, a, b in mov:
            if a[0] != 0 and b[0] == 0:
                kind = 'D->A'
            elif a[0] == 0 and b[0] != 0:
                kind = 'A->D'
            elif a[0] != 0:
                kind = 'STRING'
            elif a[1] != b[1]:
                kind = 'STREAM'
            else:
                kind = 'WARN'
            print(f'  {kind}\t{t}\tA={a}\tB={b}', flush=True)
        total_mov += len(mov)
    print(f'TOTAL movers {total_mov}')


if __name__ == '__main__':
    main()
