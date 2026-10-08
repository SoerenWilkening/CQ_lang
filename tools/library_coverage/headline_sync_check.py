#!/usr/bin/env python3
"""Every published math.h headline matches the committed cqc census.

The census (`runtime_census.json`) is the one source of the number. `probe.py
render` copies it into the README, COVERAGE.md and coverage/mathh.md, and a census
re-run that was never rendered left those pages 14 cells low at e0af16ed (86/180
vs 100/180) with every gate green (2026-10-08 review, R17). Pure Python over
committed files: no clang, no opt, no plugin.
"""
import argparse
import json
from pathlib import Path
import re
import sys

PAGES = ('README.md', 'tools/library_coverage/COVERAGE.md',
         'tools/library_coverage/coverage/mathh.md',
         'tools/library_coverage/runtime_census.md')
HEADLINE = re.compile(r'\*\*(\d+)/(\d+) scalar-input cells')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    a = ap.parse_args()
    census = json.loads((a.root/'tools/library_coverage/runtime_census.json').read_text())
    scalar = [t for p, t in census['score'].items() if p != 'classical-only']
    want = (sum(t['covered'] for t in scalar), sum(t['total'] for t in scalar))
    bad = []
    for page in PAGES:
        found = [(int(c), int(t)) for c, t in HEADLINE.findall((a.root/page).read_text())]
        if not found:
            bad.append(f'{page}: no headline')
        bad += [f'{page}: {c}/{t}' for c, t in found if (c, t) != want]
    if bad:
        print(f'headline_sync_check: census says {want[0]}/{want[1]}; stale: ' + '; '.join(bad))
        print('  regenerate: python3 tools/library_coverage/probe.py render')
        return 1
    print(f'headline_sync_check: {len(PAGES)} pages match the census ({want[0]}/{want[1]})')
    return 0


if __name__ == '__main__':
    sys.exit(main())
