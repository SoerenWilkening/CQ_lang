#!/usr/bin/env python3
"""Measure the 183 math.h cells with runtime operands and every C/Q mixture.

Preserves historical constant-probe artifacts. Output is pipeline acceptance,
not numerical or unitary verification; no new goldens are blessed. Requires a
faithful OpenLibm bitcode corpus built by full_surface/build_corpus.py.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import itertools
import json
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


def measure(cell, defmap, cq_shims, evidence_dir):
    src, main = source(cell)
    row = {k: cell[k] for k in ('cell', 'name', 'mix')}
    row.update(source_sha256=hashlib.sha256(src.encode()).hexdigest(),
               status='harness-error', cq_dependencies=[], diagnostic='')
    provider = 'macro' if cell['macro'] else 'source-injected'
    if cell['base'] in WP.HARDWARE_KEEPS or cell.get('native_fmod'):
        provider = 'intrinsic'
    if cell['name'] in cq_shims.values():
        provider = 'CQ-provided'
    if cell['base'] == 'nan':
        provider = 'classical-only'
    row['provider'] = provider
    try:
        with tempfile.TemporaryDirectory(prefix='cq_runtime_census_') as td:
            wd = Path(td)
            (wd/'probe.c').write_text(src)
            (wd/'main.c').write_text(main)
            flags = [] if provider in ('intrinsic', 'macro') else [
                '-fno-builtin', '-fno-builtin-' + cell['name']]
            r = run([WP.CLANG, '-O1', '-g', *flags, '-I', ROOT/'include',
                     '-emit-llvm', '-c', wd/'probe.c', '-o', wd/'probe.bc'])
            if r.returncode:
                row.update(status='build-fail', diagnostic=r.stderr)
                return row
            linkset = []
            linked, err = WP.closure_link(wd/'probe.bc', defmap, wd, linkset)
            if linked is None:
                row.update(status='link-fail', diagnostic=err)
                return row
            row['cq_dependencies'] = sorted({cq_shims[str(x)] for x in linkset
                                              if str(x) in cq_shims})
            ir = run([WP.DIS, linked, '-o', '-']).stdout
            # Preserve the externally observable lgamma output, even when the
            # historical harness would internalize and dead-store-eliminate it.
            public = 'probe,signgam' if re.search(r'^@signgam\s*=', ir, re.M) else 'probe'
            row['preserved_signgam'] = public != 'probe'
            r = run([WP.OPT, '-passes=internalize,always-inline,globaldce,default<O1>,scalarizer,instcombine,dce',
                     '-internalize-public-api-list=' + public, '-inline-threshold=2000000',
                     linked, '-o', wd/'inl.bc'])
            if r.returncode:
                row.update(diagnostic=r.stderr)
                return row
            ir = run([WP.DIS, wd/'inl.bc', '-o', '-']).stdout
            row['intrinsics'] = sorted(set(re.findall(r'@llvm\.([\w.]+)\(', ir)))
            row['raw_callees'] = sorted({x for x in re.findall(r'call[^@\n]*@([\w.$]+)', ir)
                                         if not x.startswith(('cq_', 'llvm.'))})
            r = run([WP.OPT, '-load-pass-plugin', WP.PASS, '-passes=cq-lowering',
                     '-S', wd/'inl.bc', '-o', wd/'low.ll'])
            if r.returncode:
                row.update(status='decline' if r.returncode == 1 else 'compiler-crash',
                           diagnostic=r.stderr)
                return row
            low = (wd/'low.ll').read_text()
            row['spec_clone'] = '@__cq_q_' in low
            low_calls = set(re.findall(r'call[^@\n]*@([\w.$]+)', low))
            surviving = sorted(set(row['raw_callees']) & low_calls)
            if 'Q' in cell['mix'] and surviving:
                row.update(status='unlowered-call', diagnostic=str(surviving))
                return row
            r = run([WP.CLANG, '-O0', wd/'low.ll', wd/'main.c',
                     ROOT/'build/runtime/libcq_templates.a', ROOT/'build/runtime/libcq_runtime.a',
                     '-lm', '-o', wd/'probe'])
            if r.returncode:
                row.update(status='runtime-link-fail', diagnostic=r.stderr)
                return row
            r = run([wd/'probe'])
            if r.returncode:
                row.update(status='runtime-fail', diagnostic=r.stderr)
                return row
            row['trace_sha256'] = hashlib.sha256(r.stdout.encode()).hexdigest()
            row['trace_lines'] = len(r.stdout.splitlines())
            # Structural discharge is evidence, not a substitute for a unitary
            # proof or a current golden for every runtime parameter mixture.
            r = run([sys.executable, ROOT/'tools/free_pairing_check.py', '--stats', '-q', wd/'low.ll'])
            row['free_check_exit'] = r.returncode
            row['free_check'] = r.stdout.strip() + r.stderr.strip()
            row['status'] = 'COMPILES'
            if evidence_dir:
                dest = evidence_dir/(cell['cell']+'-'+cell['mix'])
                dest.mkdir(parents=True, exist_ok=True)
                for name in ('probe.c', 'low.ll'):
                    (dest/name).write_text((wd/name).read_text())
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
    lines = ['# Runtime-operand census', '',
             f"**{covered}/{total} cells have pipeline acceptance for every runtime C/Q mixture.**", '',
             'This counts build, lowering, link and trace-run success. It does not certify numerical',
             'or unitary semantics. CQ-provided leaf range contracts remain pending. No new goldens were blessed.', '',
             '| Provider | Accepted for every mixture | Cells |', '| --- | ---: | ---: |']
    for provider, tally in score.items():
        lines.append(f"| {provider} | {tally['covered']} | {tally['total']} |")
    accepted = sum(r['status'] == 'COMPILES' for r in rows)
    checks = sum(r.get('free_check_exit') == 0 for r in rows)
    lines += ['', f"Measured {len(rows)} probes: {accepted} accepted; {len(rows)-accepted} did not accept.",
              f"Structural free-check passes: {checks}. Classical-only nan accounting is separate.",
              'The macro cells retain the historical f64 scope of the 183-cell model.', '',
              '## Reproduction', '', '```sh',
              'git clone https://github.com/JuliaMath/openlibm.git /private/tmp/cq-northstar-openlibm',
              'git -C /private/tmp/cq-northstar-openlibm checkout ' + data['metadata']['openlibm_commit'],
              'python3 tools/library_coverage/full_surface/build_corpus.py --openlibm /private/tmp/cq-northstar-openlibm --out /private/tmp/cq-northstar-bc --expect-bc 252',
              'BC=/private/tmp/cq-northstar-bc OPENLIBM=/private/tmp/cq-northstar-openlibm python3 tools/library_coverage/runtime_census.py '
              + ('--native-fmod ' if data['metadata']['fmod_policy'] == 'Native frem route only' else '')
              + '--output ' + str(path), '```', '',
              'Exact compiler and corpus hashes are in the adjacent JSON metadata. Classical operands',
              'and quantum seeds are function parameters. Pointer outputs are read and explicitly measured;',
              'signgam is preserved through internalization. fenv remains outside the CQ model (CLAUDE R16).', '',
              '## Cells lacking acceptance for every mixture', '',
              '| Cell | Failing mixtures | First diagnostic |', '| --- | --- | --- |']
    groups = {}
    for row in rows:
        groups.setdefault(row['cell'], []).append(row)
    for name, group in groups.items():
        failed = [r for r in group if r['status'] != 'COMPILES']
        if failed:
            diag = failed[0]['diagnostic'].replace('/private/tmp/cq-northstar-openlibm/', 'openlibm/')
            diag = re.sub(r'/private/tmp/cq_runtime_census_[^/]+/', '', diag)
            diag = ' '.join(diag.split()).replace('|', r'\|')
            lines.append(f"| {name} | {', '.join(r['mix'] for r in failed)} | {diag} |")
    path.with_suffix('.md').write_text('\n'.join(lines)+'\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--jobs', type=int, default=6)
    parser.add_argument('--render-existing', action='store_true')
    parser.add_argument('--filter', default='')
    parser.add_argument('--native-fmod', action='store_true',
                        help='Measure builtin fmod -> frem separately, without source injection.')
    parser.add_argument('--evidence-dir', type=Path)
    args = parser.parse_args()
    if args.render_existing:
        render_report(args.output, json.loads(args.output.read_text()))
        return 0
    WP.CENSUS_OPTLEVEL = 'O1'
    if len(list(WP.BC.glob('*.bc'))) != 252:
        parser.error('Expected the faithful 252-file corpus; use build_corpus.py first.')
    defmap = {} if args.native_fmod else WP.build_defmap()
    cq_shims = {} if args.native_fmod else {str(v): k for k, v in WP.cq_provided_shims().items()}
    cells = [c for c in variants() if not args.filter or c['base'] in args.filter.split(',')]
    if args.native_fmod:
        cells = [dict(c, native_fmod=True) for c in cells if c['base'] == 'fmod']
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for row in pool.map(lambda c: measure(c, defmap, cq_shims, args.evidence_dir), cells):
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
    metadata = {'definition': 'Every runtime C/Q mixture builds, lowers, links and trace-runs; not unitary verified.',
                'nan_policy': ('Not part of this native-fmod measurement.' if args.native_fmod else
                               'Three measured classical-only cells; denominator awaits owner ruling.'),
                'fmod_policy': ('Native frem route only' if args.native_fmod else
                                'Real source injection; native frem route reported separately.'),
                'optlevel': 'O1', 'corpus_count': 252,
                'pass_sha256': hashlib.sha256(WP.PASS.read_bytes()).hexdigest(),
                'corpus_sha256': hashlib.sha256(b''.join(
                    p.name.encode() + hashlib.sha256(p.read_bytes()).digest()
                    for p in sorted(WP.BC.glob('*.bc')))).hexdigest(),
                'openlibm_commit': run(['git', '-C', WP.OL, 'rev-parse', 'HEAD']).stdout.strip()}
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
