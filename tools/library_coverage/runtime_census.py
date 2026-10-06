#!/usr/bin/env python3
"""Measure the 183 math.h cells with runtime operands and every C/Q mixture.

Every probe is compiled by tools/cqc, the user-facing driver, so the number is
what a user gets (bd 3c6m.70). Output is pipeline acceptance, not numerical or
unitary verification; no new goldens are blessed.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import itertools
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE / 'full_surface'))
import probe as P
import wprobe as WP

TYPES = {'int': 'int', 'long': 'long', 'ldbl': 'long double', 'str': 'const char *'}
MEASURE = {'float': 'f32', 'double': 'f64', 'long double': 'f80',
           'int': 'si32', 'long': 'sl', 'long long': 'sll'}
WIDTHS = {'f': 'f32', '': 'f64', 'l': 'f80'}


def run(command, timeout=60):
    return subprocess.run([str(x) for x in command], text=True,
                          capture_output=True, timeout=timeout)


def variants():
    for spec in P.MATHH_SPEC:
        for suffix in spec['variants']:
            fp = WP.W[WIDTHS[suffix]][0]
            kinds = spec['args']
            types = [fp if k in ('fp', 'fp*') else TYPES.get(k, 'int') for k in kinds]
            ret = fp if spec['ret'] == 'fp' else {
                'int': 'int', 'long': 'long', 'llong': 'long long'}[spec['ret']]
            mixable = [i for i, k in enumerate(kinds) if not k.endswith('*') and k != 'str']
            for bits in itertools.product('CQ', repeat=len(mixable)):
                yield {'name': spec['base'] + suffix, 'base': spec['base'],
                       'cell': spec['base'] + suffix + '.' + WIDTHS[suffix],
                       'width': WIDTHS[suffix], 'types': types, 'kinds': kinds,
                       'ret': ret, 'macro': 'macro' in spec['flags'],
                       'mix': ''.join(bits) or 'C-only', 'assign': dict(zip(mixable, bits))}


def source(cell):
    params, locals_, args, observations, actuals = [], [], [], [], []
    for i, (kind, ct) in enumerate(zip(cell['kinds'], cell['types'])):
        if kind.endswith('*'):
            locals_.append(f'  {ct} out{i} = 0;')
            args.append(f'&out{i}')
            observations.append(f'  volatile {ct} observed{i} = cq_measure(out{i});')
        else:
            params.append(f'{ct} x{i}')
            if kind == 'str':
                args.append(f'x{i}')
                actuals.append('argc > 1 ? argv[1] : ""')
            else:
                q = cell['assign'][i] == 'Q'
                if q:
                    locals_.append(f'  {ct} q{i} = x{i}; cq_theta(&q{i}, 0.5);')
                args.append(f'q{i}' if q else f'x{i}')
                actuals.append(f'({ct})(argc > {i+1} ? strtod(argv[{i+1}], 0) : {i+2})')
    prototype = ', '.join(params) or 'void'
    argtypes = [ct + (' *' if k.endswith('*') else '')
                for k, ct in zip(cell['kinds'], cell['types'])]
    decl = '' if cell['macro'] else f"extern {cell['ret']} {cell['name']}({', '.join(argtypes)});\n"
    includes = '#include "CQ.h"\n' + ('#include <math.h>\n' if cell['macro'] else '')
    call = f"{cell['name']}({', '.join(args)})"
    body = '\n'.join(locals_ + [f"  {cell['ret']} r = {call};"] + observations
                     + ['  return cq_measure(r);'])
    src = includes + decl + f"{cell['ret']} probe({prototype}) {{\n{body}\n}}\n"
    main = '#include <stdlib.h>\n' + f"extern {cell['ret']} probe({prototype});\n"
    main += f"int main(int argc, char **argv) {{ (void)probe({', '.join(actuals)}); return 0; }}\n"
    return src, main


CQC = ROOT/'tools/cqc'
STAGE_STATUS = {'compile': 'build-fail', 'link-ir': 'link-fail', 'lower': 'decline',
                'link': 'runtime-link-fail'}


def calls_in(ir, fn):
    """Callees inside the body of @fn, minus the CQ runtime, specializer clones and
    debug/lifetime markers. LLVM intrinsics count: without -fno-builtin, cqc's
    `sin(q)` is `@llvm.sin.f64`, and a guard that skipped `llvm.*` was blind to it
    (R17 mutant: cq_theta replaced by freeze, every probe still read COMPILES)."""
    m = re.search(r'^define[^@\n]*@' + re.escape(fn) + r'\(.*?^\}', ir, re.M | re.S)
    body = m.group(0) if m else ''
    return {x for x in re.findall(r'call[^@\n]*@([\w.$]+)', body)
            if not x.startswith(('cq_', 'cqrt_', '__cq_q_', 'llvm.dbg.', 'llvm.lifetime.'))}


def measure(cell, cq_provided, evidence_dir, cqc=CQC):
    src, main = source(cell)
    row = {k: cell[k] for k in ('cell', 'name', 'mix')}
    row.update(source_sha256=hashlib.sha256(src.encode()).hexdigest(),
               status='harness-error', diagnostic='')
    provider = 'macro' if cell['macro'] else 'source-injected'
    if cell['base'] in WP.HARDWARE_KEEPS:
        provider = 'intrinsic'
    if cell['name'] in cq_provided:
        provider = 'CQ-provided'
    if cell['base'] == 'nan':
        provider = 'classical-only'
    row['provider'] = provider
    try:
        with tempfile.TemporaryDirectory(prefix='cq_runtime_census_') as td:
            wd = Path(td)
            (wd/'probe.c').write_text(src)
            (wd/'main.c').write_text(main)
            env = dict(os.environ, LLVM_PREFIX=str(WP.LLVM.parent))
            r = subprocess.run([str(cqc), '-g', '--emit-ll', wd/'probe.c', wd/'main.c',
                                '-o', wd/'probe'], text=True, capture_output=True,
                               timeout=120, env=env)
            if r.returncode:
                stage = re.search(r'cqc: stage ([\w-]+) failed', r.stderr)
                status = STAGE_STATUS.get(stage.group(1), 'harness-error') if stage else 'harness-error'
                if status == 'decline' and re.search(r'Stack dump|PLEASE submit', r.stderr):
                    status = 'compiler-crash'
                row.update(status=status, diagnostic=r.stderr)
                return row
            combined = (wd/'probe.combined.ll').read_text()
            low = (wd/'probe.lowered.ll').read_text()
            row['intrinsics'] = sorted(set(re.findall(r'@llvm\.([\w.]+)\(', combined)))
            row['raw_callees'] = sorted(calls_in(combined, 'probe'))
            row['spec_clone'] = '@__cq_q_' in low
            # A quantum probe's lowered body holds only CQ runtime calls; any
            # surviving callee means a quantum call left the pass unlowered.
            surviving = sorted(calls_in(low, 'probe'))
            if 'Q' in cell['mix'] and surviving:
                row.update(status='unlowered-call', diagnostic=str(surviving))
                return row
            r = run([wd/'probe'])
            if r.returncode:
                row.update(status='runtime-fail', diagnostic=r.stderr)
                return row
            row['trace_sha256'] = hashlib.sha256(r.stdout.encode()).hexdigest()
            row['trace_lines'] = len(r.stdout.splitlines())
            # Structural discharge is evidence, not a substitute for a unitary
            # proof or a current golden for every runtime parameter mixture.
            r = run([sys.executable, ROOT/'tools/free_pairing_check.py', '--stats', '-q',
                     wd/'probe.lowered.ll'])
            row['free_check_exit'] = r.returncode
            row['free_check'] = r.stdout.strip() + r.stderr.strip()
            row['status'] = 'COMPILES'
            if evidence_dir:
                dest = evidence_dir/(cell['cell']+'-'+cell['mix'])
                dest.mkdir(parents=True, exist_ok=True)
                (dest/'probe.c').write_text(src)
                (dest/'low.ll').write_text(low)
    except subprocess.TimeoutExpired as e:
        row.update(status='timeout', diagnostic=' '.join(map(str, e.cmd)))
    except Exception as e:
        row.update(status='harness-error', diagnostic=str(e))
    return row


def render_report(path, data):
    rows, score = data['results'], data['score']
    scalar = {p: t for p, t in score.items() if p != 'classical-only'}
    covered = sum(t['covered'] for t in scalar.values())
    total = sum(t['total'] for t in scalar.values())
    lines = ['# math.h coverage through cqc', '',
             f"**{covered}/{total} scalar-input cells compile through `tools/cqc` for every runtime C/Q mixture.**", '',
             'Each probe is compiled by the user-facing driver `tools/cqc`, so this is the number a user',
             'gets. It counts build, lowering, link and trace-run success. It does not certify numerical',
             'or unitary semantics. No new goldens were blessed.', '',
             '| Provider | Accepted for every mixture | Cells |', '| --- | ---: | ---: |']
    for provider, tally in score.items():
        lines.append(f"| {provider} | {tally['covered']} | {tally['total']} |")
    accepted = sum(r['status'] == 'COMPILES' for r in rows)
    checks = sum(r.get('free_check_exit') == 0 for r in rows)
    lines += ['', f"Measured {len(rows)} probes: {accepted} accepted; {len(rows)-accepted} did not accept.",
              f"Structural free-check passes: {checks}. The classical-only nan row is not in the scalar total.",
              'The macro cells retain the historical f64 scope of the 183-cell model.', '',
              '## Reproduction', '', '```sh',
              'cmake --build build -j8',
              'python3 tools/library_coverage/runtime_census.py --output ' + str(path), '```', '',
              'Driver, pass and LLVM hashes are in the adjacent JSON metadata. Classical operands and',
              'quantum seeds are function parameters. Pointer outputs are read and explicitly measured.',
              'fenv remains outside the CQ model (CLAUDE R16).', '',
              '## Cells lacking acceptance for every mixture', '',
              '| Cell | Failing mixtures | First diagnostic |', '| --- | --- | --- |']
    groups = {}
    for row in rows:
        groups.setdefault(row['cell'], []).append(row)
    for name, group in groups.items():
        failed = [r for r in group if r['status'] != 'COMPILES']
        if failed:
            diag = next((l for l in failed[0]['diagnostic'].splitlines() if 'error' in l),
                        failed[0]['diagnostic'])
            diag = re.sub(r'/private/tmp/cq_runtime_census_[^/]+/', '', diag)
            diag = re.sub(r'/(?:private/)?var/folders/\S*?cq_runtime_census_[^/]+/', '', diag)
            diag = ' '.join(diag.split()).replace('|', r'\|')
            lines.append(f"| {name} | {', '.join(r['mix'] for r in failed)} | {diag} |")
    path.with_suffix('.md').write_text('\n'.join(lines)+'\n')


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=6)
    parser.add_argument('--render-existing', action='store_true')
    parser.add_argument('--filter', default='')
    parser.add_argument('--cqc', type=Path, default=CQC,
                        help='Driver to measure (default tools/cqc; a mutant for R17 checks).')
    parser.add_argument('--evidence-dir', type=Path)
    args = parser.parse_args()
    if args.render_existing:
        render_report(args.output, json.loads(args.output.read_text()))
        return 0
    cq_provided = set(P.cq_provided_cells())
    cells = [c for c in variants() if not args.filter or c['base'] in args.filter.split(',')]
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for row in pool.map(lambda c: measure(c, cq_provided, args.evidence_dir, args.cqc), cells):
            results.append(row)
            print(row['cell'], row['mix'], row['status'], flush=True)
    groups = {}
    for row in results:
        groups.setdefault(row['cell'], []).append(row)
    tally = {}
    for rows in groups.values():
        provider = rows[0]['provider']
        t = tally.setdefault(provider, {'covered': 0, 'total': 0})
        t['total'] += 1
        t['covered'] += all(r['status'] == 'COMPILES' for r in rows)
    metadata = {'definition': 'Every runtime C/Q mixture builds, lowers, links and trace-runs '
                              'through tools/cqc; not unitary verified.',
                'driver': str(args.cqc.resolve().relative_to(ROOT)) if args.cqc.resolve().is_relative_to(ROOT)
                          else str(args.cqc),
                'driver_sha256': sha256(args.cqc),
                'pass_sha256': sha256(WP.PASS),
                'cq_commit': run(['git', '-C', ROOT, 'rev-parse', 'HEAD']).stdout.strip(),
                'llvm_version': run([WP.CLANG, '--version']).stdout.splitlines()[0]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    document = {'metadata': metadata, 'score': tally, 'results': results}
    args.output.write_text(json.dumps(document, indent=2)+'\n')
    render_report(args.output, document)
    print(json.dumps(tally, indent=2))
    if any(r['status'] in ('harness-error', 'timeout', 'compiler-crash') for r in results):
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
