#!/usr/bin/env python3
"""Shared seed mutator for the Track U round-2 sweeps.

Rewrites the CONSTANT arg-0 of every `@cq_theta_<sfx>` CALL SITE to a chosen
literal.  Two corrections over the first draft, both of which produced VACUOUS
probes (CLAUDE.md Rule 12c) before they were found:
  * a `declare` prototype is not a call site and is never touched;
  * a `@cq_theta_` inside a `;` COMMENT (FileCheck CHECK lines are full of them)
    is not a call site either — matching one made the argument scan run across
    newlines and join comment lines, mutating nothing while reporting success.
A chained theta's arg-0 is an SSA value and is always left alone.
"""
import re, os, glob

ZERO = {'i1':'false','i8':'0','i16':'0','i32':'0','i64':'0','i128':'0',
        'half':'0xH0000','bfloat':'0xR0000','float':'0.000000e+00',
        'double':'0.000000e+00','x86_fp80':'0xK00000000000000000000',
        'fp128':'0xL00000000000000000000000000000000','ptr':'null'}
PAT = re.compile(r'@cq_theta_[A-Za-z0-9_]+\(')

def mutate(src, mode):
    """mode 'undef' -> undef ; mode 'zero' -> the type's null value.
    Returns (text, n_mutated, unknown_types)."""
    out = []; i = 0; n = 0; unknown = set()
    while True:
        m = PAT.search(src, i)
        if not m:
            out.append(src[i:]); break
        out.append(src[i:m.end()])
        ls = src.rfind('\n', 0, m.start()) + 1
        head = src[ls:m.start()]
        if head.lstrip().startswith('declare') or ';' in head:
            i = m.end(); continue           # prototype, or inside a comment
        d = 0; j = m.end()
        while j < len(src):
            c = src[j]
            if c == '\n': break             # an argument never spans a line here
            if c in '([{<': d += 1
            elif c in ')]}>':
                if d == 0: break
                d -= 1
            elif c == ',' and d == 0: break
            j += 1
        arg = src[m.end():j]; toks = arg.split()
        ssa = bool(toks) and (toks[-1].startswith('%') or toks[-1].startswith('@'))
        if toks and (not ssa or mode.endswith('all')):
            if mode.startswith('undef'):
                toks[-1] = 'undef'; n += 1
            else:
                ty = toks[0]
                if ty in ZERO: toks[-1] = ZERO[ty]; n += 1
                else: unknown.add(ty)
            arg = ' '.join(toks)
        out.append(arg); i = j
    return ''.join(out), n, unknown

if __name__ == '__main__':
    import sys
    mode, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    made = 0; unk = set()
    for f in sorted(glob.glob('/Users/sorenwilkening/Desktop/CQ_lang/ir-pass/test/*.ll')):
        t, n, u = mutate(open(f, errors='replace').read(), mode)
        unk |= u
        if n:
            open(os.path.join(out, os.path.basename(f)), 'w').write(t); made += 1
    print("mode=%s mutants=%d unknown_types=%s" % (mode, made, sorted(unk)))
