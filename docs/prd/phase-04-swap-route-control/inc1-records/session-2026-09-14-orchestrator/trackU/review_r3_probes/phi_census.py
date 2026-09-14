#!/usr/bin/env python3
"""Track U review round 3 — census of the phi clause's ELIGIBLE population.

The phi clause of `normalizeUndefRotationSeed` can only fire on a phi that has a
`@cq_theta_*` RESULT as one of its incoming values (`Theta->users()` filtered to
PHINode).  This script counts, per fixture, how many such phis exist and how many
non-theta incomings they have (= the injection sites round 3 can create).

Textual `.ll` parsing, deliberately: we never need to *understand* the module,
only to locate `%name = ... call ... @cq_theta_` and `phi` lines that mention
that `%name` inside a `[ ... , %block ]` incoming pair.

VACUITY FENCES (Rule 12c; round 2's mutator had two of exactly this class):
  * comment text after ';' is stripped before any match, so a FileCheck line that
    mentions @cq_theta_ or phi can never be counted or mutated;
  * theta results are matched with a word boundary so `%1` does not match `%10`.
"""
import re, sys, os, glob, json

THETA = re.compile(r'^\s*(%[\w.$-]+)\s*=\s*(?:tail\s+|musttail\s+|notail\s+)?call[^\n]*@(cq_theta_[\w]+)\s*\(')
PHI   = re.compile(r'^\s*(%[\w.$-]+)\s*=\s*phi\s+(?:fast\s+|nnan\s+|ninf\s+|nsz\s+|arcp\s+|contract\s+|afn\s+|reassoc\s+)*([^\[]+?)\s*(\[.*)$')
PAIR  = re.compile(r'\[\s*([^,\]]+?)\s*,\s*(%[\w.$-]+)\s*\]')

def strip_comment(line):
    # a ';' inside a string literal is not something these fixtures contain in
    # an instruction line; the conservative split is fine and is what keeps
    # FileCheck prefixes (which are ALL comment lines) out of the census.
    return line.split(';', 1)[0]

def scan(path):
    """-> (list of theta names, list of (phi_line_idx, phi_name, ty, [(val, blk)]))"""
    thetas, phis = [], []
    with open(path, 'r', errors='replace') as f:
        lines = f.readlines()
    for i, raw in enumerate(lines):
        line = strip_comment(raw)
        m = THETA.match(line)
        if m:
            thetas.append(m.group(1))
            continue
        m = PHI.match(line)
        if m:
            pairs = PAIR.findall(m.group(3))
            phis.append((i, m.group(1), m.group(2).strip(), pairs))
    return lines, thetas, phis

def eligible(path):
    lines, thetas, phis = scan(path)
    tset = set(thetas)
    out = []
    for (i, name, ty, pairs) in phis:
        carriers = [k for k, (v, b) in enumerate(pairs) if v.strip() in tset]
        if not carriers:
            continue
        others = [k for k, (v, b) in enumerate(pairs) if k not in carriers]
        out.append(dict(idx=i, name=name, ty=ty, pairs=pairs,
                        carriers=carriers, others=others,
                        carried=[pairs[k][0].strip() for k in carriers]))
    return lines, thetas, out

if __name__ == '__main__':
    files = sorted(glob.glob(os.path.join(sys.argv[1], '*.ll')))
    tot = nphi = nfix = ninj = nundef = 0
    rows = []
    for p in files:
        tot += 1
        lines, thetas, el = eligible(p)
        if not el:
            continue
        nfix += 1
        nphi += len(el)
        inj = sum(len(e['others']) for e in el)
        ninj += inj
        hasu = any(any(e['pairs'][k][0].strip() in ('undef', 'poison') for k in e['others'])
                   for e in el)
        if hasu:
            nundef += 1
        rows.append(dict(file=os.path.basename(p), phis=len(el), inj=inj,
                         already_undef=hasu,
                         detail=[dict(n=e['name'], ty=e['ty'],
                                      pairs=[(v, b) for v, b in e['pairs']],
                                      carried=e['carried']) for e in el]))
    json.dump(rows, open(sys.argv[2], 'w'), indent=1)
    print(f"fixtures scanned              : {tot}")
    print(f"fixtures with a THETA-CARRYING phi : {nfix}")
    print(f"such phis                     : {nphi}")
    print(f"injectable non-theta incomings: {ninj}")
    print(f"fixtures ALREADY carrying an undef/poison incoming on such a phi: {nundef}")
