#!/usr/bin/env python3
"""make_trace.py NN_name [...]: verify, link and run one example; writes traces/NN_name.txt and runs trace_check.
Recipe from README.txt. Old repo runtime + trace_stubs.c supply the symbols."""
import re, sys, subprocess, pathlib, os
HERE = pathlib.Path(__file__).resolve().parent; SPEC = HERE.parent
LLVM = pathlib.Path('/usr/local/opt/llvm@19/bin'); OLD = pathlib.Path.home() / 'Desktop/Projects/CQ_lang'
RT = [str(OLD / 'build/runtime/libcq_templates.a'), str(OLD / 'build/runtime/libcq_runtime.a')]
drivers = {l.split('|')[0]: (l.rstrip('\n').split('|')[1:] + [''])[:3] for l in open(HERE / 'drivers.txt') if '|' in l}
rc_all = 0
def norm_addrs(text):
    """Stack/heap addresses reach the trace as classical i64 operands (examples 84-85: a pointer is an i64 rail, cell
    addresses are classical operands). They differ per run (ASLR), so they are printed as P<n>+<off> relative to the first
    address of each object (a new P<n> when more than 4 KiB from every base seen in the same call)."""
    import re as _re
    bases = []
    def sub(m):
        v = int(m.group(0))
        if v < 1 << 32 or v & (v - 1) == 0 or (v + 1) & v == 0: return m.group(0)   # literals (incl. 2^k, 2^k-1) stay
        for i, b in enumerate(bases):
            if 0 <= v - b < 4096: return f'P{i}+{v - b}' if v != b else f'P{i}'
        bases.append(v); return f'P{len(bases) - 1}'
    out = []
    for line in text.split('\n'):
        if line.startswith('# call:'): bases = []
        out.append(_re.sub(r'(?<![\w.x-])\d{10,}(?![\w.])', sub, line))
    return '\n'.join(out)
for name in sys.argv[1:]:
    base = name.split('_', 1)[1]; d = SPEC / 'examples' / name
    low = d / f'{base}.lowered.ll'
    v = subprocess.run([str(LLVM / 'opt'), '-passes=verify', '-S', str(low), '-o', '/dev/null'], capture_output=True, text=True)
    if v.returncode: print(f'{name}: VERIFY FAILED\n{v.stderr}'); rc_all = 1; continue
    ov = HERE / 'drivers.d' / f'{name}.txt'   # per-example override (parallel work), merged into drivers.txt afterwards
    if ov.exists(): drivers[name] = (ov.read_text().strip().split('|')[1:] + [''])[:3]
    protos, calls, extra = drivers[name]  # extra: optional 4th field, C statements run in main before the calls
    drv = '#include <stdio.h>\n#include <stdlib.h>\nstatic const double coef[4]={1,2,3,4}; static const int icoef[4]={1,2,3,4};\n' + protos + '\n'
    drv += 'int main(void){\n  ' + extra + '\n' + ''.join(f'  puts("# call: {c}"); (void){c};\n' for c in calls.split(';')) + '  return 0; }\n'
    tmp = pathlib.Path(f'/tmp/cq_spec_trace_{name}'); tmp.mkdir(exist_ok=True)   # per example: parallel runs must not share drv.c
    (tmp / 'drv.c').write_text(drv)
    cc = subprocess.run([str(LLVM / 'clang'), '-w', str(low), str(tmp / 'drv.c'), str(HERE / 'trace_stubs.c')] + ([str(HERE / 'stubs.d' / f'{name}.c')] if (HERE / 'stubs.d' / f'{name}.c').exists() else []) + RT + ['-o', str(tmp / 'a.out')], capture_output=True, text=True)
    if cc.returncode: print(f'{name}: LINK FAILED\n{cc.stderr}'); rc_all = 1; continue
    run = subprocess.run([str(tmp / 'a.out')], capture_output=True, text=True)
    out = f'# driver: {calls}\n' + norm_addrs(run.stdout)
    (HERE / 'traces' / f'{name}.txt').write_text(out)
    print(f'{name}: trace {len(out.splitlines())} lines, exit {run.returncode}')
    subprocess.run([sys.executable, str(HERE / 'trace_check.py'), str(HERE / 'traces' / f'{name}.txt')])
sys.exit(rc_all)
