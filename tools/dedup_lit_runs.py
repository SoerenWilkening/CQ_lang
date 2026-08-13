#!/usr/bin/env python3
"""Deduplicate identical first-stage `opt` spawns inside a lit fixture.

A fixture that runs the byte-identical `%cq-opt ... -passes=cq-lowering -S %s`
two-to-five times, purely to feed a different --check-prefix, pays 0.44s of
libLLVM.dylib startup per repeat and ~0.02s of actual work. Run it ONCE into
%t and let each consumer read that file.

  ; RUN: %cq-opt ... -S %s | %filecheck %s
  ; RUN: %cq-opt ... -S %s | %filecheck %s --check-prefix=CNT
->
  ; RUN: %cq-opt ... -S %s > %t.cqd0.ll
  ; RUN: %filecheck %s < %t.cqd0.ll
  ; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

This is a pure scheduling change: same command, same assertions, same order.
It is also STRICTLY STRONGER — in `A | B` only B's exit code is checked unless
the shell sets pipefail, whereas a separate `A > %t` line always checks A's.

CONSERVATIVE BY CONSTRUCTION. A group is rewritten only when every member
shares a byte-identical pre-pipe segment that:
  - starts with `%cq-opt` (never `not %cq-opt` — decline fixtures are left alone)
  - carries no redirection (> < 2>) and no compound operator (; && || `)
Anything else is skipped untouched.
"""
import glob
import os
import re
import sys

RUN_RE = re.compile(r'^(\s*;\s*RUN:\s?)(.*)$')
UNSAFE = ('>', '<', ';', '&&', '||', '`', '$(')


def parse_runs(lines):
    """-> list of (start_idx, end_idx, joined_command). Handles `\\` continuations."""
    runs, start, buf = [], None, None
    for i, L in enumerate(lines):
        m = RUN_RE.match(L)
        if not m:
            if buf is not None:
                runs.append((start, i - 1, buf))
                start, buf = None, None
            continue
        body = m.group(2)
        if buf is None:
            start, buf = i, body
        else:
            buf = buf + ' ' + body.strip()
        if buf.rstrip().endswith('\\'):
            buf = buf.rstrip()[:-1]
        else:
            runs.append((start, i, buf))
            start, buf = None, None
    if buf is not None:
        runs.append((start, len(lines) - 1, buf))
    return runs


def transform(path, apply_changes):
    text = open(path, encoding='utf-8', errors='surrogateescape').read()
    lines = text.split('\n')
    runs = parse_runs(lines)

    groups = {}
    for idx, (s, e, cmd) in enumerate(runs):
        stripped = cmd.strip()
        if not stripped.startswith('%cq-opt'):
            continue
        if '|' not in stripped:
            continue
        pre = stripped.split('|')[0].strip()
        if any(u in pre for u in UNSAFE):
            continue
        groups.setdefault(pre, []).append(idx)

    dup = {k: v for k, v in groups.items() if len(v) > 1}
    if not dup:
        return 0, 0

    # deterministic group numbering: by first appearance
    ordered = sorted(dup.items(), key=lambda kv: kv[1][0])
    repl = {}  # run-index -> list of new command strings
    saved = 0
    for gi, (pre, idxs) in enumerate(ordered):
        tmp = '%%t.cqd%d.ll' % gi
        saved += len(idxs) - 1
        for n, ri in enumerate(idxs):
            cmd = runs[ri][2].strip()
            rest = cmd.split('|', 1)[1].strip()
            consumer = '%s < %s' % (rest, tmp)
            if n == 0:
                repl[ri] = ['%s > %s' % (pre, tmp), consumer]
            else:
                repl[ri] = [consumer]

    # rebuild, replacing each affected RUN block (which may span
    # continuation lines) with its new single-line RUN commands
    out, drop = [], {}
    for ri, cmds in repl.items():
        s, e, _ = runs[ri]
        drop[s] = (e, cmds)
    i = 0
    while i < len(lines):
        if i in drop:
            e, cmds = drop[i]
            indent = RUN_RE.match(lines[i]).group(1)
            for c in cmds:
                out.append(indent + c)
            i = e + 1
        else:
            out.append(lines[i])
            i += 1

    if apply_changes:
        with open(path, 'w', encoding='utf-8', errors='surrogateescape') as f:
            f.write('\n'.join(out))
    return len(ordered), saved


def main():
    apply_changes = '--apply' in sys.argv
    root = 'ir-pass/test/*.ll'
    tot_f = tot_g = tot_s = 0
    for p in sorted(glob.glob(root)):
        g, s = transform(p, apply_changes)
        if g:
            tot_f += 1
            tot_g += g
            tot_s += s
    print('%s: %d fixtures, %d groups, %d opt spawns removed'
          % ('APPLIED' if apply_changes else 'DRY-RUN', tot_f, tot_g, tot_s))


if __name__ == '__main__':
    main()
