#!/usr/bin/env python3
"""stopcheck.py: the one acceptance instrument of the stop-removal phase (owner 2026-11-03).

Usage: tools/stopcheck.py [-j N] [-t SECS] [--plugin P] [--all-nonpass | fn...]

For each musl function, take its linked IR from the libc sweep's cache (../wt/musl_sweep/libc_out/run/<fn>/L.ll;
regenerated through libc_sweep.py when missing), run the pass with a time limit (default 60 s; the structural
verifier runs inside the pass) and print one line:
    PASS-LOWER <fn>
    STOP  <fn>  <site file:line>  <message>
    ICE   <fn>  <site file:line>  <message>          (internal error, or a crash with no cq message)
    TIMEOUT <fn>
A summary groups the STOP/ICE rows by site. Exit status 1 if any listed function did not lower.
The plugin defaults to <this repo>/build/pass/libCQLower.so, so a worktree checks its own build.
"""
import argparse, os, re, subprocess, sys, collections, concurrent.futures as cf

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SWEEP = os.environ.get('CQ_MUSL_SWEEP', '/Users/sorenwilkening/Desktop/Projects/wt/musl_sweep')
OUT = os.path.join(SWEEP, 'libc_out')
B = '/usr/local/opt/llvm@19/bin'


def sweep_mod():
    sys.path.insert(0, SWEEP)
    import libc_sweep
    return libc_sweep


def prepare(name):
    """The per-function L.ll: the cached one, else libc_sweep's caller + link + internalize."""
    d = f'{OUT}/run/{name}'
    if os.path.exists(f'{d}/L.ll'):
        return f'{d}/L.ll'
    ls = sweep_mod()
    import json
    protos = json.load(open(f'{OUT}/protos.json'))
    if name not in protos:
        return None
    src, mode, _ = ls.caller(name, protos[name])
    if src is None:
        return None
    os.makedirs(d, exist_ok=True)
    open(f'{d}/c.c', 'w').write(src)
    r = ls.cc([f'{B}/clang', '-std=c11', '-O1', '-w', '-fno-strict-aliasing', '-S', '-emit-llvm', '-target', ls.TRIPLE,
               *ls.CALLER_INC, '-include', f'{ls.SPEC}/CQ.h', f'{d}/c.c', '-o', f'{d}/c.ll'])
    if r.returncode:
        return None
    ls.cc([f'{B}/llvm-link', '-S', f'{d}/c.ll', f'{OUT}/libc.ll', '-o', f'{d}/L.full.ll'])
    full = ls.resolve_aliases(open(f'{d}/L.full.ll').read())
    open(f'{d}/L.full.ll', 'w').write(full)
    keep, prev = [f'sweep_{name}'], None
    while keep != prev:
        prev = list(keep)
        ls.cc([f'{B}/opt', '-S', f'-internalize-public-api-list={",".join(keep)}', '-passes=internalize,globaldce',
               f'{d}/L.full.ll', '-o', f'{d}/L.ll'])
        names = ls.cc(['python3', '-I', f'{SWEEP}/libnames.py', f'{d}/L.ll']).stdout.split()
        for f in names:
            if f not in keep and re.search(rf'^define .*@{re.escape(f)}\(', full, re.M):
                keep.append(f)
    os.remove(f'{d}/L.full.ll')
    return f'{d}/L.ll'


def one(name, plugin, limit):
    ll = prepare(name)
    if ll is None:
        return ('SKIP', name, '-', 'no caller / no definition in the IR build')
    out = ll[:-3] + '.stopcheck.ll'
    try:
        r = subprocess.run(['nice', '-n', '10', f'{B}/opt', f'-load-pass-plugin={plugin}', '-passes=cq-lower',
                            '-cq-k-default=4', '-S', ll, '-o', out], capture_output=True, text=True, timeout=limit)
    except subprocess.TimeoutExpired:
        return ('TIMEOUT', name, '-', f'{limit} s')
    if os.path.exists(out):
        os.remove(out)
    if r.returncode == 0:
        return ('PASS-LOWER', name, '', '')
    err = r.stderr
    m = re.search(r'cq: (unimplemented|internal error): (.*)', err)
    s = re.search(r'^\s*site:\s+(\S+)', err, re.M)
    site = s.group(1) if s else '-'
    if m:
        kind = 'STOP' if m.group(1) == 'unimplemented' else 'ICE'
        msg = m.group(2).strip()
    else:
        # a crash with no cq message: the site is the first frame of the pass in the backtrace
        fr = re.findall(r'^\s*#\d+ 0x[0-9a-f]+ (cq::[^(]*)\(', err, re.M)
        fr = [f for f in fr if 'cq::unimplementedAt' not in f and 'cq::internalErrorAt' not in f]
        site = fr[0].strip()[:90] if fr else '-'
        kind, msg = 'ICE', 'crash in ' + (fr[0].strip()[:90] if fr else '?') + ': ' + ((err.strip().splitlines() or ['?'])[-1][:120])
    return (kind, name, site, msg)


def nonpass():
    rows = [l.rstrip('\n').split('\t') for l in open(f'{SWEEP}/libc_results.tsv') if l.strip()]
    return [r[0] for r in rows if not (r[2] == 'OK' and r[5] == 'PASS') and r[2] not in ('SKIP', 'CALLER')]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('fns', nargs='*')
    ap.add_argument('-j', type=int, default=2)
    ap.add_argument('-t', type=int, default=60)
    ap.add_argument('--plugin', default=f'{REPO}/build/pass/libCQLower.so')
    ap.add_argument('--all-nonpass', action='store_true', help='every function not PASS in the latest libc_results.tsv')
    ap.add_argument('--tsv', help='also write the rows here')
    a = ap.parse_args()
    fns = list(a.fns) + (nonpass() if a.all_nonpass else [])
    if not fns:
        ap.error('no functions')
    if not os.path.exists(a.plugin):
        sys.exit(f'no plugin at {a.plugin}')
    rows = []
    with cf.ThreadPoolExecutor(a.j) as ex:
        for res in ex.map(lambda f: one(f, a.plugin, a.t), fns):
            rows.append(res)
            print('\t'.join(res).rstrip(), flush=True)
    if a.tsv:
        open(a.tsv, 'w').write(''.join('\t'.join(r) + '\n' for r in rows))
    groups = collections.defaultdict(list)
    for k, n, site, msg in rows:
        if k in ('STOP', 'ICE'):
            groups[(k, site, msg.split('\n')[0][:110])].append(n)
    bad = [r for r in rows if r[0] != 'PASS-LOWER']
    print(f'\n== {len(rows) - len(bad)} PASS-LOWER, {sum(r[0]=="STOP" for r in rows)} STOP, '
          f'{sum(r[0]=="ICE" for r in rows)} ICE, {sum(r[0]=="TIMEOUT" for r in rows)} TIMEOUT, '
          f'{sum(r[0]=="SKIP" for r in rows)} SKIP ==')
    for (k, site, msg), ns in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        print(f'{len(ns):3d}  {k:4s} {site}  {msg}\n       {" ".join(ns)}')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
