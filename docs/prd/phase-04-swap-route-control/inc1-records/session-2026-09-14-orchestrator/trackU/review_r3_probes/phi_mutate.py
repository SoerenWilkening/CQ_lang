#!/usr/bin/env python3
"""Track U review round 3 — THE PHI-INCOMING INJECTION INSTRUMENT.

Round 2 reported it "could not synthesize phi-incoming injection soundly".  The
reason is real and is stated in REVIEW_U_R3.md §1: you cannot emulate the phi
half with a zero twin that mutates arg-0 only, because the clause rewrites a
*second* operand.  The fix is that the twin must mutate BOTH operands — i.e. the
twin must reproduce `normalizeUndefRotationSeed`'s OWN algorithm by hand, not
approximate it.  That is constructible, and this is it.

Two parallel mutant corpora from one source:

  U-mutant : every theta CARRIED BY a phi gets arg-0 := undef, and every
             non-theta incoming of every theta-carrying phi := undef.
  Z-mutant : the SAME sites get the type's concrete ZERO.

`Z` is exactly "what the subject's rewrite produces, applied by hand", so the
rule's whole claim on the phi half is  SUBJECT(U) == ORACLE(Z)  — the same shape
as round 2's seed closure, now covering the operand round 2 could not reach.

VACUITY FENCES (Rule 12c):
  * ';' comment text is stripped before matching, so FileCheck lines are never
    mutated (round 2's mutator defect #2, reproduced here deliberately as a fence);
  * `declare` lines are never touched (round 2's defect #1);
  * a fixture whose phi type we cannot render a zero for is SKIPPED and COUNTED,
    never silently emitted;
  * every emitted mutant is compared against its source and a fixture that did
    not actually change is COUNTED as vacuous;
  * every emitted file is checked NON-EMPTY (a 0-byte module ACCEPTS through the
    passthrough early-out).
"""
import re, sys, os, glob, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from phi_census import strip_comment, THETA, PHI, PAIR, eligible

ZERO = {
    'i1': 'false', 'i8': '0', 'i16': '0', 'i32': '0', 'i64': '0', 'i128': '0',
    'half': '0xH0000', 'float': '0.000000e+00', 'double': '0.000000e+00',
    'x86_fp80': '0xK00000000000000000000',
}
# theta arg-0 zero, keyed on the LLVM type spelled in the call
def zero_for(ty):
    ty = ty.strip()
    if ty in ZERO:
        return ZERO[ty]
    if re.fullmatch(r'i\d+', ty):
        return '0'
    return None

ARG0 = re.compile(r'(@cq_theta_[\w]+\s*\(\s*)([^,]*?)(\s*,)')

def split_arg0(txt):
    """-> (prefix, type, attrs, value, suffix) for the first arg of a theta call"""
    m = ARG0.search(txt)
    if not m:
        return None
    inner = m.group(2)            # e.g. "i32 noundef %x"  /  "i1 noundef true"
    toks = inner.split()
    if len(toks) < 2:
        return None
    ty = toks[0]
    val = toks[-1]
    attrs = ' '.join(toks[1:-1])
    return (m.start(2), m.end(2), ty, attrs, val)

def mutate_file(src, dst, mode):
    """mode in {'undef','zero'}; returns (changed, reason)"""
    lines, thetas, el = eligible(src)
    if not el:
        return (False, 'no-eligible-phi')
    # 1. which theta RESULTS are carried by an eligible phi
    carried = set()
    for e in el:
        carried.update(e['carried'])
    if not carried:
        return (False, 'no-carrier')
    out = list(lines)
    nchg = 0
    # 2. rewrite arg-0 of each carried theta's DEFINING call
    for i, raw in enumerate(lines):
        code = strip_comment(raw)
        m = THETA.match(code)
        if not m or m.group(1) not in carried:
            continue
        sp = split_arg0(code)
        if sp is None:
            return (False, 'arg0-unparsed')
        s, e2, ty, attrs, val = sp
        if mode == 'undef':
            new = 'undef'
        else:
            new = zero_for(ty)
            if new is None:
                return (False, f'no-zero-for-{ty}')
        # `noundef` must go when the value becomes undef — otherwise the module is
        # self-contradictory and the *parser/verifier*, not the pass, decides it.
        keep = ' '.join(a for a in attrs.split() if a != 'noundef') if mode == 'undef' else attrs
        repl = (ty + (' ' + keep if keep else '') + ' ' + new)
        newcode = code[:s] + repl + code[e2:]
        out[i] = newcode + ('\n' if not newcode.endswith('\n') else '')
        nchg += 1
    # 3. rewrite every NON-theta incoming of every eligible phi
    for e in el:
        i = e['idx']
        code = strip_comment(out[i]) if strip_comment(out[i]).strip() else strip_comment(lines[i])
        ty = e['ty']
        if mode == 'undef':
            new = 'undef'
        else:
            new = zero_for(ty)
            if new is None:
                return (False, f'no-zero-for-{ty}')
        def rep(m):
            v = m.group(1).strip()
            if v in e['carried']:
                return m.group(0)
            return '[ %s, %s ]' % (new, m.group(2))
        newcode = PAIR.sub(rep, code)
        if newcode != code:
            out[i] = newcode + ('\n' if not newcode.endswith('\n') else '')
            nchg += 1
    if nchg == 0:
        return (False, 'no-change')
    with open(dst, 'w') as f:
        f.writelines(out)
    if os.path.getsize(dst) == 0:
        os.unlink(dst)
        return (False, 'EMPTY-OUTPUT')
    return (True, 'ok')

if __name__ == '__main__':
    srcdir, mode, outdir = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(outdir, exist_ok=True)
    ok = 0
    skip = {}
    vac = []
    for p in sorted(glob.glob(os.path.join(srcdir, '*.ll'))):
        b = os.path.basename(p)
        d = os.path.join(outdir, b)
        changed, why = mutate_file(p, d, mode)
        if not changed:
            skip[why] = skip.get(why, 0) + 1
            continue
        if open(d).read() == open(p).read():
            vac.append(b)
        ok += 1
    print(f"mode={mode}  emitted={ok}  outdir={outdir}")
    print(f"  skipped: {skip}")
    print(f"  VACUOUS (mutant == source): {len(vac)} {vac[:5]}")
