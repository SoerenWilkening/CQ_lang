#!/usr/bin/env python3
"""Census of clang's poison-shielded short-circuit select-forms and their cones.

WHY THIS EXISTS, AND WHY IT IS COMMITTED
========================================
`PredMuxFlatten.cpp` rewrites clang -O1's poison-shielded short-circuit form
`select i1 %a, i1 %b, i1 false` (= `a && b`) into a plain `and`, which OBSERVES
`%b` on basis states the select shielded.  Two functions govern that rewrite:

  * `coneDefinedAfterFlagDrop` — the CLAIM-time proof over `%b`'s backward cone;
  * `stripPoisonCone`          — the EMIT-time annotation drop over that cone.

Every question anyone asks about that pair ("how many real modules even have
this shape?", "does any cone carry a call?", "does the strip walk further than
the proof?") is a census over LLVM IR, and it has now been hand-rebuilt three
times from scratch — once losing 10 modules to a basename collision and once
reporting probes that never reached the clause at all.  So it lives here.

WHAT IT MEASURES, AND WHAT IT DOES NOT
======================================
It is a TEXTUAL scan of `.ll` files.  It is a SHAPE census: it tells you what
shapes exist in a corpus.  It is NOT a fence measurement and has NO power to
show what the pass accepts — only running `opt` with the plugin does that.  A
module with no `@cq_theta` never even reaches the pass (passthrough early-out),
so `--require-taint` is offered to make that distinction explicit rather than
silent.

KNOWN LIMITS, stated so nobody re-derives them:
  * Unnamed IR shares one numbering space between instruction results and block
    labels, so a `%N` that is a LABEL resolves to nothing and is treated as a
    leaf.  That under-counts cone size through `phi` incoming-block operands
    only, which carry no data.
  * Operand extraction intersects `%tokens` with the set of known SSA
    definitions in the same function, so type names (`%struct.foo`) and labels
    drop out by construction.
  * `declare`-level attributes are read from the module's `declare` lines; a
    call-site attribute is read from the call text.  Both are reported
    separately because `CallBase::getRetAttr` falls back from one to the other
    while `dropPoisonGeneratingReturnAttributes` writes only the call site.

USAGE
=====
    python3 tools/predmux_cone_census.py <file-or-dir> [...] [--json OUT]
    python3 tools/predmux_cone_census.py corpus/ --require-taint --verbose
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter

# A `%name` or `%42` SSA reference.  LLVM identifiers may be quoted; the quoted
# form is rare in clang output and is handled by the same character class plus
# an explicit quoted alternative.
SSA_REF = re.compile(r'%(?:"[^"]*"|[-a-zA-Z$._0-9]+)')

# `  %x = <rest>` — an SSA definition inside a function body.
SSA_DEF = re.compile(r'^\s*(%(?:"[^"]*"|[-a-zA-Z$._0-9]+))\s*=\s*(.*)$')

DEFINE_START = re.compile(r'^define\b.*\{\s*$')

# The two poison-shielded short-circuit forms clang -O1 emits.
#   `a && b`  ->  select i1 %a, i1 %b, i1 false      (shielded operand = arg 2)
#   `a || b`  ->  select i1 %a, i1 true, i1 %b       (shielded operand = arg 3)
SEL_AND = re.compile(r'\bselect\s+i1\s+(\S+?),\s*i1\s+(\S+?),\s*i1\s+false\b')
SEL_OR = re.compile(r'\bselect\s+i1\s+(\S+?),\s*i1\s+true,\s*i1\s+(\S+?)\s*$')

# Poison-generating annotations LLVM 19 recognises, split by family.
FLAG_TOKENS = ('nsw', 'nuw', 'exact', 'inbounds', 'nneg', 'disjoint', 'nusw',
               'samesign')
# Return attributes `Instruction::dropPoisonGeneratingReturnAttributes` clears.
RETATTR = re.compile(r'\b(range\(|nonnull\b|align\s+\d+|dereferenceable\()')

CALL = re.compile(r'\b(?:tail\s+|musttail\s+|notail\s+)?call\b')
CALLEE = re.compile(r'@([-a-zA-Z$._0-9]+|"[^"]*")\s*\(')

ROTATION_PREFIXES = ('cq_theta_', 'cq_phi_')

# The curated `memory(none)` intrinsic set `isCuratedReversibleIntrinsic`
# admits.  Kept as a STEM list; this mirrors `intrinsicStem` in
# IntrinsicLowering.cpp, which is coupled to it by nothing mechanical — re-read
# that function when either moves.
CURATED_STEMS = (
    'bswap', 'bitreverse', 'ctpop', 'ctlz', 'cttz', 'abs',
    'smin', 'smax', 'umin', 'umax',
    'sadd.sat', 'uadd.sat', 'ssub.sat', 'usub.sat',
    'fshl', 'fshr',
    'sqrt', 'fabs', 'copysign', 'floor', 'ceil', 'trunc', 'round', 'rint',
    'nearbyint', 'minnum', 'maxnum', 'fma', 'fmuladd', 'lrint', 'llrint',
)

# The three curated cells whose poison rides an IMMARG, which no drop API can
# reach (`curatedIntrinsicCanBePoison`).
POISON_IMMARG_STEMS = ('ctlz', 'cttz', 'abs')


def strip_comment(line: str) -> str:
    """Drop a trailing `;` comment, respecting quoted strings."""
    out, in_q, i = [], False, 0
    while i < len(line):
        c = line[i]
        if c == '"':
            in_q = not in_q
        elif c == ';' and not in_q:
            break
        out.append(c)
        i += 1
    return ''.join(out)


class Function:
    __slots__ = ('name', 'defs', 'order')

    def __init__(self, name: str):
        self.name = name
        self.defs: dict[str, str] = {}   # `%x` -> RHS text
        self.order: list[str] = []


def parse_module(text: str):
    """-> (functions, declare_ret_attrs)  — declare_ret_attrs: fn name -> attr str."""
    funcs: list[Function] = []
    declares: dict[str, str] = {}
    cur: Function | None = None
    for raw in text.splitlines():
        line = strip_comment(raw).rstrip()
        if not line:
            continue
        if line.startswith('declare'):
            m = CALLEE.search(line)
            if m:
                # Everything between `declare` and the callee name holds the
                # return attributes.
                head = line[len('declare'):line.index('@')]
                declares[m.group(1).strip('"')] = head.strip()
            continue
        if DEFINE_START.match(line):
            m = CALLEE.search(line)
            cur = Function(m.group(1).strip('"') if m else '?')
            funcs.append(cur)
            continue
        if line == '}':
            cur = None
            continue
        if cur is None:
            continue
        m = SSA_DEF.match(line)
        if m:
            cur.defs[m.group(1)] = m.group(2)
            cur.order.append(m.group(1))
    return funcs, declares


def operands_of(fn: Function, rhs: str) -> list[str]:
    """SSA references in `rhs` that name a definition in this function."""
    return [t for t in SSA_REF.findall(rhs) if t in fn.defs]


def callee_of(rhs: str) -> str | None:
    if not CALL.search(rhs):
        return None
    m = CALLEE.search(rhs)
    return m.group(1).strip('"') if m else None


def intrinsic_stem(name: str) -> str | None:
    if not name.startswith('llvm.'):
        return None
    parts = name.split('.')[1:]
    # `llvm.ctlz.i32` -> `ctlz`;  `llvm.sadd.sat.i32` -> `sadd.sat`
    while parts and re.fullmatch(r'[iv]?\d+|f\d+|p\d+|v\d+[a-z0-9]*', parts[-1]):
        parts.pop()
    return '.'.join(parts) if parts else None


def classify_node(fn: Function, ref: str) -> str:
    """Mirror of the SHIPPED `coneDefinedAfterFlagDrop` node classification.

    Returns one of: 'leaf' (no operand recursion), 'interior' (recurse),
    'fail' (proof would refuse).  This is the whole point of the tool: the
    difference between this classification and a blind operand walk IS the
    bd u1rp over-reach.
    """
    rhs = fn.defs[ref]
    callee = callee_of(rhs)
    if callee is not None:
        if any(callee.startswith(p) for p in ROTATION_PREFIXES):
            return 'leaf'
        stem = intrinsic_stem(callee)
        if stem is None or stem not in CURATED_STEMS:
            return 'fail'
        if stem in POISON_IMMARG_STEMS:
            return 'fail'      # conservative: the immarg may be poison-on
        return 'interior'
    return 'interior'          # non-call: the whitelist decides; shape-only here


def walk_cone(fn: Function, root: str, narrow: bool):
    """Backward cone from `root`.

    narrow=True  mirrors the proof (stop at a rotation-call leaf).
    narrow=False mirrors the SHIPPED strip (recurse through everything).
    """
    seen, wl, nodes = set(), [root], []
    while wl:
        r = wl.pop()
        if r in seen or r not in fn.defs:
            continue
        seen.add(r)
        nodes.append(r)
        if narrow and classify_node(fn, r) == 'leaf':
            continue
        wl.extend(operands_of(fn, fn.defs[r]))
    return nodes


def annotations_in(rhs: str) -> list[str]:
    found = [t for t in FLAG_TOKENS if re.search(r'\b%s\b' % re.escape(t), rhs)]
    if RETATTR.search(rhs):
        found.append('retattr')
    return found


def scan_module(path: str, require_taint: bool):
    with open(path, 'r', errors='replace') as fh:
        text = fh.read()
    has_taint = '@cq_theta' in text
    if require_taint and not has_taint:
        return None
    funcs, declares = parse_module(text)
    rec = {
        'module': os.path.basename(path),
        'has_taint': has_taint,
        'shielded_forms': 0,
        'cones_with_call': 0,
        'cone_callees': Counter(),
        'cone_callees_curated': 0,
        'cone_callees_rotation': 0,
        'cone_callees_other': 0,
        # THE bd u1rp OVER-REACH: nodes the shipped strip mutates that the
        # proof's walk never visits.
        'overreach_forms': 0,
        'overreach_nodes': 0,
        'overreach_annotated_nodes': 0,
        'overreach_examples': [],
        # bd 94on / u1rp half 2: poison-generating RETURN attributes in a cone.
        'cone_callsite_retattr': 0,
        'cone_declare_retattr': 0,
        'retattr_examples': [],
    }
    for fn in funcs:
        for ref, rhs in fn.defs.items():
            for rx, grp in ((SEL_AND, 2), (SEL_OR, 2)):
                m = rx.search(rhs)
                if not m:
                    continue
                shielded = m.group(grp)
                if not shielded.startswith('%'):
                    continue      # a constant shielded operand: nothing to walk
                rec['shielded_forms'] += 1
                wide = walk_cone(fn, shielded, narrow=False)
                narrow = set(walk_cone(fn, shielded, narrow=True))
                extra = [n for n in wide if n not in narrow]
                has_call = False
                for n in wide:
                    c = callee_of(fn.defs[n])
                    if c is None:
                        continue
                    has_call = True
                    rec['cone_callees'][c] += 1
                    if any(c.startswith(p) for p in ROTATION_PREFIXES):
                        rec['cone_callees_rotation'] += 1
                    elif (intrinsic_stem(c) or '') in CURATED_STEMS:
                        rec['cone_callees_curated'] += 1
                    else:
                        rec['cone_callees_other'] += 1
                    if RETATTR.search(fn.defs[n]):
                        rec['cone_callsite_retattr'] += 1
                        rec['retattr_examples'].append(
                            f'{fn.name}: {fn.defs[n][:140]}')
                    if RETATTR.search(declares.get(c, '')):
                        rec['cone_declare_retattr'] += 1
                        rec['retattr_examples'].append(
                            f'{fn.name}: DECLARE {c}: {declares[c][:100]}')
                if has_call:
                    rec['cones_with_call'] += 1
                if extra:
                    rec['overreach_forms'] += 1
                    rec['overreach_nodes'] += len(extra)
                    for n in extra:
                        ann = annotations_in(fn.defs[n])
                        if ann:
                            rec['overreach_annotated_nodes'] += 1
                            if len(rec['overreach_examples']) < 6:
                                rec['overreach_examples'].append(
                                    f'{fn.name}: {n} = {fn.defs[n][:120]}'
                                    f'   [{",".join(ann)}]')
    rec['cone_callees'] = dict(rec['cone_callees'])
    return rec


def iter_inputs(paths):
    for p in paths:
        if os.path.isdir(p):
            for root, _dirs, files in os.walk(p):
                for f in sorted(files):
                    if f.endswith('.ll'):
                        yield os.path.join(root, f)
        elif p.endswith('.ll'):
            yield p


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('paths', nargs='+', help='.ll files or directories')
    ap.add_argument('--json', help='write the per-module records here')
    ap.add_argument('--require-taint', action='store_true',
                    help='skip modules with no @cq_theta (they never reach the pass)')
    ap.add_argument('--verbose', action='store_true')
    args = ap.parse_args()

    inputs = sorted(set(iter_inputs(args.paths)))
    # COUNT WHAT IS ON DISK: distinct basenames, so a collision that silently
    # overwrote a module in some upstream compile loop shows up here.
    basenames = {os.path.basename(p) for p in inputs}

    recs, skipped = [], 0
    for p in inputs:
        r = scan_module(p, args.require_taint)
        if r is None:
            skipped += 1
            continue
        recs.append(r)

    tot = Counter()
    for r in recs:
        for k in ('shielded_forms', 'cones_with_call', 'cone_callees_curated',
                  'cone_callees_rotation', 'cone_callees_other',
                  'overreach_forms', 'overreach_nodes',
                  'overreach_annotated_nodes', 'cone_callsite_retattr',
                  'cone_declare_retattr'):
            tot[k] += r[k]

    print(f'files given        : {len(inputs)}')
    print(f'distinct basenames : {len(basenames)}'
          f'{"   *** COLLISION: some inputs share a name ***" if len(basenames) != len(inputs) else ""}')
    print(f'scanned            : {len(recs)}   (skipped for no-taint: {skipped})')
    print(f'carry @cq_theta    : {sum(1 for r in recs if r["has_taint"])}')
    print()
    print(f'poison-shielded select-forms      : {tot["shielded_forms"]}'
          f'   in {sum(1 for r in recs if r["shielded_forms"]) } module(s)')
    print(f'  cones containing a call         : {tot["cones_with_call"]}')
    print(f'    callees: rotation={tot["cone_callees_rotation"]}'
          f' curated={tot["cone_callees_curated"]}'
          f' other={tot["cone_callees_other"]}')
    print(f'  call sites with a poison ret-attr: {tot["cone_callsite_retattr"]}')
    print(f'  declares with a poison ret-attr  : {tot["cone_declare_retattr"]}')
    print()
    print('bd u1rp OVER-REACH (nodes the shipped strip mutates that the proof never visits)')
    print(f'  forms whose wide walk exceeds the narrow walk : {tot["overreach_forms"]}')
    print(f'  extra nodes mutated                           : {tot["overreach_nodes"]}')
    print(f'  ... of which carry a poison annotation        : {tot["overreach_annotated_nodes"]}')

    if args.verbose:
        for r in recs:
            if r['overreach_forms'] or r['cones_with_call']:
                print(f'\n--- {r["module"]}')
                for k in ('shielded_forms', 'cones_with_call', 'overreach_forms',
                          'overreach_nodes', 'overreach_annotated_nodes'):
                    print(f'    {k}: {r[k]}')
                for e in r['overreach_examples']:
                    print(f'    OVERREACH  {e}')
                for e in r['retattr_examples'][:4]:
                    print(f'    RETATTR    {e}')
                if r['cone_callees']:
                    print(f'    callees    {r["cone_callees"]}')

    if args.json:
        with open(args.json, 'w') as fh:
            json.dump({'inputs': len(inputs), 'distinct': len(basenames),
                       'scanned': len(recs), 'totals': dict(tot),
                       'modules': recs}, fh, indent=1)
        print(f'\nwrote {args.json}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
