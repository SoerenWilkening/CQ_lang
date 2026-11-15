"""Reading a lowered function's control flow for the tests of tests/loops-cutoff (cq-9kcq): how often a call site runs.
A K-loop runs one trip K times in a generated classical loop

    H: %j = phi i32 [ 0, %pre ], [ %j1, %L ] ...      L: %j1 = add i32 %j, 1
                                                         %c = icmp ult i32 %j1, N
                                                         br i1 %c, label %H, label %exit

and undoes the trips in a reverse loop (exited by a switch on a popped value). Where the bound is a run-time value or 0
(cq-9kcq S6c: a received K, K = 0) the counter test is also made before trip 0, and a trip runs N times, none for N = 0:

    pre: %g = icmp ult i32 0, N                       (%g may be `and i1` with a classical trip-0 conjunct)
         br i1 %g, label %H, label %exit              (the same exit block as the latch's)
With two tests per trip (cq-9kcq S7, 189: a header test region and an exit from the body) the counter's br goes on to the
header test region R, which goes back to H: R runs after every trip but the last (N - 1 times; its blocks are the trip
loop's `after`):

    L: br i1 %c, label %R, label %exit        R: ... br label %H        (H: %j = phi i32 [ 0, %pre ], [ %j1, %R ])

N is evaluated with no received K
(@__cq_k all ones, owner ruling Q2: -1 is "none"; a table clone's K parameter, its last one, likewise), which is the
function's own K. A cycle with neither shape is a loop of the C program (a classically bounded loop): a site in it is
counted once per iteration of that loop, i.e. once.
"""
import re


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def blocks(fn_body: str):
    """{label: (instruction lines, successor labels)} of one lowered function, and the labels in text order."""
    out, order = {}, []
    for line in fn_body.splitlines()[1:]:
        m = re.match(r"^([-\w.$]+):", line)
        if m or not order:
            order.append(m.group(1) if m else "<entry>")
            out[order[-1]] = ([], [])
            if m:
                continue
        if line.startswith("}"):
            break
        if line.strip():
            out[order[-1]][0].append(line)
            out[order[-1]][1].extend(re.findall(r"label %([-\w.$]+)", line))
    return out, order


def reach(bl, frm):
    seen, todo = set(), list(bl[frm][1])
    while todo:
        x = todo.pop()
        if x not in seen and x in bl:
            seen.add(x)
            todo.extend(bl[x][1])
    return seen


def defs(fn_body: str):
    return {m.group(1): m.group(2) for m in re.finditer(r"^\s*(%[-\w.$]+) = (.*)$", fn_body, re.M)}


def table_k_param(fn_body: str):
    """A table clone's received-K parameter (its last i32 parameter), or None."""
    head = fn_body.splitlines()[0] if fn_body else ""
    params = re.findall(r"i32 (%[-\w.$]+)", head)
    return params[-1] if "_t" in head.split("(")[0] and params else None


# The value read for a table clone's K parameter (table_k_param): -1, none, by default (its own K is not in the IR, so a
# trip loop bounded by it has no N); run_probes.py --table-k sets the K its dispatch passes where no K is received (the
# caller's own K), for a count in a rolled table clone (cq-9kcq).
TABLE_K = -1


def value(d, v: str, depth=0, tableK=None):
    """The integer v holds with no received K (@__cq_k = -1, a table clone's K parameter TABLE_K), or None."""
    if re.fullmatch(r"-?\d+", v):
        return int(v)
    if tableK is not None and v == tableK:
        return TABLE_K
    rhs = d.get(v)
    if rhs is None or depth > 32:
        return None
    if re.fullmatch(r"load i32, ptr @__cq_k(?:, align \d+)?", rhs):
        return -1
    ev = lambda x: value(d, x, depth + 1, tableK)
    m = re.fullmatch(r"icmp (eq|ne|ult|slt) i32 (\S+), (\S+)", rhs)
    if m:
        a, b = ev(m.group(2)), ev(m.group(3))
        if a is None or b is None:
            return None
        u = lambda x: x & 0xFFFFFFFF
        s = lambda x: u(x) - (1 << 32) if u(x) >> 31 else u(x)
        return int({"eq": u(a) == u(b), "ne": u(a) != u(b), "ult": u(a) < u(b), "slt": s(a) < s(b)}[m.group(1)])
    m = re.fullmatch(r"select i1 (\S+), i32 (\S+), i32 (\S+)", rhs)
    if m:
        c = ev(m.group(1))
        return None if c is None else ev(m.group(2) if c else m.group(3))
    m = re.fullmatch(r"(?:tail )?call i32 @llvm\.umin\.i32\(i32 (\S+), i32 (\S+)\)", rhs)
    if m:
        a, b = ev(m.group(1)), ev(m.group(2))
        return None if a is None or b is None else min(a & 0xFFFFFFFF, b & 0xFFFFFFFF)
    m = re.fullmatch(r"add (?:nuw )?(?:nsw )?i32 (\S+), (\S+)", rhs)
    if m:
        a, b = ev(m.group(1)), ev(m.group(2))
        return None if a is None or b is None else (a + b) & 0xFFFFFFFF
    return None


def counter_loops(fn_body: str):
    """The rolled trip loops: [(blocks of the loop, header, counter phi, block of the counter's br, N or None, top,
    block of the counter's test before trip 0 or None, blocks after the counter's test)]. A
    loop is the natural loop of the counter's back edge: its header (the block of the phi starting at 0) and every block
    reaching the latch without passing the header. top: the counter test is also made before trip 0, by the one block
    entering the header (a trip may not run: N, not at least 1)."""
    bl, order = blocks(fn_body)
    d = defs(fn_body)
    tk = table_k_param(fn_body)
    where = {}
    for lab in order:
        for l in bl[lab][0]:
            m = re.match(r"^\s*(%[-\w.$]+) = ", l)
            if m:
                where[m.group(1)] = lab
    preds = {x: [y for y in order if x in bl[y][1]] for x in order}
    out = []
    for lab in order:
        if not bl[lab][0]:
            continue
        m = re.match(r"^\s*br i1 (%[-\w.$]+), label %([-\w.$]+), label %([-\w.$]+)", bl[lab][0][-1])
        if not m:
            continue
        c = re.fullmatch(r"icmp ult i32 (%[-\w.$]+), (\S+)", d.get(m.group(1), ""))
        if not c:
            continue
        jv = c.group(1)
        j = re.fullmatch(r"add (?:nuw )?(?:nsw )?i32 (%[-\w.$]+), 1", d.get(jv, ""))
        if not (j and re.fullmatch(r"phi i32 .*\[ 0, %[-\w.$]+ \].*", d.get(j.group(1), ""))):
            continue
        jphi = j.group(1)
        head = where.get(jphi)
        after = set()
        back = lab
        if head != m.group(2):
            # two tests per trip: the counter phi's next value comes back from a block the counter's go-on edge reaches
            inc = re.findall(r"\[ (\S+), %([-\w.$]+) \]", d.get(jphi, ""))
            backs = [b for v, b in inc if v == jv]
            if len(backs) != 1 or head is None or backs[0] == lab or head not in bl.get(backs[0], ([], []))[1]:
                continue
            back = backs[0]
            if back != m.group(2) and back not in reach(bl, m.group(2)):
                continue
        latch = lab
        loop, todo = {head, latch, back}, [latch, back]
        while todo:
            x = todo.pop()
            if x == head:
                continue
            for p in preds[x]:
                if p not in loop:
                    loop.add(p)
                    todo.append(p)
        N = value(d, c.group(2), tableK=tk)
        # the counter test before trip 0: the one block entering the header from outside the loop branches on
        # `icmp ult i32 0, N` (the same N; with a trip-0 conjunct, `and i1` of it) to the header or the latch's exit;
        # with a constant N of 0 the builder folded it to `false`
        top, guard = False, None
        outside = [p for p in preds[head] if p not in loop]
        if len(outside) == 1 and bl[outside[0]][0]:
            g = re.match(r"^\s*br i1 (%[-\w.$]+|false), label %([-\w.$]+), label %([-\w.$]+)", bl[outside[0]][0][-1])
            if g and g.group(2) == head and g.group(3) == m.group(3):
                if g.group(1) == "false":
                    top = N == 0 and re.fullmatch(r"-?\d+", c.group(2)) is not None
                else:
                    gc = d.get(g.group(1), "")
                    a = re.fullmatch(r"and i1 (%[-\w.$]+), (\S+)", gc)
                    if a:
                        gc = d.get(a.group(1), "")
                    top = gc == "icmp ult i32 0, " + c.group(2)
                guard = outside[0] if top else None
        if N is not None and (N < 0 or N >= 1 << 31):
            N = None   # a table clone's K parameter read as none: its own K is not in the IR
        if back != lab:
            # the blocks after the counter's test: reached from its go-on edge without passing the header or the latch
            after, todo = {m.group(2)}, [m.group(2)]
            while todo:
                x = todo.pop()
                for y in bl.get(x, ([], []))[1]:
                    if y in loop and y not in after and y not in (head, lab):
                        after.add(y)
                        todo.append(y)
        out.append((loop, head, jphi, lab, N, top, guard, after))
    return out


def reverse_loops(fn_body: str):
    """Blocks of the rolled form's reverse loops: cycles through a block ending in a switch on a cqrt_pop result."""
    bl, order = blocks(fn_body)
    d = defs(fn_body)
    out = set()
    for lab in order:
        sw = [l for l in bl[lab][0] if re.match(r"^\s*switch ", l)]
        m = sw and re.match(r"^\s*switch i32 (%[-\w.$]+),", sw[-1])
        if m and "@cqrt_pop(" in d.get(m.group(1), "") and lab in reach(bl, lab):
            out |= {x for x in reach(bl, lab) if lab in reach(bl, x)} | {lab}
    return out


def runs(fn_body: str, site: str, invariant_once=False, skip_latches=False):
    """How many times the instructions matching the regex site run with no received K: once outside every rolled trip
    loop, N times per enclosing rolled trip loop (a C program's own loop counts once per iteration, i.e. once).
    invariant_once: a site in a trip loop whose first %operand is defined outside that loop runs on the same rail every
    trip (rule 2: a re-measurement of the same rail is a classical re-read), so that loop counts once for it.
    skip_latches: the trip loops' own counter branches (the guard before trip 0 included) are not counted. None where a site lies in a reverse loop or a
    trip loop's N is unknown."""
    bl, order = blocks(fn_body)
    loops = counter_loops(fn_body)
    rev = reverse_loops(fn_body)
    latches = {lt for _, _, _, lt, _, _, _, _ in loops} | {g for *_, g, _ in loops if g}
    defined_in = lambda v, loop: any(re.match(r"^\s*" + re.escape(v) + r" = ", l) for x in loop for l in bl[x][0])
    n = 0
    for lab in order:
        for i, l in enumerate(bl[lab][0]):
            if not re.search(site, l):
                continue
            if skip_latches and lab in latches and i == len(bl[lab][0]) - 1:
                continue
            if lab in rev:
                return None
            k = 1
            for loop, _, _, _, N, top, _, after in loops:
                if lab not in loop:
                    continue
                if invariant_once:
                    op = re.search(r"\((?:i\d+ )?(%[-\w.$]+)", l)
                    if op and not defined_in(op.group(1), loop):
                        continue
                if N is None:
                    return None
                k *= (N if top else max(N, 1)) - (1 if lab in after and (N if top else max(N, 1)) else 0)
            n += k
    return n


# Self-test (ctest loops-cutoff-ktrips): a rolled trip loop in the shape cq-lower emits (me_rail's f), with
# the received K read from @__cq_k, and the counterexamples each count must still reject.
_ROLLED = """define i32 @f(i32 %0) {
  %k = load i32, ptr @__cq_k, align 4
  %kn = icmp eq i32 %k, -1
  %K = select i1 %kn, i32 4, i32 %k
  %r = call i32 @cqrt_alloc_i1(i1 true)
  br label %h

h:                                                ; preds = %h, %1
  %j = phi i32 [ 0, %1 ], [ %j1, %h ]
  %v = phi i32 [ %r, %1 ], [ %w, %h ]
  call void @cqrt_push(i32 %v)
  %m = call i1 @cqrt_measure_i1(i32 %r), !cq.measure !6
  MUTANT
  %w = call i32 @cq_template_mul_i32_hl(i32 %v, i32 3)
  %j1 = add i32 %j, 1
  %c = icmp ult i32 %j1, %K
  br i1 %c, label %h, label %x

x:                                                ; preds = %h
  %o = call i32 @cqrt_measure_i32(i32 %w), !cq.measure !6
  br label %rv

rv:                                               ; preds = %x, %rv
  %p = call i32 @cqrt_pop()
  call void @cq_template_mul_i32_hl_unc(i32 %p, i32 3)
  switch i32 %p, label %rv [
    i32 1, label %e
  ]

e:                                                ; preds = %rv
  ret i32 %o
}
"""


def _selftest() -> int:
    M = r"call [^@]*@cqrt_measure_"
    cases = [
        # (mutant line, regex, options, expected): the original, then each count's counterexample
        ("", M, dict(invariant_once=True), 2),                      # rule 2: the loop-invariant rail re-read; one after
        ("%q = call i32 @cqrt_measure_i32(i32 %v), !cq.measure !6", M, dict(invariant_once=True), 6),  # a carried rail per trip
        ("", r"@cq_template_mul_i32_hl\(", {}, 4),                  # K = 4 trips with no received K
        ("", r"^  br i1 ", dict(skip_latches=True), 0),             # the trip counter's br is not a classical branch
        ("br label %h0\nh0:\n  br i1 %kn, label %h1, label %h1\nh1:", r"^  br i1 ", dict(skip_latches=True), 4),  # one per trip
        ("", r"@cq_template_mul_i32_hl_unc\(", {}, None),           # a site of the reverse loop: no count
    ]
    bad = 0
    for mut, site, opt, want in cases:
        got = runs(_ROLLED.replace("MUTANT", mut), site, **opt)
        if got != want:
            print(f"FAIL ktrips {site!r} {opt} mutant {mut[:40]!r}: {got}, not {want}")
            bad += 1
    plain = _ROLLED.replace("[ 0, %1 ]", "[ 1, %1 ]")           # no counter starting at 0: a C program's loop, once
    if runs(plain.replace("MUTANT", ""), r"@cq_template_mul_i32_hl\(") != 1:
        print("FAIL ktrips: a cycle with no trip counter counted per trip")
        bad += 1
    tbl = _ROLLED.replace("@f(i32 %0)", "@__cq_q_f_1_t(i32 %0, i32 %kp)").replace("load i32, ptr @__cq_k, align 4", "add i32 %kp, 0")
    if runs(tbl.replace("MUTANT", ""), r"@cq_template_mul_i32_hl\(") != 4:
        print("FAIL ktrips: a table clone's K parameter not read as none")
        bad += 1
    # the counter test before trip 0 (cq-9kcq S6c): N trips, none for N = 0; a run-time N read with no received K; a
    # trip-0 conjunct `and i1` on the guard; a guard on another N, or to another block than the latch's exit, is none
    top = _ROLLED.replace("  br label %h\n\nh:", "  %g = icmp ult i32 0, %K\n  br i1 %g, label %h, label %x\n\nh:")
    for mut, site, opt, want in [("", r"@cq_template_mul_i32_hl\(", {}, 4), ("", r"^  br i1 ", dict(skip_latches=True), 0)]:
        got = runs(top.replace("MUTANT", mut), site, **opt)
        if got != want:
            print(f"FAIL ktrips guarded {site!r}: {got}, not {want}")
            bad += 1
    zero = top.replace("select i1 %kn, i32 4, i32 %k", "select i1 %kn, i32 0, i32 %k")
    if runs(zero.replace("MUTANT", ""), r"@cq_template_mul_i32_hl\(") != 0:
        print("FAIL ktrips: a guarded trip loop with N = 0 counted as running")
        bad += 1
    if runs(_ROLLED.replace("select i1 %kn, i32 4, i32 %k", "select i1 %kn, i32 0, i32 %k").replace("MUTANT", ""),
            r"@cq_template_mul_i32_hl\(") != 1:
        print("FAIL ktrips: an unguarded trip loop (bottom test) with N = 0 not counted once")
        bad += 1
    lit = _ROLLED.replace("  br label %h\n\nh:", "  br i1 false, label %h, label %x\n\nh:")
    if runs(lit.replace("%c = icmp ult i32 %j1, %K", "%c = icmp ult i32 %j1, 0").replace("MUTANT", ""),
            r"@cq_template_mul_i32_hl\(") != 0:
        print("FAIL ktrips: a constant N = 0 behind a folded guard counted as running")
        bad += 1
    if runs(lit.replace("MUTANT", ""), r"@cq_template_mul_i32_hl\(") != 4:
        print("FAIL ktrips: a folded `false` branch before a loop with a run-time N read as its guard")
        bad += 1
    if runs(zero.replace("MUTANT", "").replace("%g = icmp ult i32 0, %K", "%g0 = icmp ult i32 0, %K\n  %g = and i1 %g0, %kn"),
            r"@cq_template_mul_i32_hl\(") != 0:
        print("FAIL ktrips: a guard with a trip-0 conjunct not read")
        bad += 1
    for other in (zero.replace("%g = icmp ult i32 0, %K", "%g = icmp ult i32 0, 7"),
                  zero.replace("br i1 %g, label %h, label %x", "br i1 %g, label %h, label %rv")):
        if runs(other.replace("MUTANT", ""), r"@cq_template_mul_i32_hl\(") != 1:
            print("FAIL ktrips: a branch before the loop that is not its zero-trip guard read as one")
            bad += 1
    # two tests per trip (cq-9kcq S7): the header test region after the counter's test runs N - 1 times, the trip N times;
    # a back edge that the counter's go-on edge does not reach is no trip loop (a C program's loop: once)
    two = _ROLLED.replace("[ %j1, %h ]", "[ %j1, %r ]").replace("[ %w, %h ]", "[ %w2, %r ]").replace(
        "br i1 %c, label %h, label %x", "br i1 %c, label %r, label %x\n\nr:\n  %w2 = call i32 @cq_template_add_i32_hl(i32 %w, i32 1)\n  br label %h")
    for site, want in ((r"@cq_template_mul_i32_hl\(", 4), (r"@cq_template_add_i32_hl\(", 3)):
        if runs(two.replace("MUTANT", ""), site) != want:
            print(f"FAIL ktrips: two tests per trip {site!r}: {runs(two.replace('MUTANT', ''), site)}, not {want}")
            bad += 1
    stray = two.replace("br i1 %c, label %r, label %x", "br i1 %c, label %x, label %x\n\nz:\n  br label %r")
    if runs(stray.replace("MUTANT", ""), r"@cq_template_add_i32_hl\(") != 1:
        print("FAIL ktrips: a back edge the counter's test does not lead to read as a trip loop")
        bad += 1
    print("ok   ktrips" if not bad else f"FAIL ktrips: {bad}")
    return 1 if bad else 0


if __name__ == "__main__":
    import sys
    sys.exit(_selftest())
