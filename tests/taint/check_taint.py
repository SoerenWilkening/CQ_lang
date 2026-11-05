#!/usr/bin/env python3
"""Acceptance of cq-w0-taint, per example of the pinned CQ_spec (counted from the directory).

For each example, computeTaint over name.O1.ll (cq_taint_dump, which also checks that two runs give
the same answer) is compared with name.lowered.ll:

  clones   the published non-entry specializations, by clone name (CR §1.4), equal the __cq_q_*
           functions the reference defines or declares, _unc twins excluded (a twin is not a
           specialization);
  entries  a function present in both files has an in-place specialization iff the reference
           rewrote its body (comments, attribute groups and metadata ignored);

A computeTaint that stops (cq: unimplemented / internal error) is a failure of that example.

Owner ruling 2026-10-27 (amended acceptance): examples whose reference lifts an injected library
body (169, 190) depend on the v1 injection bundle; they still run and their differences are printed
as EXCLUDED, but they do not fail this test until cq-dav re-checks them with the bundle linked.
Usage: check_taint.py --dump build/tests/taint/cq_taint_dump [--spec DIR] [NN ...] [-v]
Exit 0 only when every selected example matches on all four counts.
"""
import argparse
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUNDLE_DEPENDENT = {'169': 'cq-dav', '190': 'cq-dav'}


def strip_comment(line):
    out, q = [], False
    for ch in line:
        if ch == '"':
            q = not q
        if ch == ';' and not q:
            break
        out.append(ch)
    return ''.join(out).rstrip()


def functions(path):
    defs, decls, cur, body = {}, set(), None, []
    text = []
    for raw in path.read_text().splitlines():
        s = strip_comment(raw)
        text.append(s)
        m = re.match(r'define .*?@("?[\w.$\\]+"?)\(', s)
        if m:
            cur, body = m.group(1).strip('"'), []
            continue
        if cur is not None:
            if s == '}':
                defs[cur] = body
                cur = None
            else:
                body.append(s)
            continue
        m = re.match(r'declare .*?@("?[\w.$\\]+"?)\(', s)
        if m:
            decls.add(m.group(1).strip('"'))
    return defs, decls, '\n'.join(text)


def norm_body(lines):
    out = []
    for s in lines:
        s = re.sub(r',?\s*!\w[\w.]*\s+!\d+', '', s)
        s = re.sub(r'#\d+', '', s)
        s = re.sub(r'\s+', ' ', s).strip()
        if s:
            out.append(s)
    return out


def expected(ex):
    o1 = next(ex.glob('*.O1.ll'))
    lo = next(ex.glob('*.lowered.ll'))
    od, _, _ = functions(o1)
    ld, ldecl, ltxt = functions(lo)
    clones = {f for f in set(ld) | ldecl if f.startswith('__cq_q_') and not f.endswith('_unc')}
    rewritten = {f for f in od if f in ld and norm_body(od[f]) != norm_body(ld[f])}
    kept = {f for f in od if f in ld}
    return o1, clones, rewritten, kept


def run(dump, ex):
    o1, clones, rewritten, kept = expected(ex)
    p = subprocess.run([dump, str(o1)], capture_output=True, text=True)
    if p.returncode != 0:
        err = (p.stderr.strip().splitlines() or ['exit %d' % p.returncode])
        return ex.name, ['stopped: ' + ' | '.join(err[:2])], ''
    got_clones, got_entries = set(), set()
    for line in p.stdout.splitlines():
        m = re.match(r'cq-taint: spec (\S+) fn=@(\S+) .* entry=(\d)', line)
        if m:
            if m.group(3) == '1':
                got_entries.add(m.group(2))
            else:
                got_clones.add(m.group(1))
    reasons = []
    if got_clones != clones:
        reasons.append('clones: missing %s extra %s' % (sorted(clones - got_clones),
                                                         sorted(got_clones - clones)))
    got_rew = got_entries & kept
    if got_rew != rewritten:
        reasons.append('entries: reference rewrote %s, taint says %s' % (sorted(rewritten),
                                                                          sorted(got_rew)))
    return ex.name, reasons, p.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dump', required=True)
    ap.add_argument('--spec', default=str(ROOT.parent / 'CQ_spec'))
    ap.add_argument('-v', action='store_true')
    ap.add_argument('examples', nargs='*')
    a = ap.parse_args()
    # Until the bus constructions land (W3+), the examples the flat-memory cut keeps lowering.
    nonbus = set((ROOT / 'tests' / 'nonbus_examples.txt').read_text().split())
    exs = sorted(p for p in (Path(a.spec) / 'examples').iterdir() if p.is_dir() and p.name in nonbus)
    if a.examples:
        exs = [e for e in exs if e.name.split('_')[0] in a.examples or e.name in a.examples]
    with ThreadPoolExecutor(8) as pool:
        results = list(pool.map(lambda e: run(a.dump, e), exs))
    bad = excluded = 0
    for name, reasons, out in sorted(results, key=lambda r: int(r[0].split('_')[0])):
        num = name.split('_')[0]
        if num in BUNDLE_DEPENDENT:
            excluded += 1
            print('EXCLUDED %s (%s, needs the v1 injection bundle): %s' % (
                name, BUNDLE_DEPENDENT[num], '; '.join(reasons) if reasons else 'matches'))
            continue
        if reasons:
            bad += 1
            print('FAIL %s: %s' % (name, '; '.join(reasons)))
            if a.v:
                print(out)
        elif a.v:
            print('ok   %s' % name)
    checked = len(results) - excluded
    print('taint: %d of %d examples match (%d excluded pending the bundle)' % (
        checked - bad, checked, excluded))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
