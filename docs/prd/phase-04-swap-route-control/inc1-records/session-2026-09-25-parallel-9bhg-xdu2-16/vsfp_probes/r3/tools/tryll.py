#!/usr/bin/env python3
"""tryll.py FILE.ll TAG... : run each binary tag on FILE and print rc, the first error
line, and every call to a user/clone function (not cqrt_/cq_template_)."""
import re
import subprocess
import sys

V = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp'
f = sys.argv[1]
for t in sys.argv[2:]:
    b = f'{V}/../frozen/cq-opt.main_aee8' if t == 'main' else f'{V}/bin/cq-opt.{t}'
    r = subprocess.run([b, '-passes=cq-lowering', '-S', f, '-o', '-'], capture_output=True, text=True)
    err = [l for l in r.stderr.splitlines() if 'error' in l]
    main = re.search(r'^define [^\n]*@main\(.*?^}', r.stdout, re.S | re.M)
    calls = re.findall(r'call \S+ @([\w.]+)\(', main.group(0)) if main else []
    print(f'[{t}] rc={r.returncode} {err[0][-110:] if err else ""} calls={calls}')
