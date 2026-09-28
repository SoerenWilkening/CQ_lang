#!/usr/bin/env python3
"""battery.py BIN [ARG] PAIR... — the bd rhk5 twin battery.

For each SUBJ:TWIN pair (stage-1 `.s1.ll` files in src/), lower BOTH with the same
binary BIN (`S` = this worktree's build, `M` = the frozen ORACLE, or a path), run
stage 2b STRICT, link, run with ARG, and report per side:
  verdict (opt exit) | warnings | 2b census (alloc-left, template dirty, violations,
  unproven) | entangle.py Rule-8 findings on the trace
and the pair's trace_twin_equiv.py verdict (EQUIV / DIFF / VACUOUS / refused).

Boundary controls: both instruments run their own controls on every invocation; this
script also refuses a 0-byte `.s1.ll` (the passthrough-ACCEPT vacuity trap).
"""
import os
import re
import subprocess
import sys

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
L = '/usr/local/opt/llvm@19/bin'
ORACLE = ('/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/'
          'e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646')
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'src')
OUT = os.path.join(HERE, '..', 'results', 'battery_out')
EQ = os.path.join(W, 'tools', 'trace_twin_equiv.py')
ENT = os.path.join(HERE, 'entangle.py')


def binpath(b):
    return {'S': os.path.join(W, 'build/ir-pass/cq-opt'), 'M': ORACLE}.get(b, b)


def side(B, tag, name, arg):
    src = os.path.join(SRC, name + '.s1.ll')
    if not os.path.exists(src) or os.path.getsize(src) == 0:
        return {'v': 'EMPTY-INPUT'}
    s2 = os.path.join(OUT, f'{name}.{tag}.s2.ll')
    p = subprocess.run([binpath(B), '-passes=cq-lowering', '-S', src, '-o', s2],
                       capture_output=True, text=True)
    err = p.stderr
    r = {'rc': p.returncode, 'warn': err.count('warning:'),
         'err1': next((l for l in err.splitlines() if 'error' in l), '')}
    if p.returncode != 0:
        r['v'] = 'DECLINE' if p.returncode == 1 else f'rc{p.returncode}'
        return r
    r['v'] = 'ACCEPT'
    fp = subprocess.run(['python3', os.path.join(W, 'tools/free_pairing_check.py'), s2],
                        capture_output=True, text=True)
    m = re.search(r'(\d+) rail mint\(s\) of which (\d+) left allocated, (\d+) template rail '
                  r'mint\(s\) of which (\d+) left dirty.*?(\d+) verified, (\d+) violation\(s\), '
                  r'(\d+) unproven', fp.stdout)
    r['2b'] = (f'left={m.group(2)} dirty={m.group(4)} viol={m.group(6)} unpr={m.group(7)}'
               if m else 'NO-CENSUS:' + fp.stdout[-80:])
    r['2brc'] = fp.returncode
    exe = s2 + '.exe'
    obj = s2 + '.o'
    # the harness's own stage-3 split (bd dgn5): compile, then the derived linker
    # wrapper — templates BEFORE runtime (load-bearing link order).
    cc = subprocess.run([os.path.join(L, 'clang'), '-Wno-everything', '-c', s2, '-o', obj],
                        capture_output=True, text=True)
    lk = cc if cc.returncode != 0 else subprocess.run(
        [os.path.join(W, 'build/tests/e2e/cq_link.sh'), '-o', exe, obj,
         os.path.join(W, 'build/runtime/libcq_templates.a'),
         os.path.join(W, 'build/runtime/libcq_runtime.a')],
        capture_output=True, text=True)
    if os.path.exists(obj):
        os.unlink(obj)
    if lk.returncode != 0:
        r['v'] = 'LINKFAIL'
        return r
    run = subprocess.run([exe, str(arg)], capture_output=True, text=True)
    os.unlink(exe)
    tr = s2 + '.trace'
    open(tr, 'w').write(run.stdout)
    r['trace'] = tr
    r['lines'] = len(run.stdout.splitlines())
    en = subprocess.run(['python3', ENT, '--quiet-controls', tr], capture_output=True, text=True)
    r['r8'] = len(re.findall(r'^\s+!! ', en.stdout, re.M))
    if en.returncode == 2:
        r['r8'] = 'ENT-REFUSED'
    return r


def fmt(r):
    if r.get('v') != 'ACCEPT':
        return f"{r.get('v')} {r.get('err1', '')[-90:]}"
    return (f"ACCEPT warn={r['warn']} {r['2b']} 2brc={r['2brc']} r8={r['r8']} "
            f"lines={r['lines']}")


def main(argv):
    B = argv[1]
    arg = argv[2]
    pairs = argv[3:]
    os.makedirs(OUT, exist_ok=True)
    c = subprocess.run(['python3', EQ, '--selftest'], capture_output=True, text=True)
    if c.returncode != 0:
        print(c.stdout)
        print('!! trace_twin_equiv controls FAILED')
        return 2
    tag = os.path.basename(binpath(B))
    for pr in pairs:
        s, t = pr.split(':')
        a = side(B, tag, s, arg)
        b = side(B, tag, t, arg)
        if a.get('v') == 'ACCEPT' and b.get('v') == 'ACCEPT':
            e = subprocess.run(['python3', EQ, '--quiet-controls', a['trace'], b['trace']],
                               capture_output=True, text=True)
            ev = e.stdout.strip().splitlines()[-1].split(': ', 1)[-1]
        else:
            ev = 'n/a'
        print(f"{s:6s}| S: {fmt(a)}")
        print(f"{'':6s}| T: {fmt(b)}")
        print(f"{'':6s}| TWIN: {ev}")
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
