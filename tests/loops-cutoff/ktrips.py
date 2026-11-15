"""Reading a lowered function's control flow for the tests of tests/loops-cutoff (cq-9kcq): how often a call site runs,
the same in both forms of a K-loop. The copied form writes trip j's code as its own copy (a site per trip, outside any
cycle); the rolled form runs one trip K times in a generated classical loop

    H: %j = phi i32 [ 0, %pre ], [ %j1, %L ] ...      L: %j1 = add i32 %j, 1
                                                         %c = icmp ult i32 %j1, N
                                                         br i1 %c, label %H, label %exit

and undoes the trips in a reverse loop (exited by a switch on a popped value). Where the bound is a run-time value or 0
(cq-9kcq S6: a received K, K = 0) the counter test sits at the top, and a trip runs N times, none for N = 0:

    H: %j = phi i32 [ 0, %pre ], [ %j1, %L ] ...      L: %j1 = add i32 %j, 1
       %c = icmp ult i32 %j, N                           br label %H
       br i1 %c, label %trip, label %exit             (%c may be `and i1` with a classical trip-0 conjunct)
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


def value(d, v: str, depth=0, tableK=None):
    """The integer v holds with no received K (@__cq_k = -1, a table clone's K parameter -1), or None."""
    if re.fullmatch(r"-?\d+", v):
        return int(v)
    if tableK is not None and v == tableK:
        return -1
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
    """The rolled trip loops: [(blocks of the loop, header, counter phi, block of the counter's br, N or None, top)]. A
    loop is the natural loop of the counter's back edge: its header (the block of the phi starting at 0) and every block
    reaching the latch without passing the header. top: the counter test at the top (a trip may not run: N, not at
    least 1)."""
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
        cond = d.get(m.group(1), "")
        a = re.fullmatch(r"and i1 (%[-\w.$]+), (\S+)", cond)   # the top test's trip-0 conjunct
        if a:
            cond = d.get(a.group(1), "")
        c = re.fullmatch(r"icmp ult i32 (%[-\w.$]+), (\S+)", cond)
        if not c:
            continue
        jv, top = c.group(1), False
        j = re.fullmatch(r"add (?:nuw )?(?:nsw )?i32 (%[-\w.$]+), 1", d.get(jv, ""))
        if j and re.fullmatch(r"phi i32 .*\[ 0, %[-\w.$]+ \].*", d.get(j.group(1), "")):
            jphi = j.group(1)
            head = where.get(jphi)
            if head != m.group(2):
                continue
            latch = lab
        else:
            # the top test: %j itself, a phi in this block starting at 0, its back edge `add %j, 1` from the latch
            ph = re.fullmatch(r"phi i32 (.*)", d.get(jv, ""))
            if not ph or where.get(jv) != lab or not re.search(r"\[ 0, %[-\w.$]+ \]", ph.group(1)):
                continue
            back = [(v, b) for v, b in re.findall(r"\[ (%[-\w.$]+), %([-\w.$]+) \]", ph.group(1))
                    if re.fullmatch(r"add (?:nuw )?(?:nsw )?i32 " + re.escape(jv) + r", 1", d.get(v, ""))]
            if len(back) != 1:
                continue
            jphi, head, latch, top = jv, lab, back[0][1], True
            if latch not in bl or m.group(2) == m.group(3):
                continue
        loop, todo = {head, latch}, [latch]
        while todo:
            x = todo.pop()
            if x == head:
                continue
            for p in preds[x]:
                if p not in loop:
                    loop.add(p)
                    todo.append(p)
        N = value(d, c.group(2), tableK=tk)
        if N is not None and (N < 0 or N >= 1 << 31):
            N = None   # a table clone's K parameter read as none: its own K is not in the IR
        out.append((loop, head, jphi, lab, N, top))
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
    skip_latches: the trip loops' own counter branches are not counted. None where a site lies in a reverse loop or a
    trip loop's N is unknown."""
    bl, order = blocks(fn_body)
    loops = counter_loops(fn_body)
    rev = reverse_loops(fn_body)
    latches = {lt for _, _, _, lt, _, _ in loops}
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
            for loop, _, _, _, N, top in loops:
                if lab not in loop:
                    continue
                if invariant_once:
                    op = re.search(r"\((?:i\d+ )?(%[-\w.$]+)", l)
                    if op and not defined_in(op.group(1), loop):
                        continue
                if N is None:
                    return None
                k *= N if top else max(N, 1)
            n += k
    return n


# Self-test (ctest loops-cutoff-ktrips): a rolled trip loop in the shape cq-lower emits (CQ_K_ROLLED, me_rail's f), with
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
    copied = _ROLLED.replace("[ 0, %1 ]", "[ 1, %1 ]")          # no counter starting at 0: a C program's loop, once
    if runs(copied.replace("MUTANT", ""), r"@cq_template_mul_i32_hl\(") != 1:
        print("FAIL ktrips: a cycle with no trip counter counted per trip")
        bad += 1
    tbl = _ROLLED.replace("@f(i32 %0)", "@__cq_q_f_1_t(i32 %0, i32 %kp)").replace("load i32, ptr @__cq_k, align 4", "add i32 %kp, 0")
    if runs(tbl.replace("MUTANT", ""), r"@cq_template_mul_i32_hl\(") != 4:
        print("FAIL ktrips: a table clone's K parameter not read as none")
        bad += 1
    # the top test (cq-9kcq S6): N trips, none for N = 0; its own br is the counter's; a run-time N read with no
    # received K; a trip-0 conjunct `and i1` on the test
    top = (_ROLLED.replace("  br label %h\n\nh:", "  br label %h\n\nh:")
           .replace("  %j1 = add i32 %j, 1\n  %c = icmp ult i32 %j1, %K\n  br i1 %c, label %h, label %x",
                    "  %j1 = add i32 %j, 1\n  br label %h")
           .replace("  call void @cqrt_push(i32 %v)\n", "  %c = icmp ult i32 %j, %K\n  br i1 %c, label %b, label %x\nb:\n"
                    "  call void @cqrt_push(i32 %v)\n")
           .replace("[ %j1, %h ]", "[ %j1, %b ]").replace("[ %w, %h ]", "[ %w, %b ]").replace("preds = %h", "preds = %h"))
    for mut, site, opt, want in [("", r"@cq_template_mul_i32_hl\(", {}, 4), ("", r"^  br i1 ", dict(skip_latches=True), 0)]:
        got = runs(top.replace("MUTANT", mut), site, **opt)
        if got != want:
            print(f"FAIL ktrips top test {site!r}: {got}, not {want}")
            bad += 1
    if runs(top.replace("MUTANT", "").replace("select i1 %kn, i32 4, i32 %k", "select i1 %kn, i32 0, i32 %k"),
            r"@cq_template_mul_i32_hl\(") != 0:
        print("FAIL ktrips: a top-tested trip loop with N = 0 counted as running")
        bad += 1
    if runs(top.replace("MUTANT", "").replace("%c = icmp ult i32 %j, %K", "%c0 = icmp ult i32 %j, %K\n  %c = and i1 %c0, %kn"),
            r"@cq_template_mul_i32_hl\(") != 4:
        print("FAIL ktrips: a top test with a trip-0 conjunct not read")
        bad += 1
    print("ok   ktrips" if not bad else f"FAIL ktrips: {bad}")
    return 1 if bad else 0


if __name__ == "__main__":
    import sys
    sys.exit(_selftest())
