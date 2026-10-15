#!/usr/bin/env python3
"""trace_twin_equiv.py — is a 2-TU CLONE trace the SAME CIRCUIT as its hand-inlined twin?

bd test_C_libtooling-rhk5 (2026-09-28). The project's correctness criterion for a
lowering change is the TWIN: the hand-inlined / hand-unrolled program defines the
correct circuit, and a byte-identical golden is the witness (`*-twin-identical`).
For a program that calls a Phase-6 SPECIALIZED CLONE whose result is quantum, byte
identity is IMPOSSIBLE by construction, for two reasons that are both properties of
the shipped design and neither of which is a defect:

  (1) THE BENNETT COPY-OUT. A clone returning a quantum value is wrapped
      compute -> copy -> uncompute (`BennettWrap.cpp`): its trace is
          cq_template_T(args) -> a
          cqrt_alloc_W(0)     -> b
          cqrt_copy_W(a, b)
          cq_template_T_unc(a, args)
          cqrt_free(a)
      where the hand-inlined twin emits the single line `cq_template_T(args) -> b`.
      The two are the same unitary on every register but the scratch `a`, which the
      block returns to |0> and frees (Bennett).
  (2) POSITION. `clang -O1` SINKS the twin's inlined op to its first use, while a
      call to another TU stays where the user wrote it — so the block and the op sit
      at different positions of an otherwise identical stream.

So this tool decides the precise weaker relation, and nothing weaker:

  REWRITE both traces to a fixpoint with two rules (see `contract()`):
    rule 1 — a Bennett COPY-OUT `T(args)->a; alloc(0)->b; copy(a,b); … T_unc(a,args);
             … free(a)` becomes `T(args)->b` (the copy must be ADJACENT to the alloc,
             `a` used by those four lines only, the copy full-width — `result_width`
             — and no handle among `args` written between T and its adjoint). The
             block need NOT be contiguous, and a multi-template clone body is handled
             one link at a time: each application contracts the LAST link (the one the
             copy reads), and the rest of the scratch chain stays as ordinary
             forward/adjoint/free traffic the twin must reproduce;
    rule 2 — an inner `_unc` twin's recompute-copy-uncompute `T(args)->c; copy(c,x);
             T_unc(c,args); free(c)` becomes the out-first adjoint `T_unc(x, args)`;
    rule 3 — (bd dm7f.81, applied once before the two above) a
             `cqrt_xorc_<W>[_controlled](…, 0)` with a LITERAL-zero immediate (fp:
             the all-zero bit pattern, never -0.0's `0x8000…`) is the identity and
             is deleted, with the now-empty x(f); x(f) bracket around it: a rolled
             trip prints it from a runtime counter, the unrolled twin folds it.
             `--zero-xorc-then-bytes` applies ONLY rule 3, then byte identity;
  then decide TRACE EQUIVALENCE (Mazurkiewicz) up to a consistent RENAMING of handles: the two streams must contain the same gates, with
  the same literals and the same operand roles, and every pair of DEPENDENT gates
  must occur in the same order. Two gates are DEPENDENT iff they share a handle that
  at least one of them WRITES. Reordering only independent gates never changes the
  unitary; that is the whole soundness argument, and it is why an EQUIV verdict
  says "same circuit".

THE MODEL IS CONSERVATIVE IN ONE DIRECTION ONLY. Every gate that touches a handle
in any way other than an explicitly listed READ slot is a WRITE of it — including
`cqrt_rz_*` (diagonal, so it genuinely commutes with a read-as-control, but calling
it a write can only refuse a reordering, never admit one), `cqrt_measure_*` (a
collapse), `cqrt_free` and every mint. So a false DIFF is possible by design. A false
EQUIV requires one of the two rewrite rules or the effect table to be wrong: that is
the claim the boundary controls below exist to attack, and it is an argued claim,
not a proof — the first shipped spelling had one (rule 1's width test was a
substring match; Rule-13 r1B found it with attack row A9, now control
`r1B-A9-width-cast`). An UNCLASSIFIED symbol is refused (exit 2) rather than
guessed — the free_pairing_check / entangle.py discipline.

THE CONTRACTION IS DELIBERATELY NARROW in its CONJUNCTS (listed under rule 1 and
rule 2 above, each pinned by a `*-clobbered` / `*-free-first` / `*-nonzero` control),
not in the block's shape: what does not match stays in the trace, and an unmatched
scratch chain can only make the pair compare DIFF — the safe direction — in which
case judge it with entangle.py (Rule 8) and the 2b census instead.

WHAT IT CANNOT SEE: anything the trace does not print (rail identities at a free —
that is stage 2b's job; stderr warnings). It compares circuits, not verdicts.

USAGE
  trace_twin_equiv.py SUBJECT.trace TWIN.trace     exit 0 EQUIV, 1 DIFF, 2 refused
  trace_twin_equiv.py --selftest                   the boundary controls only
  trace_twin_equiv.py --zero-xorc-then-bytes A B   STRICT: rule 3 only, then byte
                                                   identity (exit 0 IDENTICAL, 1 DIFF)
Every invocation runs the boundary controls FIRST (a NULL control included) and
refuses to measure anything if one of them fails (L10: an instrument that has not
been made to fail is measuring itself).
"""
import os
import re
import sys

LINE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\((.*)\)(?:\s*->\s*(\S+))?$')
HANDLE = re.compile(r'^[ah](\d+)$')   # hN = a rail, aN = a QRAM array token


class Refused(Exception):
    pass


def parse(lines):
    evs = []
    for n, raw in enumerate(lines, 1):
        l = raw.strip()
        if not l:
            continue
        m = LINE.match(l)
        if not m:
            raise Refused(f"L{n}: unparseable trace line {l!r}")
        sym, argtxt, ret = m.group(1), m.group(2), m.group(3)
        args = [a.strip() for a in argtxt.split(',')] if argtxt.strip() else []
        evs.append({'sym': sym, 'args': args, 'ret': ret, 'line': l})
    return evs


def is_h(tok):
    return tok is not None and HANDLE.match(tok) is not None


def result_width(sym):
    """The width of the rail a forward producer MINTS — which is what a full-width
    copy-out must match. Read off the symbol grammar
    `cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh|…]`:
      * a cast `…_<from>_to_<to>` mints `<to>`;
      * a compare (`icmp_*`/`fcmp_*`) mints `i1`;
      * every other template, and `cqrt_qram_load_<W>`, mints its (first) `<W>`.
    Returns None when no width can be read (the caller then refuses to contract).
    bd rhk5 round 2 (r1B F-r1B-2): the first spelling asked whether `_<w>_` was a
    SUBSTRING of the symbol, and a cast carries BOTH widths, so an i32 copy of an
    i64 `sext` result contracted — a false EQUIV (control `r1B-A9-width-cast`)."""
    m = re.search(r'_to_([if]\d+)(?=_|$)', sym)
    if m:
        return m.group(1)
    if re.match(r'^cq_template_[if]cmp_', sym):
        return 'i1'
    m = re.search(r'_([if]\d+)(?=_|$)', sym)
    return m.group(1) if m else None


def is_fwd_producer(sym):
    """A reassigning producer (fresh result rail, reads every operand) or its
    out-first `_unc` adjoint: `cq_template_*` (uncontrolled, not `_inv`) and the
    QRAM LOAD. A QRAM STORE is NOT one (it writes its array; refused)."""
    if sym.endswith('_inv') or '_controlled' in sym:
        return False
    return sym.startswith('cq_template_') or sym.startswith('cqrt_qram_load_')


def effects(ev):
    """(reads, writes) as sets of handle TOKENS, plus the list of arg positions
    that are handles. Refuses an unclassified symbol."""
    s, a, r = ev['sym'], ev['args'], ev['ret']
    hpos = [i for i, t in enumerate(a) if is_h(t)]
    reads, writes = set(), set()

    def W(i):
        writes.add(a[i])

    def R(i):
        reads.add(a[i])

    if s.startswith('cqrt_alloc_'):
        if hpos:
            raise Refused(f"alloc with a handle operand: {ev['line']!r}")
    elif s.startswith('cqrt_qram_alloc_'):
        if hpos or not is_h(r):
            raise Refused(f"off-shape QRAM array mint: {ev['line']!r}")
    elif is_fwd_producer(s) and s.endswith('_unc'):
        # the out-first void adjoint `T_unc(out, <T's own operands>)`: writes the
        # out rail ONLY and reads every other handle operand (DD-3; a QRAM STORE
        # `_unc` is the one exception to out-first and is refused below).
        if not a or not is_h(a[0]) or r is not None:
            raise Refused(f"_unc without an out handle: {ev['line']!r}")
        W(0)
        for i in hpos:
            if i != 0:
                R(i)
    elif is_fwd_producer(s):
        if r is None or not is_h(r):
            raise Refused(f"forward producer without a result handle: {ev['line']!r}")
        for i in hpos:
            R(i)
    elif re.match(r'^cqrt_(ry|rz)_\w+_controlled$', s) and len(a) == 3:
        if is_h(a[0]):
            R(0)
        W(1)
    elif re.match(r'^cqrt_(ry|rz)_\w+$', s) and len(a) == 2 and not s.endswith('_controlled'):
        W(0)
    elif s.startswith('cqrt_copy_') and s.endswith('_controlled') and len(a) == 3:
        R(0); R(1); W(2)
    elif re.match(r'^cqrt_xorc_\w+_controlled$', s) and len(a) == 3:
        R(0); W(1)  # bd dm7f.81: (ctrl, dst, classical imm)
    elif s.startswith('cqrt_copy_') and len(a) == 2:
        R(0); W(1)
    elif s == 'cqrt_cnot' and len(a) == 2:
        R(0); W(1)
    elif s == 'cqrt_toffoli' and len(a) == 3:
        R(0); R(1); W(2)
    elif s == 'cqrt_cswap' and len(a) == 3:
        R(0); W(1); W(2)
    elif s == 'cqrt_x' and len(a) == 1:
        W(0)
    elif re.match(r'^cqrt_(addc|xorc)_\w+$', s) and len(a) == 2:
        W(0)
    elif s == 'cqrt_free' and len(a) == 1:
        W(0)
    elif s.startswith('cqrt_measure_') and len(a) == 1:
        W(0)
    else:
        raise Refused(f"UNCLASSIFIED trace line, refusing to guess: {ev['line']!r}")
    for i in hpos:
        if a[i] not in reads and a[i] not in writes:
            raise Refused(f"handle operand in no classified slot: {ev['line']!r}")
    if r is not None and is_h(r):
        writes.add(r)
    ev['R'], ev['W'] = reads, writes
    return reads, writes


def contract(evs):
    """Collapse every BENNETT COPY-OUT — the pattern a Phase-6 clone's wrap emits:

        T(args) -> a          a forward producer, anywhere earlier
        ...                   nothing here may WRITE a handle among `args`
        cqrt_alloc_W(0) -> b  \\ adjacent
        cqrt_copy_W(a, b)     /
        ...
        T_unc(a, args)        exactly one, after the copy, SAME operand text
        ...
        cqrt_free(a)          exactly one, after the adjoint

    with `a` touched by NOTHING ELSE anywhere in the trace. It is rewritten to the
    one line `T(args) -> b` at T's position, and the alloc, copy, adjoint and free
    are deleted.

    SOUND, register by register: `b` is fresh |0>, so `b ^= a` leaves `b = T(args)`;
    the adjoint returns `a` to |0> because no operand of T was written between the
    two (checked), so its free is the reset of a |0> rail; nothing reads `a` except
    the copy, and nothing reads `b` before its alloc, so computing `T(args)` straight
    into `b` at T's position changes no value any other gate sees. A MULTI-template
    clone body contracts only its LAST link (the one the copy reads) — the rest of its
    scratch chain is ordinary forward/adjoint/free traffic the twin must reproduce,
    which is exactly the claim to be checked.

    RULE 2 (below, in the loop) is the dual: an inner `_unc` twin's
    recompute-copy-uncompute is the out-first adjoint `T_unc(x, args)`. Both rules
    are applied to BOTH traces until neither fires. Returns (events, contractions)."""
    k = 0
    while True:
        uses = {}
        for i, e in enumerate(evs):
            for t in e['args'] + ([e['ret']] if e['ret'] else []):
                if is_h(t):
                    uses.setdefault(t, []).append(i)
        hit = None
        for j in range(len(evs) - 1):
            al, cp = evs[j], evs[j + 1]
            if not (al['sym'].startswith('cqrt_alloc_') and al['args'] == ['0']
                    and is_h(al['ret'])):
                continue
            w = al['sym'][len('cqrt_alloc_'):]
            b = al['ret']
            if not (cp['sym'] == 'cqrt_copy_' + w and len(cp['args']) == 2
                    and cp['args'][1] == b and is_h(cp['args'][0])
                    and cp['args'][0] != b):
                continue
            a = cp['args'][0]
            ua = uses.get(a, [])
            if len(ua) != 4 or ua[1] != j + 1:
                continue            # a: mint, copy, adjoint, free — and nothing else
            i, u, f = ua[0], ua[2], ua[3]
            t, un, fr = evs[i], evs[u], evs[f]
            if not (is_fwd_producer(t['sym']) and not t['sym'].endswith('_unc')
                    and t['ret'] == a and i < j):
                continue
            if not (un['sym'] == t['sym'] + '_unc' and un['args'] == [a] + t['args']
                    and fr['sym'] == 'cqrt_free' and fr['args'] == [a]):
                continue
            if result_width(t['sym']) != w:
                continue            # the copy width must be the producer's RESULT width
            targs = {x for x in t['args'] if is_h(x)}
            clobbered = False
            for e in evs[i + 1:u]:
                effects(e)
                if e['W'] & targs:
                    clobbered = True
                    break
            if clobbered:
                continue
            hit = (i, j, u, f, b, t)
            break
        if hit is not None:
            i, j, u, f, b, t = hit
            ne = {'sym': t['sym'], 'args': list(t['args']), 'ret': b,
                  'line': f"{t['sym']}({', '.join(t['args'])}) -> {b}"}
            evs = [ne if x == i else e for x, e in enumerate(evs)
                   if x not in (j, j + 1, u, f)]
            k += 1
            continue
        # RULE 2 — ADJOINT BY RECOMPUTE: the body of a clone's `_unc` TWIN, which
        # zeroes its `out` by recomputing the value into a scratch rail and XOR-copying:
        #
        #     T(args) -> c          c touched by these four lines and NOTHING else
        #     cqrt_copy_W(c, x)     x != c, x not among args
        #     T_unc(c, args)        after the copy; SAME operand text
        #     cqrt_free(c)          after the adjoint
        #
        # is `x ^= T(args)` at the copy's position — exactly the out-first adjoint
        # `T_unc(x, args)` (DD-3: `f_unc(out, ops)` XORs `f(ops)` onto `out`). SOUND
        # for the same reason as rule 1: nothing writes a handle among `args` between
        # T and its adjoint (checked — the copy writes only `x`), so the value XORed at
        # the copy is T(args) and the scratch returns to |0> before its free.
        hit2 = None
        for j, cp in enumerate(evs):
            if not (cp['sym'].startswith('cqrt_copy_') and not cp['sym'].endswith('_controlled')
                    and len(cp['args']) == 2 and all(is_h(x) for x in cp['args'])
                    and cp['args'][0] != cp['args'][1]):
                continue
            w = cp['sym'][len('cqrt_copy_'):]
            c, x = cp['args']
            uc = uses.get(c, [])
            if len(uc) != 4 or uc[1] != j:
                continue
            i, u, f = uc[0], uc[2], uc[3]
            t, un, fr = evs[i], evs[u], evs[f]
            if not (is_fwd_producer(t['sym']) and not t['sym'].endswith('_unc')
                    and t['ret'] == c):
                continue
            if not (un['sym'] == t['sym'] + '_unc' and un['args'] == [c] + t['args']
                    and fr['sym'] == 'cqrt_free' and fr['args'] == [c]):
                continue
            if result_width(t['sym']) != w or x in t['args']:
                continue
            targs = {y for y in t['args'] if is_h(y)}
            clobbered = False
            for e in evs[i + 1:u]:
                effects(e)
                if e['W'] & targs:
                    clobbered = True
                    break
            if clobbered:
                continue
            hit2 = (i, j, u, f, x, t)
            break
        if hit2 is None:
            return evs, k
        i, j, u, f, x, t = hit2
        sym = t['sym'] + '_unc'
        args = [x] + list(t['args'])
        ne = {'sym': sym, 'args': args, 'ret': None,
              'line': f"{sym}({', '.join(args)})"}
        evs = [ne if y == j else e for y, e in enumerate(evs) if y not in (i, u, f)]
        k += 1


def label(ev):
    """The handle-free part of an event: symbol, literal args by position, the
    positions that are handles, and a non-handle return value (a measure's)."""
    lits = tuple((i, t) for i, t in enumerate(ev['args']) if not is_h(t))
    hpos = tuple(i for i, t in enumerate(ev['args']) if is_h(t))
    rv = None if ev['ret'] is None or is_h(ev['ret']) else ev['ret']
    return (ev['sym'], len(ev['args']), lits, hpos, rv, is_h(ev['ret']))


# The Q+Q templates whose two HANDLE operands commute on the VALUE — `a+b`, `a*b`,
# `a^b`, `a&b`, `a|b` — spelled with NO shape suffix (a `_hl`/`_lh` form has one
# handle and one literal, nothing to swap). Their out-first adjoint commutes in
# slots 1 and 2. `clang -O1` canonicalizes a commutative operand pair by operand
# COMPLEXITY, so a call result and an inlined instruction can land in either order;
# refusing the swap would make this tool report DIFF on the same circuit. `sub` and
# every compare are deliberately absent.
COMMUTATIVE = re.compile(r'^cq_template_(add|mul|xor|and|or)_i\d+(_unc)?$')


def arg_orders(ev):
    n = len(ev['args'])
    ident = list(range(n))
    m = COMMUTATIVE.match(ev['sym'])
    if not m:
        return [ident]
    a, b = (1, 2) if m.group(2) else (0, 1)
    if n != b + 1 or not (is_h(ev['args'][a]) and is_h(ev['args'][b])):
        return [ident]
    sw = list(ident)
    sw[a], sw[b] = sw[b], sw[a]
    return [ident, sw]


def dependent(e, f):
    return bool((e['W'] & (f['R'] | f['W'])) | (f['W'] & e['R']))


def equivalent(A, B, budget=200000):
    """Trace equivalence up to handle renaming. True / False / None (budget)."""
    if len(A) != len(B):
        return False
    for e in A + B:
        effects(e)
    LA = [label(e) for e in A]
    LB = [label(e) for e in B]
    if sorted(map(repr, LA)) != sorted(map(repr, LB)):
        return False
    n = len(A)
    used = [False] * n
    fwd, bwd = {}, {}
    steps = [0]

    def bind(ea, eb, perm):
        """Try to extend the renaming with ea's handles -> eb's, B's arguments read
        through `perm`. Returns the list of NEW bindings (to undo) or None."""
        new = []
        bargs = [eb['args'][k] for k in perm]
        pairs = [(x, y) for x, y in zip(ea['args'], bargs) if is_h(x) or is_h(y)]
        if is_h(ea['ret']) or is_h(eb['ret']):
            pairs.append((ea['ret'], eb['ret']))
        for x, y in pairs:
            if not (is_h(x) and is_h(y)):
                for u in new:
                    del bwd[fwd.pop(u)]
                return None
            if x in fwd:
                if fwd[x] != y:
                    for u in new:
                        del bwd[fwd.pop(u)]
                    return None
            elif y in bwd:
                for u in new:
                    del bwd[fwd.pop(u)]
                return None
            else:
                fwd[x] = y
                bwd[y] = x
                new.append(x)
        return new

    def rec(i):
        steps[0] += 1
        if steps[0] > budget:
            raise TimeoutError
        if i == n:
            return True
        ea = A[i]
        for j in range(n):
            if used[j] or LB[j] != LA[i]:
                continue
            eb = B[j]
            # B[j] can be commuted to the front of B's remaining word iff it is
            # independent of every EARLIER unconsumed event of B.
            if any((not used[k]) and dependent(B[k], eb) for k in range(j)):
                continue
            for perm in arg_orders(ea):
                new = bind(ea, eb, perm)
                if new is None:
                    continue
                used[j] = True
                if rec(i + 1):
                    return True
                used[j] = False
                for u in new:
                    del bwd[fwd.pop(u)]
        return False

    try:
        return rec(0)
    except TimeoutError:
        return None


XORC_ZERO = re.compile(r'^cqrt_xorc_([if])\d+(?:_controlled)?$')
FP_ZERO_BITS = re.compile(r'^0x0+$')


def is_zero_xorc(e):
    """A controlled or plain xor-immediate whose immediate is the LITERAL zero: the
    integer `0`, or (fp, printed as its exact bit pattern since dm7f.81 R11 A-F1)
    an all-zero hex pattern — +0.0 only; -0.0 is `0x8000…` and is not zero."""
    m = XORC_ZERO.match(e['sym'])
    if not m or not e['args']:
        return False
    imm = e['args'][-1]
    return imm == '0' if m.group(1) == 'i' else bool(FP_ZERO_BITS.match(imm))


def drop_zero_xorc(evs):
    """RULE 3 (bd dm7f.81; owner ruling ruling-dm7f81-open-qs-2026-10-15 Q2) — a
    `cqrt_xorc_<W>[_controlled](…, imm)` whose immediate is the LITERAL zero is the
    identity (h ^= 0, under any control) and is deleted from BOTH traces before the
    comparison (`is_zero_xorc`). Why: a rolled loop's trip prints `xorc(…, 0)` from a
    RUNTIME counter that is 0 on that trip, while its unrolled twin sees the
    constant 0 and emits no gate (the constant-zero arm skip, MergeArmWrite.cpp)
    — and no ¬flag bracket either: so when the deleted gate is the controlled form
    and sits EXACTLY between `cqrt_x(f)` and `cqrt_x(f)` on its own control `f`,
    that now-empty bracket pair goes with it (R11 C-F4; x(f) x(f) is the identity).
    Same unitary, different bytes."""
    out, i = [], 0
    while i < len(evs):
        e = evs[i]
        if is_zero_xorc(e):
            f = e['args'][0] if e['sym'].endswith('_controlled') else None
            if (f is not None and out and out[-1]['sym'] == 'cqrt_x' and out[-1]['args'] == [f]
                    and i + 1 < len(evs) and evs[i + 1]['sym'] == 'cqrt_x'
                    and evs[i + 1]['args'] == [f]):
                out.pop(); i += 2; continue
            i += 1; continue
        out.append(e); i += 1
    return out


def compare_bytes_after_rule3(ta, tb):
    """The STRICT relation the dm7f.81 twin gates use (`--zero-xorc-then-bytes`,
    R11 B-F1): RULE 3 only, then the remaining lines must be byte-identical — no
    reordering, no renaming, no rule-1/2 contraction. "Byte-identical" is over the
    PARSED lines: each line is compared after `strip()` (leading/trailing
    whitespace ignored) and blank lines are dropped (`parse`); every other byte,
    the line order and the handle names must match exactly."""
    A = [e['line'] for e in drop_zero_xorc(parse(ta.splitlines()))]
    B = [e['line'] for e in drop_zero_xorc(parse(tb.splitlines()))]
    if not A or not B:
        return 'VACUOUS'
    return 'IDENTICAL' if A == B else 'DIFF'


def compare_text(ta, tb):
    A = drop_zero_xorc(parse(ta.splitlines()))
    B = drop_zero_xorc(parse(tb.splitlines()))
    if not A or not B:
        return 'VACUOUS', 0, 0
    A, ka = contract(A)
    B, kb = contract(B)
    r = equivalent(A, B)
    return ('EQUIV' if r else 'DIFF' if r is False else 'UNDECIDED'), ka, kb


# ── BOUNDARY CONTROLS ───────────────────────────────────────────────────────
_D4_ORACLE = """cqrt_alloc_i32(5) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_mul_i32_hl(h0, 3) -> h1
cq_template_xor_i32(h0, h1) -> h2
cq_template_add_i32_hl(h0, 1) -> h3
cqrt_alloc_i32(0) -> h4
cqrt_copy_i32(h3, h4)
cq_template_add_i32_hl_unc(h3, h0, 1)
cqrt_free(h3)
cq_template_icmp_eq_i32_hl(h2, 10) -> h5
cqrt_rz_i1(h5, 0x1.921f9f01b866ep+1)
cq_template_icmp_eq_i32_hl_unc(h5, h2, 10)
cqrt_free(h5)
cqrt_measure_i32(h4) -> 0
cqrt_ry_i32(h0, 0x1.6666666666666p-1)
cqrt_measure_i32(h0) -> 0
"""
_D4_TWIN = """cqrt_alloc_i32(5) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_mul_i32_hl(h0, 3) -> h1
cq_template_xor_i32(h0, h1) -> h2
cq_template_icmp_eq_i32_hl(h2, 10) -> h3
cqrt_rz_i1(h3, 0x1.921f9f01b866ep+1)
cq_template_icmp_eq_i32_hl_unc(h3, h2, 10)
cq_template_xor_i32_unc(h2, h0, h1)
cqrt_free(h2)
cq_template_mul_i32_hl_unc(h1, h0, 3)
cqrt_free(h1)
cqrt_free(h3)
cq_template_add_i32_hl(h0, 1) -> h4
cqrt_measure_i32(h4) -> 0
cqrt_ry_i32(h0, 0x1.6666666666666p-1)
cqrt_measure_i32(h0) -> 0
"""
# The discharged stream the fix must produce: the chain's `_unc`s and frees land
# after the strip, the clone block stays where the call was written.
_D4_FIXED = """cqrt_alloc_i32(5) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_mul_i32_hl(h0, 3) -> h1
cq_template_xor_i32(h0, h1) -> h2
cq_template_add_i32_hl(h0, 1) -> h3
cqrt_alloc_i32(0) -> h4
cqrt_copy_i32(h3, h4)
cq_template_add_i32_hl_unc(h3, h0, 1)
cqrt_free(h3)
cq_template_icmp_eq_i32_hl(h2, 10) -> h5
cqrt_rz_i1(h5, 0x1.921f9f01b866ep+1)
cq_template_icmp_eq_i32_hl_unc(h5, h2, 10)
cq_template_xor_i32_unc(h2, h0, h1)
cqrt_free(h2)
cq_template_mul_i32_hl_unc(h1, h0, 3)
cqrt_free(h1)
cqrt_free(h5)
cqrt_measure_i32(h4) -> 0
cqrt_ry_i32(h0, 0x1.6666666666666p-1)
cqrt_measure_i32(h0) -> 0
"""


_RZ_READ = """cqrt_alloc_i32(1) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_rz_i32(h0, 0x1p-2)
cq_template_mul_i32_hl(h0, 3) -> h1
cqrt_measure_i32(h1) -> 0
"""
_ALLOCS = """cqrt_alloc_i32(1) -> h0
cqrt_alloc_i32(0) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_copy_i32(h0, h1)
cqrt_x(h2)
cqrt_measure_i32(h1) -> 0
cqrt_measure_i32(h2) -> 0
"""


_CLOB_S = """cqrt_alloc_i32(1) -> h0
cq_template_add_i32_hl(h0, 1) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_copy_i32(h1, h2)
cqrt_ry_i32(h0, 0x1p-3)
cq_template_add_i32_hl_unc(h1, h0, 1)
cqrt_free(h1)
cqrt_measure_i32(h2) -> 0
"""
_CLOB_T = """cqrt_alloc_i32(1) -> h0
cq_template_add_i32_hl(h0, 1) -> h1
cqrt_ry_i32(h0, 0x1p-3)
cqrt_measure_i32(h1) -> 0
"""
_MULTI_S = """cqrt_alloc_i32(1) -> h0
cq_template_mul_i32_hl(h0, 5) -> h1
cq_template_add_i32_hl(h1, 3) -> h2
cqrt_alloc_i32(0) -> h3
cqrt_copy_i32(h2, h3)
cq_template_add_i32_hl_unc(h2, h1, 3)
cq_template_mul_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_free(h2)
cqrt_measure_i32(h3) -> 0
"""
_MULTI_T = """cqrt_alloc_i32(1) -> h0
cq_template_mul_i32_hl(h0, 5) -> h1
cq_template_add_i32_hl(h1, 3) -> h2
cq_template_mul_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h2) -> 0
"""


_REC_S = """cqrt_alloc_i32(1) -> h0
cq_template_mul_i32_hl(h0, 5) -> h1
cq_template_mul_i32_hl(h0, 5) -> h2
cqrt_copy_i32(h2, h1)
cq_template_mul_i32_hl_unc(h2, h0, 5)
cqrt_free(h2)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0
"""
_REC_T = """cqrt_alloc_i32(1) -> h0
cq_template_mul_i32_hl(h0, 5) -> h1
cq_template_mul_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0
"""
_REC_CLOB_S = """cqrt_alloc_i32(1) -> h0
cq_template_mul_i32_hl(h0, 5) -> h1
cq_template_mul_i32_hl(h0, 5) -> h2
cqrt_copy_i32(h2, h1)
cqrt_ry_i32(h0, 0x1p-3)
cq_template_mul_i32_hl_unc(h2, h0, 5)
cqrt_free(h2)
cqrt_free(h1)
"""
_REC_CLOB_T = """cqrt_alloc_i32(1) -> h0
cq_template_mul_i32_hl(h0, 5) -> h1
cq_template_mul_i32_hl_unc(h1, h0, 5)
cqrt_ry_i32(h0, 0x1p-3)
cqrt_free(h1)
"""


def _t(*lines):
    return '\n'.join(lines) + '\n'


_A9_S = _t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)',
           'cq_template_sext_i32_to_i64(h0) -> h1', 'cqrt_alloc_i32(0) -> h2',
           'cqrt_copy_i32(h1, h2)', 'cq_template_sext_i32_to_i64_unc(h1, h0)', 'cqrt_free(h1)',
           'cqrt_x(h2)', 'cqrt_free(h2)')
_A9_T = _t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)',
           'cq_template_sext_i32_to_i64(h0) -> h1', 'cqrt_x(h1)', 'cqrt_free(h1)')
_A18_S = _t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)', 'cq_template_add_i32_hl(h0, 1) -> h1',
            'cqrt_alloc_i32(1) -> h2', 'cqrt_copy_i32(h1, h2)',
            'cq_template_add_i32_hl_unc(h1, h0, 1)', 'cqrt_measure_i32(h2) -> 0',
            'cqrt_ry_i32(h0, 0x1p-2)', 'cqrt_measure_i32(h0) -> 0', 'cqrt_free(h1)')
_A18_T = _t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)', 'cq_template_add_i32_hl(h0, 1) -> h1',
            'cqrt_measure_i32(h1) -> 0', 'cqrt_ry_i32(h0, 0x1p-2)', 'cqrt_measure_i32(h0) -> 0')
_REC_W_S = _t('cqrt_alloc_i32(1) -> h0', 'cq_template_sext_i32_to_i64(h0) -> h1',
              'cq_template_sext_i32_to_i64(h0) -> h2', 'cqrt_copy_i32(h2, h1)',
              'cq_template_sext_i32_to_i64_unc(h2, h0)', 'cqrt_free(h2)', 'cqrt_free(h1)')
_REC_W_T = _t('cqrt_alloc_i32(1) -> h0', 'cq_template_sext_i32_to_i64(h0) -> h1',
              'cq_template_sext_i32_to_i64_unc(h1, h0)', 'cqrt_free(h1)')
# RULE 3 controls (bd dm7f.81): a literal-zero controlled xor-immediate is the
# identity; a nonzero one, and fp -0.0, are not.
_Z_PRE = ['cqrt_alloc_i1(0) -> h0', 'cqrt_ry_i1(h0, 0x1p-1)']
_Z_T = _t(*_Z_PRE, 'cqrt_alloc_i32(0) -> h1', 'cqrt_measure_i32(h1) -> 0')
_Z_S = _t(*_Z_PRE, 'cqrt_alloc_i32(0) -> h1', 'cqrt_xorc_i32_controlled(h0, h1, 0)',
          'cqrt_measure_i32(h1) -> 0')
_ZF_T = _t(*_Z_PRE, 'cqrt_alloc_f64(0x0p+0) -> h1', 'cqrt_measure_f64(h1) -> 0x0p+0')
_ZF_S = _t(*_Z_PRE, 'cqrt_alloc_f64(0x0p+0) -> h1',
           'cqrt_xorc_f64_controlled(h0, h1, 0x0000000000000000)',
           'cqrt_measure_f64(h1) -> 0x0p+0')
# C-F4: the zero write's own ¬flag bracket, now empty, goes with it ...
_ZB_S = _t(*_Z_PRE, 'cqrt_alloc_i32(0) -> h1', 'cqrt_x(h0)',
           'cqrt_xorc_i32_controlled(h0, h1, 0)', 'cqrt_x(h0)', 'cqrt_measure_i32(h1) -> 0')
# ... but an x(f); x(f) pair that never bracketed a zero write is NOT rule 3's.
_ZX_S = _t(*_Z_PRE, 'cqrt_alloc_i32(0) -> h1', 'cqrt_x(h0)', 'cqrt_x(h0)',
           'cqrt_measure_i32(h1) -> 0')
_U12_S = _t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(0) -> h1',
            'cqrt_copy_i32(h0, h1)', 'cqrt_measure_i32(h0) -> 0', 'cqrt_free(h1)')
_U12_T = _t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(0) -> h1',
            'cqrt_measure_i32(h0) -> 0', 'cqrt_copy_i32(h0, h1)', 'cqrt_free(h1)')
_U13_S = _t('cqrt_cnot(h0, h1)', 'cqrt_cnot(h0, h2)')
_U13_T = _t('cqrt_cnot(h0, h1)', 'cqrt_cnot(h0, h1)')
_A12_S = _t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(3) -> h1',
            'cq_template_icmp_ult_i32(h0, h1) -> h2', 'cqrt_measure_i1(h2) -> 0')
_WS_PRE = ['cqrt_alloc_i1(1) -> h0', 'cqrt_alloc_i32(5) -> h1', 'cqrt_alloc_i32(3) -> h2']
_WRITE_SLOT_ROWS = []
for _nm, _g in [('A22-cnot-target', 'cqrt_cnot(h0, h1)'),
                ('A23-toffoli-target', 'cqrt_toffoli(h0, h2, h1)'),
                ('A24-cswap-target', 'cqrt_cswap(h0, h1, h2)'),
                ('A25-ccopy-dst', 'cqrt_copy_i32_controlled(h0, h2, h1)'),
                ('A26-cry-target', 'cqrt_ry_i32_controlled(h0, h1, 0x1p-1)'),
                ('A27-addc', 'cqrt_addc_i32(h1, 4)'),
                ('A28-xorc', 'cqrt_xorc_i32(h1, 4)'),
                ('A29-cxorc-dst', 'cqrt_xorc_i32_controlled(h0, h1, 4)')]:
    _rd = 'cq_template_add_i32_hl(h1, 1) -> h9'
    _WRITE_SLOT_ROWS.append((_nm, _t(*_WS_PRE, _g, _rd, 'cqrt_measure_i32(h9) -> 0'),
                             _t(*_WS_PRE, _rd, _g, 'cqrt_measure_i32(h9) -> 0')))


def _swap(t, i, j):
    L = t.splitlines()
    L[i], L[j] = L[j], L[i]
    return '\n'.join(L) + '\n'


def _move(t, i, j):
    L = t.splitlines()
    x = L.pop(i)
    L.insert(j, x)
    return '\n'.join(L) + '\n'


def _drop(t, i):
    L = t.splitlines()
    del L[i]
    return '\n'.join(L) + '\n'


def _sub(t, a, b):
    assert a in t, a
    return t.replace(a, b, 1)


CONTROLS = [
    # (name, subject, twin, expected verdict)
    ("null-self", _D4_TWIN, _D4_TWIN, 'EQUIV'),
    ("null-empty", "", _D4_TWIN, 'VACUOUS'),
    ("rename-only", _D4_TWIN,
     _D4_TWIN.replace('h1', 'hX').replace('h2', 'h1').replace('hX', 'h2'), 'EQUIV'),
    # THE DEFECT ITSELF must be DIFF: the oracle's d4 stream has no chain adjoints.
    ("rhk5-oracle-defect", _D4_ORACLE, _D4_TWIN, 'DIFF'),
    # the stream the fix must produce is EQUIV to the twin.
    ("rhk5-fixed-shape", _D4_FIXED, _D4_TWIN, 'EQUIV'),
    # gates on DISJOINT handles commute (free(h3) vs add(h0)->h4).
    ("indep-commute", _D4_TWIN, _swap(_D4_TWIN, 12, 11), 'EQUIV'),
    # READS of a shared handle commute: `add(h0)->h4` moved up across
    # `xor_unc(h2, h0, h1)` and `mul_unc(h1, h0, 3)`, which READ h0 too.
    ("reads-commute", _D4_TWIN, _move(_D4_TWIN, 12, 4), 'EQUIV'),
    # a read of h0 must NOT cross the Ry that writes it.
    ("read-vs-ry", _D4_TWIN, _swap(_D4_TWIN, 1, 2), 'DIFF'),
    # ...in either direction: the clone-result read moved BELOW the second Ry.
    ("read-below-ry", _D4_TWIN, _move(_D4_TWIN, 12, 14), 'DIFF'),
    # a measure is a WRITE: it may not cross the Ry on the same rail.
    ("ry-vs-measure", _D4_TWIN, _swap(_D4_TWIN, 14, 15), 'DIFF'),
    # a free moved above the last use of its rail.
    ("free-before-use", _D4_TWIN, _swap(_D4_TWIN, 8, 7), 'DIFF'),
    # an adjoint WRITES its out slot: the strip (a read of h2) may not cross the
    # `xor_unc` that zeroes h2. (Added when the checker mutant "an `_unc` only READS
    # its out slot" survived every other control — L10.)
    ("unc-writes-out", _D4_TWIN, _swap(_D4_TWIN, 6, 7), 'DIFF'),
    # a changed LITERAL.
    ("literal", _D4_TWIN, _sub(_D4_TWIN, 'mul_i32_hl(h0, 3)', 'mul_i32_hl(h0, 5)'), 'DIFF'),
    # a changed ANGLE.
    ("angle", _D4_TWIN, _sub(_D4_TWIN, '0x1.6666666666666p-1', '0x1.6666666666667p-1'), 'DIFF'),
    # a dropped adjoint.
    ("drop-unc", _D4_TWIN, _drop(_D4_TWIN, 9), 'DIFF'),
    # an operand ROLE swap into the adjoint's OUT slot (it would zero the parent
    # instead of the chain rail). (A swap of a commutative pair is NOT a role swap —
    # see `commutative-xor`; the first spelling of this control used one and went
    # EQUIV, correctly, once commutativity was modelled.)
    ("role-swap", _D4_TWIN, _sub(_D4_TWIN, 'xor_i32_unc(h2, h0, h1)',
                                 'xor_i32_unc(h0, h2, h1)'), 'DIFF'),
    # a forward operand swap in ONLY the forward half of a commutative pair is still
    # the same circuit (a^b = b^a, and the adjoint recomputes the same value).
    ("commutative-fwd-only", _D4_TWIN, _sub(_D4_TWIN, 'xor_i32(h0, h1)', 'xor_i32(h1, h0)'),
     'EQUIV'),
    # an Rz is conservatively a WRITE: it may not cross a read of its rail
    # (physically it would commute with a read-as-control; refusing is the safe
    # direction, and this control pins that the model stays conservative).
    ("rz-conservative", _RZ_READ, _swap(_RZ_READ, 2, 3), 'DIFF'),
    # ...and handle MATCHING must backtrack past a wrong first guess between two
    # identical-looking `alloc(0)` mints.
    ("alloc-backtrack", _ALLOCS, _swap(_ALLOCS, 1, 2), 'EQUIV'),
    # a Bennett block whose adjoint reads DIFFERENT args is not contracted.
    ("bennett-bad-unc", _sub(_D4_FIXED, 'add_i32_hl_unc(h3, h0, 1)', 'add_i32_hl_unc(h3, h0, 2)'),
     _D4_TWIN, 'DIFF'),
    # a Bennett block whose scratch is used again elsewhere is not contracted.
    ("bennett-scratch-reused", _sub(_D4_FIXED, 'cqrt_measure_i32(h4) -> 0',
                                    'cqrt_measure_i32(h3) -> 0'), _D4_TWIN, 'DIFF'),
    # a Bennett block whose FREE precedes its adjoint is not contracted.
    ("bennett-free-first", _swap(_D4_FIXED, 7, 8), _D4_TWIN, 'DIFF'),
    # a NON-CONTIGUOUS block (an unrelated gate between copy and adjoint) IS.
    ("bennett-noncontig", _move(_D4_FIXED, 9, 7), _D4_TWIN, 'EQUIV'),
    # ...but NOT when the gate in between WRITES the producer's operand: the
    # adjoint would recompute from a relabelled register. If this contracted, the
    # two traces below would compare EQUIV.
    ("bennett-clobbered", _CLOB_S, _CLOB_T, 'DIFF'),
    # a MULTI-template clone chain contracts its last link; the twin discharging
    # the rest of the chain is then the same circuit ...
    ("bennett-multi", _MULTI_S, _MULTI_T, 'EQUIV'),
    # ... and a twin that LEAVES the chain allocated is not.
    ("bennett-multi-leak", _MULTI_S, _drop(_drop(_MULTI_T, 3), 2), 'DIFF'),
    # a COMMUTATIVE Q+Q template may name its operands in either order ...
    ("commutative-xor", _D4_TWIN, _sub(_D4_TWIN, 'xor_i32(h0, h1)', 'xor_i32(h1, h0)')
     .replace('xor_i32_unc(h2, h0, h1)', 'xor_i32_unc(h2, h1, h0)'), 'EQUIV'),
    # ... but a NON-commutative one may not.
    ("noncommutative-sub", _D4_TWIN.replace('xor_i32', 'sub_i32'),
     _D4_TWIN.replace('xor_i32', 'sub_i32').replace('sub_i32(h0, h1)', 'sub_i32(h1, h0)')
     .replace('sub_i32_unc(h2, h0, h1)', 'sub_i32_unc(h2, h1, h0)'), 'DIFF'),
    # RULE 2: an inner `_unc` twin's recompute-copy-uncompute IS `T_unc(x, args)`.
    ("recompute-adjoint", _REC_S, _REC_T, 'EQUIV'),
    # ...but NOT when the producer's operand is written before its adjoint (if this
    # contracted, the two traces would compare EQUIV).
    ("recompute-clobbered", _REC_CLOB_S, _REC_CLOB_T, 'DIFF'),
    # ── bd rhk5 round 2: Rule-13 reviewer r1B's attack rows, adopted (F-r1B-2/-3).
    # A9: a Bennett block whose COPY width is the cast's SOURCE width (i32) while the
    # producer's RESULT is i64 — a 32-bit copy of a 64-bit rail. The first spelling
    # of rule 1's width test was a SUBSTRING match and contracted it (a false EQUIV).
    ("r1B-A9-width-cast", _A9_S, _A9_T, 'DIFF'),
    # The same width hole in RULE 2: a recompute whose XOR-copy is narrower than the
    # recomputed rail is not `T_unc(x, args)`. (Found by this tool's own checker
    # mutant T10, which survived every control after r1B's A9 was adopted.)
    ("recompute-width-cast", _REC_W_S, _REC_W_T, 'DIFF'),
    # RULE 3 (bd dm7f.81): `xorc(…, 0)` is the identity and is deleted ...
    ("rule3-zero-xorc", _Z_S, _Z_T, 'EQUIV'),
    # ... a NONZERO immediate is a real flip and stays ...
    ("rule3-nonzero-stays", _Z_S.replace('h1, 0)', 'h1, 4)'), _Z_T, 'DIFF'),
    # ... the fp all-zero pattern +0.0 is deleted ...
    ("rule3-fp-plus-zero", _ZF_S, _ZF_T, 'EQUIV'),
    # ... and -0.0 (the sign bit) is NOT zero.
    ("rule3-fp-minus-zero", _ZF_S.replace('h1, 0x0000000000000000)', 'h1, 0x8000000000000000)'),
     _ZF_T, 'DIFF'),
    # ... the empty ¬flag bracket around a deleted zero write is deleted too ...
    ("rule3-zero-bracket", _ZB_S, _Z_T, 'EQUIV'),
    # ... but a bare x(f); x(f) pair is not (rule 3 deletes only what it owns).
    ("rule3-bare-x-pair-stays", _ZX_S, _Z_T, 'DIFF'),
    # ── bd rhk5 round 3 (Rule-13 r2B F-r2B-1): two conjuncts that were correct but
    # pinned by NO control — r1B's checker mutants U12 and U13 survived every control
    # above. Both pairs are r2B's (review_r2B_rhk5/probes/checker/width_battery.py and
    # REVIEW.md Q5), measured to flip to EQUIV under exactly one mutant each
    # (rhk5_probes/tools/u12_u13_probe.py).
    # U12: a MEASURE is a collapse, not a read — reordering it past a copy that READS
    # the same rail changes the circuit.
    ("r2B-U12-measure-past-copy-src", _U12_S, _U12_T, 'DIFF'),
    # U13: the handle renaming must be INJECTIVE — two gates on two distinct targets
    # are not one gate twice on one target. (The pair has no mints on purpose: a mint
    # binds the name first, and then forward consistency alone decides — r2B's first,
    # alloc-first spelling did not reach the conjunct.)
    ("r2B-U13-renaming-injective", _U13_S, _U13_T, 'DIFF'),
    # A18: the copy-out scratch `b` does not start at |0> (alloc(1)).
    ("r1B-A18-copyout-nonzero", _A18_S, _A18_T, 'DIFF'),
    # A12: a compare's two handle operands swapped — `ult` is not symmetric, so the
    # commutativity table must NOT cover a compare (r1B's mutant U14 survived every
    # control before this row).
    ("r1B-A12-icmp-operand-swap", _A12_S, _A12_S.replace('ult_i32(h0, h1)', 'ult_i32(h1, h0)'),
     'DIFF'),
    # A22–A28: one WRITE slot of each classification row no other control touches,
    # reordered across a READ of the same rail — each must be DIFF.
] + [(f"r1B-{nm}", a, b, 'DIFF') for nm, a, b in _WRITE_SLOT_ROWS]


# STRICT-MODE controls (--zero-xorc-then-bytes, R11 B-F1), counted in main().
STRICT_CONTROLS = [
    ("strict-zero-xorc", _Z_S, _Z_T, 'IDENTICAL'),
    ("strict-zero-bracket", _ZB_S, _Z_T, 'IDENTICAL'),
    ("strict-nonzero", _Z_S.replace('h1, 0)', 'h1, 4)'), _Z_T, 'DIFF'),
    ("strict-rename", _Z_T, _Z_T.replace('h1', 'h7'), 'DIFF'),
    ("strict-reorder", _t('cqrt_alloc_i1(0) -> h0', 'cqrt_alloc_i1(0) -> h1',
                          'cqrt_x(h0)', 'cqrt_x(h1)'),
     _t('cqrt_alloc_i1(0) -> h0', 'cqrt_alloc_i1(0) -> h1',
        'cqrt_x(h1)', 'cqrt_x(h0)'), 'DIFF'),
]


def selftest(verbose=True):
    ok = True
    for name, s, t, want in CONTROLS:
        try:
            got, ka, kb = compare_text(s, t)
        except Refused as e:
            got, ka, kb = 'REFUSED:' + str(e), 0, 0
        good = got == want
        ok &= good
        if verbose or not good:
            print(f"  [{'ok ' if good else 'FAIL'}] control {name:24s} {got:9s} "
                  f"(want {want}; contracted {ka}/{kb})")
    # STRICT MODE (--zero-xorc-then-bytes, R11 B-F1): rule 3, then bytes. A zero
    # write vanishes; a REORDER or a RENAME that the full relation accepts does not.
    for name, s, t2, want in STRICT_CONTROLS:
        got = compare_bytes_after_rule3(s, t2)
        good = got == want
        ok &= good
        if verbose or not good:
            print(f"  [{'ok ' if good else 'FAIL'}] control {name:24s} {got:9s} (want {want})")
    # UNCLASSIFIED must be refused, never guessed.
    try:
        compare_text("cqrt_bogus(h0)\n", "cqrt_bogus(h0)\n")
        print("  [FAIL] control unclassified            accepted an unknown symbol")
        ok = False
    except Refused:
        if verbose:
            print("  [ok ] control unclassified            REFUSED")
    return ok


def main(argv):
    verbose = '--quiet-controls' not in argv
    args = [a for a in argv[1:] if not a.startswith('--')]
    print("BOUNDARY CONTROLS (run on EVERY invocation, before any real measurement):")
    if not selftest(verbose):
        print("!! CONTROLS FAILED -- the instrument is measuring itself, not the traces.")
        return 2
    nctl = len(CONTROLS) + len(STRICT_CONTROLS) + 1   # + the unclassified refusal
    print(f"  controls: {nctl}/{nctl} as pinned\n")
    if '--selftest' in argv:
        return 0
    if len(args) != 2:
        print("!! need exactly SUBJECT.trace TWIN.trace -- refusing to report a vacuous pass.")
        return 2
    try:
        with open(args[0]) as f:
            ta = f.read()
        with open(args[1]) as f:
            tb = f.read()
        if '--zero-xorc-then-bytes' in argv:
            v = compare_bytes_after_rule3(ta, tb)
            print(f"{os.path.basename(args[0])} vs {os.path.basename(args[1])}: {v} "
                  f"(strict: rule 3, then byte identity)")
            return 0 if v == 'IDENTICAL' else 1 if v == 'DIFF' else 2
        verdict, ka, kb = compare_text(ta, tb)
    except Refused as e:
        print(f"REFUSED: {e}")
        return 2
    print(f"{os.path.basename(args[0])} vs {os.path.basename(args[1])}: {verdict} "
          f"(Bennett blocks contracted: subject {ka}, twin {kb})")
    if '--show' in argv:
        for tag, t in (('SUBJECT', ta), ('TWIN', tb)):
            evs, _ = contract(parse(t.splitlines()))
            print(f"--- {tag} after contraction ({len(evs)} lines)")
            for e in evs:
                print('   ', e['line'])
    return 0 if verdict == 'EQUIV' else 1 if verdict == 'DIFF' else 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
