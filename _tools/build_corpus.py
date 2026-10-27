#!/usr/bin/env python3
"""build_corpus.py: writes corpus.json for the viewer from examples/ + traces/ (README recipe)."""
import json, pathlib
HERE = pathlib.Path(__file__).resolve().parent; SPEC = HERE.parent
out = []
for d in sorted((SPEC / 'examples').iterdir()):
    if not d.is_dir(): continue
    base = d.name.split('_', 1)[1]
    tr = HERE / 'traces' / f'{d.name}.txt'
    out.append({'name': d.name, 'cname': f'{base}.c', 'irname': f'{base}.O1.ll', 'lowname': f'{base}.lowered.ll',
                'c': (d / f'{base}.c').read_text(), 'ir': (d / f'{base}.O1.ll').read_text(),
                'low': (d / f'{base}.lowered.ll').read_text(), 'trace': tr.read_text() if tr.exists() else ''})
(HERE / 'corpus.json').write_text(json.dumps(out))
print(len(out), 'examples ->', HERE / 'corpus.json')
