#!/usr/bin/env python3
"""spec_lock.py [--write] [--spec DIR]: pin CQ_spec and fail loudly on drift.

spec.lock holds the CQ_spec commit and a sha256 per locked file: everything under examples/, plus
CONSTRUCTION_RULES.md, CQ.h, BACKEND_ABI.md and _tools/drivers.txt. The first three are the spec.
BACKEND_ABI.md is non-normative (CONSTRUCTION_RULES.md wins over it) and drivers.txt is input data;
both are locked because we consume them, so a drift in either is a re-pin, not a spec issue.
Without --write it checks that CQ_spec's HEAD is the pinned commit and every locked file hashes as
recorded; any difference exits 1.
--write re-pins to the current state; do that only on a deliberate spec bump.
CQ_spec is read-only: this script never writes there."""
import hashlib, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOCK = ROOT / 'spec.lock'
FILES = ['CONSTRUCTION_RULES.md', 'CQ.h', 'BACKEND_ABI.md', '_tools/drivers.txt']
DIRS = ['examples']
HEADER = ('# CQ_spec pin, written by tools/spec_lock.py --write. Spec: examples/, CONSTRUCTION_RULES.md, CQ.h.\n'
          '# Also locked because we consume them: BACKEND_ABI.md (non-normative, CONSTRUCTION_RULES.md wins over it)\n'
          '# and _tools/drivers.txt (input data). A drift in either of those two is a re-pin, not a spec issue.\n')


def locked_paths(spec):
    paths = [spec / f for f in FILES]
    for d in DIRS:
        paths += sorted(p for p in (spec / d).rglob('*') if p.is_file() and p.name != '.DS_Store')  # Finder metadata, not spec
    return sorted(paths)


def state(spec):
    head = subprocess.run(['git', '-C', str(spec), 'rev-parse', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
    hashes = {str(p.relative_to(spec)): hashlib.sha256(p.read_bytes()).hexdigest() for p in locked_paths(spec)}
    return head, hashes


def main(argv):
    spec = ROOT.parent / 'CQ_spec'
    if '--spec' in argv:
        spec = pathlib.Path(argv[argv.index('--spec') + 1])
    head, hashes = state(spec)
    if '--write' in argv:
        LOCK.write_text(HEADER + f'commit {head}\n' + ''.join(f'{h}  {p}\n' for p, h in sorted(hashes.items())))
        print(f'spec.lock: {head}, {len(hashes)} files')
        return 0
    lines = [l for l in LOCK.read_text().splitlines() if not l.startswith('#')]
    want_head = lines[0].split()[1]
    want = dict(reversed(l.split('  ', 1)) for l in lines[1:])
    errors = []
    if head != want_head:
        errors.append(f'CQ_spec HEAD is {head}, spec.lock pins {want_head}')
    for p in sorted(set(want) | set(hashes)):
        if p not in hashes:
            errors.append(f'missing: {p}')
        elif p not in want:
            errors.append(f'new, not in lock: {p}')
        elif want[p] != hashes[p]:
            errors.append(f'changed: {p}')
    if errors:
        print('SPEC DRIFT (CQ_spec differs from spec.lock):', *errors, sep='\n  ', file=sys.stderr)
        return 1
    print(f'spec.lock OK: {head}, {len(hashes)} files')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
