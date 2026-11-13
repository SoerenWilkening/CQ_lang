"""Sample-set gaps (cq-h4pn): every input class CLAUDE.md requires, or why it has nothing, in the verdict.

CLAUDE.md "Inputs" requires, per example: edge values and fp specials for every quantum input, a
seeded random set, every input when the quantum inputs total at most 8 bits, trip counts 0, K-1, K
and K+1 for every loop, and a seeded set over the classical arguments. sampling.py lists each class
(SampleSet.classes) with its samples or the reason it has none. This module sorts each reason into

  not applicable  the class asks for nothing here (no fp quantum input, no classical argument, more
                  than 8 quantum bits, no loop): no line;
  IMPOSSIBLE      no input of the program's domain exists (every candidate leaves its object, a trip
                  count the loop cannot run, proved below): reported, never failing;
  MISSING         the sampler did not find an input (a search that gave up, a reason this module does
                  not know): the §6 checks that used the sample set are not green (report.evaluate);
  UNCOVERED       a trip target no input reaches within the checker's cost budget while the budget
                  stopped some constructed input (owner rulings 2026-11-01, cq-g8md, cq-hsan; CR §6,
                  coverage): reported with the stopped inputs and their cost "> budget" (nothing runs
                  past it), never compared, never counted green, never dead, never removed; not
                  failing (the gate: no comparison failed and every uncovered target listed); its line
                  says "not found" (the search found no input within the budget) or "unreachable within
                  the budget: needs N header executions" (zero_trip_cost proved N > budget, cq-824x);
  NOTE            the totalization rows (CR §2 rows an instruction can reach) the search did not hit:
                  reported, never failing. They are sampling.py's own coverage aid, not a class
                  CLAUDE.md "Inputs" lists (orchestrator decision under CLAUDE.md Inputs, cq-h4pn,
                  owner may override).

A trip count the sampler reports as "no input found" is IMPOSSIBLE only with a proof, never on the
search's evidence alone:

  * LLVM's ScalarEvolution on the .O1.ll (`opt -passes=print<scalar-evolution>`; whatever LLVM
    does, we do): an exact constant backedge-taken count C means every activation runs C + 1 header
    executions, so the C oracle (T1.2: trips begun) reports C or C + 1, and C + 1 alone when no header
    run only exits (the header-region test below); a constant maximum M bounds it by M + 1.
  * 0: the C oracle reports 0 only on a guard branch that skips the loop or a header run that exits
    before a trip begins (OracleInstr.cpp, trip counters). A loop, nested or not, with no such guard
    (the oracle's own walk back from the header) and no header-region exit (over-approximated: the
    header is a latch, or neither the header nor a single-predecessor non-latch successor of it is
    exiting) is never reported as 0 (cq-oou2).
  * sampling.construct_trip_targets (cq-oou2): constructed inputs that reach the count only outside
    the domain; it writes that proof as the target's reason, with the witness ("outside the domain:
    ..."). A count reached only with the K cutoff off is no proof: MISSING.

  * TripFacts.cpp (the oracle plugin's cq-trip-facts pass, cq-97oj): a value-set proof (LLVM
    ScalarEvolution's exact trip count with ValueTracking's range, power-of-two and known-bits facts
    excludes the count), a domain proof (the count needs an argument range on every point of which
    an access every path to the loop executes leaves its object, getObjectSize), or a
    finite-structure proof (cq-97oj kind 3, cq-fhoc: the loop follows a pointer loaded from the
    loop-carried pointer, writes no memory and leaves on null; the last stores before the loop, by
    MemorySSA, chain the entry pointer through n distinct pointers to null, so no activation runs
    more than n header executions; or a load at an affine address leaves the loop on a constant
    and the last store before the loop to its address at iteration j stores it: at most j + 1, rulings 2
    B, cq-b0rl). The proofs also run on the .O1.ll linked with the drivers.txt line's function bodies,
    part of the program (trip_facts).

Every count not covered above stays MISSING when the search found none.
"""
from __future__ import annotations

import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

from cqcheck import drivers as D
from cqcheck.contracts import DriverSpec, SampleSet

MISSING, IMPOSSIBLE, NOTE, UNCOVERED = "missing", "impossible", "note", "uncovered"
REQUIRED_EXHAUSTIVE_BITS = 8      # CLAUDE.md Inputs: every input when the quantum inputs total <= 8 bits


@dataclass(frozen=True)
class Gap:
    kind: str       # MISSING, IMPOSSIBLE or NOTE
    where: str      # "edge: call 0", "trips: f:%7 trip 0", "totalization"
    why: str

    def line(self) -> str:
        return f"sampling: {self.kind}: {self.where}: {self.why}"


# Reasons sampling.py writes. A reason that matches none of them is MISSING (never assumed fine).
_MISSING_MARKS = ("ran to completion", "no input found", "unreachable by search", "never reached")
_IMPOSSIBLE_MARKS = ("outside its domain", "outside the domain", "cannot be hit:")
_NA_MARKS = ("no scalar argument of this call flows into a cq_theta_* register",
             "no floating-point quantum input in this call",
             "no floating-point register among the substituted cq_theta sites",
             "no classical scalar argument in this call",
             "the example has no loop",
             "no instruction of the example is named by a CR §2 row")
_BITS = re.compile(r"total (\d+) bits > (\d+)")


def classify_reason(why: str) -> Optional[str]:
    """MISSING, IMPOSSIBLE, or None (the class does not apply) for one empty-class reason."""
    if not why or any(m in why for m in _MISSING_MARKS):
        return MISSING
    if any(m in why for m in _IMPOSSIBLE_MARKS):
        return IMPOSSIBLE
    bits = _BITS.findall(why)
    if any(int(a) <= REQUIRED_EXHAUSTIVE_BITS for a, _ in bits):
        return MISSING            # an exhaustive set CLAUDE.md requires, left out
    if bits or any(m in why for m in _NA_MARKS):
        return None
    return MISSING


# --------------------------------------------------------------------------------------------
# Loop facts: what trip counts a loop can run at all


@dataclass
class LoopFacts:
    exact: Optional[int] = None       # ScalarEvolution's exact constant backedge-taken count
    max: Optional[int] = None         # its constant maximum
    zero_proof: Optional[str] = None  # why the C oracle never reports 0 trips, or None
    region_exit: bool = True          # a header run may only exit (over-approximated; cq-oou2)
    static: Optional[Dict[int, str]] = None   # target -> proof of TripFacts.cpp (cq-97oj kinds 1, 2)

    def impossible(self, loop: str, t: int) -> Optional[str]:
        """Why no input gives `t` trips of `loop`, or None when that is not proved."""
        if t == 0:
            return self.zero_proof
        if self.exact is not None and t not in (self.exact, self.exact + 1):
            return (f"LLVM ScalarEvolution: the backedge-taken count of {loop} is always {self.exact}, "
                    f"so every activation runs {self.exact} or {self.exact + 1} trips")
        if self.exact is not None and t == self.exact and not self.region_exit:
            return (f"LLVM ScalarEvolution: the backedge-taken count of {loop} is always {self.exact}, and no "
                    f"header run only exits (the header is a latch, or its test region holds no exit), so "
                    f"every header execution begins a trip: every activation runs {self.exact + 1} trips")
        if self.max is not None and t > self.max + 1:
            return (f"LLVM ScalarEvolution: the backedge-taken count of {loop} is at most {self.max}, "
                    f"so no activation runs more than {self.max + 1} trips")
        if self.static and t in self.static:
            return self.static[t]
        return None


_SCEV_FN = re.compile(r"^Determining loop execution counts for: @(\S+)")
_SCEV_EXACT = re.compile(r"^Loop (%\S+): backedge-taken count is i(\d+) (-?\d+)\s*$")
_SCEV_MAX = re.compile(r"^Loop (%\S+): constant max backedge-taken count is i(\d+) (-?\d+)\s*$")


def scev_counts(o1: Path, llvm_bin: Path) -> Dict[str, Dict[str, Optional[int]]]:
    """{"<fn>:<header>": {"exact": C | None, "max": M | None}} from LLVM's ScalarEvolution printer."""
    r = subprocess.run([str(llvm_bin / "opt"), "-passes=print<scalar-evolution>", "-disable-output", str(o1)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"opt print<scalar-evolution> on {o1} exited {r.returncode}: {r.stderr.strip()[:500]}")
    out: Dict[str, Dict[str, Optional[int]]] = {}
    fn = None
    for line in r.stderr.splitlines() + r.stdout.splitlines():
        m = _SCEV_FN.match(line)
        if m:
            fn = m.group(1)
            continue
        for pat, field in ((_SCEV_EXACT, "exact"), (_SCEV_MAX, "max")):
            m = pat.match(line)
            if m and fn:
                w, v = int(m.group(2)), int(m.group(3))
                out.setdefault(f"{fn}:{m.group(1)}", {"exact": None, "max": None})[field] = v % (1 << w)
    return out


_SCEV_SYM = re.compile(r"^Loop (%\S+): backedge-taken count is (\(.*\)|%[-\w.$]+)(?:<[a-z]+>)*\s*$")
_SCEV_SYM_MAX = re.compile(r"^Loop (%\S+): symbolic max backedge-taken count is (\(.*\)|%[-\w.$]+)(?:<[a-z]+>)*\s*$")


def scev_symbolic_counts(o1: Path, llvm_bin: Path, symbolic_max: bool = False) -> Dict[str, str]:
    """{"<fn>:<header>": expression} for each loop whose exact backedge-taken count LLVM's
    ScalarEvolution prints as an expression (not a constant, not "Unpredictable"); with
    `symbolic_max`, its symbolic maximum backedge-taken count instead (an upper bound of every
    activation's count, also for a loop with several exits; cq-824x)."""
    r = subprocess.run([str(llvm_bin / "opt"), "-passes=print<scalar-evolution>", "-disable-output", str(o1)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"opt print<scalar-evolution> on {o1} exited {r.returncode}: {r.stderr.strip()[:500]}")
    out: Dict[str, str] = {}
    fn = None
    for line in r.stderr.splitlines() + r.stdout.splitlines():
        m = _SCEV_FN.match(line)
        if m:
            fn = m.group(1)
            continue
        m = (_SCEV_SYM_MAX if symbolic_max else _SCEV_SYM).match(line)
        if m and fn:
            out[f"{fn}:{m.group(1)}"] = m.group(2)
    return out


_SCEV_TOK = re.compile(r"\s*(\(|\)|<[a-z]+>|/u|-?\d+|[+*]|i\d+|%[-\w.$]+|[a-z_]+)")
_SCEV_NARY = {"+", "*", "smax", "umax", "smin", "umin", "/u"}


def scev_eval(expr: str, params: Dict[str, Tuple[int, int]]) -> Optional[int]:
    """The value (unsigned, at its width) of a ScalarEvolution expression as print<scalar-evolution>
    writes it, its only unknowns the parameters `params` ({"%N": (width, bit pattern)}), or None for
    any form not listed here (an AddRec, an instruction operand, a cast or operator not below):
    constants, parameters, (a + b ...), (a * b ...), (a /u b), (a smax|umax|smin|umin b ...),
    (zext|sext|trunc iN x to iM), each with optional <nsw>/<nuw>/<nw> flags."""
    toks: List[str] = []
    pos = 0
    s = expr.strip()
    while pos < len(s):
        m = _SCEV_TOK.match(s, pos)
        if not m:
            return None
        toks.append(m.group(1))
        pos = m.end()
    toks = [t for t in toks if not (t.startswith("<") and t.endswith(">"))]
    i = 0

    def sgn(v: int, w: int) -> int:
        return v - (1 << w) if v >> (w - 1) & 1 else v

    def atom():   # -> (value, width or None) ; width None: a constant not yet typed
        nonlocal i
        if i >= len(toks):
            raise ValueError
        t = toks[i]
        i += 1
        if re.fullmatch(r"-?\d+", t):
            return int(t), None
        if t.startswith("%"):
            if t not in params:
                raise ValueError
            w, v = params[t]
            return v & ((1 << w) - 1), w
        if t != "(":
            raise ValueError
        if toks[i] in ("zext", "sext", "trunc"):
            op = toks[i]
            i += 1
            wa = toks[i]
            i += 1
            if not re.fullmatch(r"i\d+", wa):
                raise ValueError
            v, w = atom()
            wa_n = int(wa[1:])
            if w is not None and w != wa_n:
                raise ValueError
            v &= (1 << wa_n) - 1
            if toks[i] != "to" or not re.fullmatch(r"i\d+", toks[i + 1]) or toks[i + 2] != ")":
                raise ValueError
            wb = int(toks[i + 1][1:])
            i += 3
            if op == "sext":
                v = sgn(v, wa_n)
            return v & ((1 << wb) - 1), wb
        vals = [atom()]
        op = None
        while toks[i] != ")":
            o = toks[i]
            if o not in _SCEV_NARY or (op is not None and o != op):
                raise ValueError
            op = o
            i += 1
            vals.append(atom())
        i += 1
        if op is None:
            return vals[0]
        ws = {w for _, w in vals if w is not None}
        if len(ws) != 1:
            raise ValueError
        w = ws.pop()
        m = (1 << w) - 1
        us = [v & m for v, _ in vals]
        if op == "+":
            r = sum(us)
        elif op == "*":
            r = 1
            for v in us:
                r *= v
        elif op == "/u":
            if len(us) != 2 or us[1] == 0:
                raise ValueError
            r = us[0] // us[1]
        elif op in ("umax", "umin"):
            r = (max if op == "umax" else min)(us)
        else:
            ss = [sgn(v, w) for v in us]
            r = (max if op == "smax" else min)(ss)
        return r & m, w

    try:
        v, w = atom()
    except (ValueError, IndexError):
        return None
    if i != len(toks) or w is None:
        return None
    return v


def _zero_proof(f: "D.Function", header: str, blocks: set, top_level: bool) -> Optional[str]:
    """Why the C oracle never reports 0 trips of this loop, or None. OracleInstr.cpp (trip counters)
    reports 0 only (a) on a guard skip: walking back from an out-of-loop predecessor of the header
    through unconditional branches and single predecessors, a conditional branch whose other
    successor is an exit block of the loop, or (b) on a header run that exits from the header's test
    region before a trip begins (the header is not a latch). Neither present: no activation of the
    loop, nested or not, is reported as 0 (cq-oou2). The region test over-approximates the oracle's
    (a single-predecessor non-latch exiting successor counts whatever it computes)."""
    preds = f.preds()
    succ = {b: f.blocks[b][-1].successors() for b in f.order}
    if _region_may_exit(f, header, blocks):
        return None
    exit_blocks = {s for b in blocks for s in succ[b] if s not in blocks}
    for p0 in preds.get(header, []):
        if p0 in blocks:
            continue
        to, p, seen = header, p0, set()
        while p is not None and p not in blocks and p not in seen:
            seen.add(p)
            term = f.blocks[p][-1]
            if term.op != "br":
                break
            ss = term.successors()
            if len(ss) > 1:
                if any(o != to and o in exit_blocks for o in ss):
                    return None
                break
            to = p
            ps = preds.get(p, [])
            p = ps[0] if len(set(ps)) == 1 else None
    where = "" if top_level else " (a nested loop: per activation)"
    return (f"the loop at {header} of @{f.name[1:]}{where} has no guard branch that skips it and no "
            f"header run that exits before a trip begins: the C oracle's trip counter never reports 0")


def guard_skips(f: "D.Function", header: str, blocks: set) -> List[Tuple[str, str]]:
    """The guard skips OracleInstr.cpp (trip counters) reports as 0 trips: (guard block, the exit block
    its branch goes to instead of the loop). Walking back from an out-of-loop predecessor of the
    header through blocks that branch unconditionally and have a single predecessor (a preheader),
    the first conditional branch whose other successor is an exit block of the loop."""
    preds = f.preds()
    succ = {b: f.blocks[b][-1].successors() for b in f.order}
    exit_blocks = {s for b in blocks for s in succ[b] if s not in blocks}
    out: List[Tuple[str, str]] = []
    for p0 in preds.get(header, []):
        if p0 in blocks:
            continue
        to, p, seen = header, p0, set()
        while p is not None and p not in blocks and p not in seen:
            seen.add(p)
            term = f.blocks[p][-1]
            if term.op != "br":
                break
            ss = term.successors()
            if len(ss) > 1:
                other = [o for o in ss if o != to]
                if other and other[0] in exit_blocks:
                    out.append((p, other[0]))
                break
            to = p
            ps = preds.get(p, [])
            p = ps[0] if len(set(ps)) == 1 else None
    return out


def zero_meaning(f: "D.Function", header: str, blocks: set) -> str:
    """What trip 0 of this loop is (owner ruling 2026-11-01, cq-g8md): the C oracle reports 0 trips of
    an activation when a guard branch skips the loop (-O1 rotates a for loop into a guarded do-while:
    trip 0 is then the guard skipping it, never a header run), or when a header run leaves through the
    header's test region before a trip begins."""
    parts = [f"the guard branch in {g} goes to {x}, skipping the loop" for g, x in guard_skips(f, header, blocks)]
    if _region_may_exit(f, header, blocks):
        parts.append(f"a run of the header {header} leaves the loop before a trip begins")
    if not parts:
        return "never reported: no guard branch skips the loop and no header run leaves before a trip begins"
    return "trip 0 means " + ", or ".join(parts)


def _region_may_exit(f: "D.Function", header: str, blocks: set) -> bool:
    """Whether a header run may only exit, leaving through the header's test region before a trip
    begins (OracleInstr.cpp, trip counters: never when the header is a latch, nor with a live exit outside the
    region: two exit tests per trip, ruling Q15). Over-approximated: the header is exiting, or a single-predecessor
    non-latch successor of it is. Only a live exit counts (a path out of it reaches a return or the loop; cq-2dxe)."""
    preds = f.preds()
    succ = {b: f.blocks[b][-1].successors() for b in f.order}
    latches = {p for p in preds.get(header, []) if p in blocks}
    if header in latches:
        return False

    def live(x: str) -> bool:
        seen, work = {x}, [x]
        while work:
            b = work.pop()
            if b in blocks or f.blocks[b][-1].op == "ret":
                return True
            for n in succ[b]:
                if n not in seen:
                    seen.add(n)
                    work.append(n)
        return False
    exiting = {b for b in blocks if any(s not in blocks and live(s) for s in succ[b])}
    region = {header} | {s for s in succ[header] if s in blocks and s != header and set(preds.get(s, [])) == {header}
                         and s not in latches and s in exiting}
    if exiting - region:
        return False
    return bool(exiting)


# --------------------------------------------------------------------------------------------
# The cost of trip 0 behind a guard on an outer induction variable (cq-824x, cq-e4sw)
#
# Owner rulings 2026-11-01 (cq-g8md): nothing runs past the cost budget; a trip target no input
# reaches within it is uncovered. Two different facts hide behind "uncovered": the search did not
# find a cheap input, or no input of any kind reaches the target cheaply. The second is proved here
# for one shape, 117's: the C oracle reports 0 trips of a loop L only on guard skips (no header run
# exits before a trip begins), and every guard is a test P == C (or P != C) in L's parent loop O,
# where P is an induction variable of O (a header phi from the constant s outside O, P + d on every
# latch, d = +1 or -1), the guard's block lies in O but in no loop nested in it, and every path from
# O's header to a latch of O passes it. An activation of O runs P = s, s + d, ... (mod 2^w); its
# guard skips L for the first time on the trip with P == C, after n = (C - s) * d (mod 2^w) trips,
# each of which reached the guard with P != C and so entered L (guard_skips' walk: unconditional
# branches only from the guard to L's header). In the trip with P = v, L runs h(v) header executions,
# h(v) - 1 the exact constant backedge-taken count LLVM's ScalarEvolution computes on a copy of the
# function with P replaced by v and instsimplify run (an h(v) LLVM leaves open counts 1, the least
# an entered loop runs). Every input that runs 0 trips of L therefore executes at least
#     N = (n + 1) + sum of h(v) over those n trips
# loop headers before the C oracle records it (the n + 1 header executions of O included; at most
# ZERO_COST_EVALS of the h(v) are computed, each other trip counts 1). N is a lower bound, never an
# estimate: with N > budget the target is unreachable within the budget for every input of the
# domain, which the uncovered line says with N (sampling.uncovered_targets). Whether such a target
# counts as covered is the owner's question; it stays uncovered.

ZERO_COST_EVALS = 64


@dataclass(frozen=True)
class ZeroRoute:
    guard: str      # the guard block in O
    iv: str         # P, a phi in O's header
    width: int
    start: int      # s, bit pattern at width
    step: int       # d: +1 or -1
    skip_at: int    # C, bit pattern at width
    trips: int      # n: the trips of O before the one whose guard skips L


_INT = re.compile(r"-?\d+")


def _int_const(tok: str, w: int) -> Optional[int]:
    if w == 1 and tok in ("true", "false"):
        return int(tok == "true")
    return int(tok) & ((1 << w) - 1) if _INT.fullmatch(tok) else None


def zero_routes(f: "D.Function", header: str, blocks: set, outer_header: str, outer_blocks: set,
                loop_blocks: Sequence[set]) -> Optional[List[ZeroRoute]]:
    """The guard skips by which the C oracle reports 0 trips of the loop at `header`, each as a
    ZeroRoute on an induction variable of its parent loop (at `outer_header`), or None when trip 0
    may arise otherwise (a header run that exits, no guard skip) or a guard is not of that shape.
    `loop_blocks`: the block sets of every loop of `f` (to find the guard's innermost loop)."""
    if _region_may_exit(f, header, blocks):
        return None
    skips = guard_skips(f, header, blocks)
    if not skips:
        return None
    preds = f.preds()
    latches = [p for p in preds.get(outer_header, []) if p in outer_blocks]
    out: List[ZeroRoute] = []
    for g, skip in skips:
        if g not in outer_blocks or any(g in s and s < outer_blocks for s in loop_blocks):
            return None
        m = re.fullmatch(r"br i1 (%\S+), label (%\S+), label (%\S+)", f.blocks[g][-1].text.strip())
        c = f.defs.get(m.group(1)) if m else None
        mc = re.fullmatch(r"(%\S+) = icmp (eq|ne) (i\d+) (\S+), (\S+)", c.text.strip()) if c else None
        if not mc:
            return None
        w = int(mc.group(3)[1:])
        a, b = mc.group(4), mc.group(5)
        iv, cst = (a, _int_const(b, w)) if _int_const(a, w) is None else (b, _int_const(a, w))
        if cst is None:
            return None
        # the skip is taken exactly where P == C
        if not ((mc.group(2) == "eq" and skip == m.group(2) and skip != m.group(3))
                or (mc.group(2) == "ne" and skip == m.group(3) and skip != m.group(2))):
            return None
        phi = f.defs.get(iv)
        mp = re.fullmatch(re.escape(iv) + r" = phi (i\d+) (.*)", phi.text.strip()) if phi else None
        if not mp or phi.block != outer_header or int(mp.group(1)[1:]) != w:
            return None
        start, steps = set(), set()
        for val, frm in re.findall(r"\[\s*([^,\]]+?)\s*,\s*(%[^\s\]]+)\s*\]", mp.group(2)):
            if frm not in outer_blocks:
                start.add(_int_const(val, w))
                continue
            st = f.defs.get(val)
            ma = re.fullmatch(re.escape(val) + r" = add (?:(?:nuw|nsw) )*i\d+ (\S+), (\S+)", st.text.strip()) if st else None
            if not ma or iv not in (ma.group(1), ma.group(2)):
                return None
            other = ma.group(2) if ma.group(1) == iv else ma.group(1)
            steps.add(_int_const(other, w))
        if len(start) != 1 or None in start or len(steps) != 1:
            return None
        s, d = start.pop(), steps.pop()
        mask = (1 << w) - 1
        if d not in (1, mask):
            return None
        d = 1 if d == 1 else -1
        # every trip of O that goes on to the next passes the guard
        seen, work = {outer_header}, [outer_header]
        while work and g != outer_header:
            b0 = work.pop()
            for n_ in f.blocks[b0][-1].successors():
                if n_ in outer_blocks and n_ != g and n_ not in seen:
                    seen.add(n_)
                    work.append(n_)
        if g != outer_header and any(lt in seen for lt in latches):
            return None
        out.append(ZeroRoute(g, iv, w, s, d, cst, ((cst - s) * d) & mask))
    return out


def _signed_text(v: int, w: int) -> str:
    if w == 1:
        return "true" if v else "false"
    return str(v - (1 << w) if v >> (w - 1) & 1 else v)


def zero_trip_cost(o1: Path, llvm_bin: Path, f: "D.Function", header: str,
                   routes: Sequence[ZeroRoute]) -> Optional[Tuple[int, str]]:
    """(N, why): every input on which the C oracle reports 0 trips of the loop at `header` executes at
    least N loop headers first (the comment above), from `routes` (zero_routes); None when the
    function cannot be copied as the bound needs."""
    text = o1.read_text()
    if re.search(r"^%\d+ = type", text, re.M):
        return None
    m = re.search(r"^define [^\n]*" + re.escape(f.name) + r"\(.*?^\}\n?", text, re.M | re.S)
    if not m or " asm " in m.group(0):
        return None
    body = m.group(0)
    lines = body.split("\n")
    entry_n = sum(1 for _, pn in f.params if re.fullmatch(r"%\d+", pn))
    has_entry_label = len(lines) > 1 and re.match(r"^[-\w.$\"]+:", lines[1]) is not None
    copies, slots = [], []
    for ri, r in enumerate(routes):
        for i in range(min(r.trips, ZERO_COST_EVALS)):
            v = (r.start + i * r.step) & ((1 << r.width) - 1)
            name = f"{f.name}.cqz{ri}.{i}"
            out = []
            for k, ln in enumerate(lines):
                if not re.match(r"\s*" + re.escape(r.iv) + r" = ", ln):
                    ln = re.sub(re.escape(r.iv) + r"(?![-\w.$])", _signed_text(v, r.width), ln)
                ln = re.sub(r"%(\d+)(?![-\w.$])", r"%cqv\1", ln)
                ln = re.sub(r"^(\d+):", r"cqv\1:", ln)
                if k == 0:
                    ln = ln.replace(f.name + "(", name + "(", 1)
                    ln = re.sub(r" comdat(\([^)]*\))?", "", ln)
                    out.append(ln)
                    if not has_entry_label:
                        out.append(f"cqv{entry_n}:")
                    continue
                out.append(ln)
            copies.append("\n".join(out))
            slots.append((ri, v, name))
    if not copies:
        return None
    with tempfile.TemporaryDirectory(prefix="cq-zero-") as tmp:
        src = Path(tmp) / "copies.ll"
        src.write_text(text + "\n" + "\n".join(copies) + "\n")
        r_ = subprocess.run([str(llvm_bin / "opt"), "-passes=instsimplify,print<scalar-evolution>",
                             "-disable-output", str(src)], capture_output=True, text=True)
    if r_.returncode != 0:
        return None
    hdr = "%cqv" + header[1:] if re.fullmatch(r"%\d+", header) else header
    exact: Dict[str, int] = {}
    fn = None
    for line in r_.stderr.splitlines() + r_.stdout.splitlines():
        mf = _SCEV_FN.match(line)
        if mf:
            fn = "@" + mf.group(1)
            continue
        me = _SCEV_EXACT.match(line)
        if me and fn and me.group(1) == hdr:
            exact[fn] = int(me.group(3)) % (1 << int(me.group(2)))
    best: Optional[Tuple[int, str]] = None
    for ri, r in enumerate(routes):
        hs = [exact[n] + 1 if n in exact else 1 for ri2, _, n in slots if ri2 == ri]
        n_ = r.trips
        total = (n_ + 1) + sum(hs) + (n_ - len(hs))
        shown = ", ".join(str(h) for h in hs[:3]) + (f", ..., {hs[-1]}" if len(hs) > 3 else "")
        why = (f"the guard in {r.guard} skips the loop only where {r.iv} == {_signed_text(r.skip_at, r.width)}, and "
               f"{r.iv} runs {_signed_text(r.start, r.width)}, {_signed_text((r.start + r.step) & ((1 << r.width) - 1), r.width)}, "
               f"... in each activation of the enclosing loop, so {n_} trips of it come first (with {n_ + 1} executions of "
               f"its header), each entering the loop at {header}, which runs h = {shown or 'none'} header executions in "
               f"them (LLVM ScalarEvolution on a copy with {r.iv} fixed, after instsimplify"
               + (f"; the first {len(hs)} trips computed, each other counted 1" if len(hs) < n_ else "") + ")")
        if best is None or total < best[0]:
            best = (total, why)
    return best


def _trip_fact_lines(args: List[str], o1: Path, llvm_bin: Path, tmax: int) -> str:
    from cqcheck import oracle
    plugin, _ = oracle.toolchain()
    r = subprocess.run([str(llvm_bin / "opt"), f"-load-pass-plugin={plugin}", *args,
                        f"-cq-trip-max={tmax}", "-disable-output", str(o1)], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"opt {' '.join(args)} on {o1} exited {r.returncode}: {r.stderr.strip()[:500]}")
    return r.stdout


# The program the C oracle runs, as far as a bound through a driver-defined body needs: inlined, forwarded, no loop pass
# and no CFG change a trip count would notice (TripFacts.cpp, -cq-trip-named).
_LINKED_FACTS = "cq-trip-name,cgscc(inline),function(sroa,early-cse<memssa>),cq-trip-facts"


def _linked_with_bodies(o1: Path, bodies: List[str], llvm_bin: Path, dest: Path) -> Path:
    """The .O1.ll linked with the drivers.txt line's prototype field, -O1 as the driver compiles it."""
    src = dest / "bodies.c"
    src.write_text(D.DRIVER_PRELUDE + "\n" + "\n".join(p if p.endswith("}") else p.rstrip(";") + ";"
                                                         for p in (b.strip() for b in bodies)) + "\n")
    triple = re.search(r'^target triple = "([^"]+)"', o1.read_text(), re.M)
    bc, linked = dest / "bodies.ll", dest / "linked.ll"
    for cmd in ([str(llvm_bin / "clang"), "-std=gnu17", "-O1", "-w", "-S", "-emit-llvm",
                 *(["-target", triple.group(1)] if triple else []), str(src), "-o", str(bc)],
                [str(llvm_bin / "llvm-link"), "-S", str(o1), str(bc), "-o", str(linked)]):
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(f"{cmd[0]} on {src} exited {r.returncode}: {r.stderr.strip()[:500]}")
    return linked


def trip_facts(o1: Path, llvm_bin: Path, tmax: int, bodies: Sequence[str] = ()) -> Dict[str, Dict[int, str]]:
    """{"<fn>:<header>": {target: proof}} from the oracle plugin's cq-trip-facts pass (TripFacts.cpp,
    cq-97oj): LLVM's ScalarEvolution and ValueTracking on the .O1.ll (value-set and domain proofs). `bodies`
    is the prototype field of a drivers.txt line that defines functions, part of the C program under test: with them LLVM also
    sees what those functions do (rulings 2 B, cq-b0rl, 203's ext_fill), and what it proves there counts too. A target
    still unproved stays MISSING, never dead."""
    text = _trip_fact_lines(["-passes=cq-trip-facts"], o1, llvm_bin, tmax)
    if bodies:
        with tempfile.TemporaryDirectory(prefix="cq-trip-") as tmp:
            linked = _linked_with_bodies(o1, list(bodies), llvm_bin, Path(tmp))
            text += _trip_fact_lines([f"-passes={_LINKED_FACTS}", "-cq-trip-named"], linked, llvm_bin, tmax)
    out: Dict[str, Dict[int, str]] = {}
    for line in text.splitlines():
        parts = line.split("\t")
        if len(parts) == 5 and parts[0] == "cq-trip-fact":
            out.setdefault(parts[1], {}).setdefault(int(parts[2]), f"{parts[3]} proof (cq-97oj): {parts[4]}")
    return out


def loop_facts(example_dir: Path, llvm_bin: Path, spec: Optional[DriverSpec] = None) -> Dict[str, LoopFacts]:
    """LoopFacts per loop of the example's .O1.ll, keyed as the trips class keys them (T1). `spec`: its
    drivers.txt line, whose function bodies are part of the program (trip_facts)."""
    from cqcheck import sampling
    o1 = sorted(Path(example_dir).glob("*.O1.ll"))[0]
    mod = D.read_module(o1)
    counts = scev_counts(o1, llvm_bin)
    # the whole prototype field when it defines a function: a body may use what the others declare
    bodies = list(spec.protos) if spec and any(p.strip().endswith("}") for p in spec.protos) else []
    static = trip_facts(o1, llvm_bin, sampling.K + 1, bodies)
    ins = sampling.Instrumenter(mod, None)
    out: Dict[str, LoopFacts] = {}
    for f in mod.functions.values():
        for lp in ins.find_loops(f):
            key = lp.key()
            c = counts.get(key, {})
            out[key] = LoopFacts(c.get("exact"), c.get("max"),
                                 _zero_proof(f, lp.header, lp.blocks, lp.parent is None),
                                 _region_may_exit(f, lp.header, lp.blocks), static.get(key))
    return out


# --------------------------------------------------------------------------------------------
# The gaps of one sample set


def sample_gaps(spec: DriverSpec, ss: SampleSet, example_dir: Path, llvm_bin: Path) -> List[Gap]:
    """Every MISSING, IMPOSSIBLE and NOTE gap of `ss`; check_sample_set's problems are MISSING."""
    from cqcheck import sampling
    gaps = [Gap(MISSING, "sample set", p) for p in sampling.check_sample_set(spec, ss)]
    c = ss.classes

    def per_call(name: str, d: dict) -> None:
        for key in sorted(d, key=lambda k: int(k) if k.isdigit() else -1):
            e = d[key]
            reasons = [e["empty"]] if "samples" not in e and e.get("empty") else []
            if "samples" in e and e.get("subst"):
                reasons.append(f"substituted cq_theta sites: {e['subst']}")
            for why in reasons:
                kind = classify_reason(why)
                if kind:
                    gaps.append(Gap(kind, f"{name}: call {key}", why))

    for name in ("edge", "specials", "exhaustive"):
        per_call(name, c.get(name, {}))
    per_call("random_seed.quantum", c.get("random_seed", {}).get("quantum", {}))
    per_call("random_seed.classical", c.get("random_seed", {}).get("classical", {}))

    tr = c.get("trips", {})
    if not tr.get("loops") and tr.get("empty"):
        kind = classify_reason(tr["empty"])
        if kind:
            gaps.append(Gap(kind, "trips", tr["empty"]))
    facts: Optional[Dict[str, LoopFacts]] = None
    for lp in tr.get("loops", []):
        for target, e in sorted(lp["trips"].items(), key=lambda kv: int(kv[0])):
            if "sample" in e or not e.get("empty"):
                continue          # a target with neither is check_sample_set's problem
            where = f"trips: {lp['loop']} trip {target}"
            if "uncovered" in e:          # its reason names what trip 0 is for this loop
                gaps.append(Gap(UNCOVERED, where, e["empty"]))
                continue
            if int(target) == 0 and lp.get("zero"):
                where += f" ({lp['zero']})"        # what trip 0 is for this loop (cq-g8md)
            kind = classify_reason(e["empty"])
            if kind == MISSING:
                if facts is None:
                    facts = loop_facts(example_dir, llvm_bin, spec)
                proof = facts.get(lp["loop"], LoopFacts()).impossible(lp["loop"], int(target))
                if proof:
                    gaps.append(Gap(IMPOSSIBLE, where, proof))
                    continue
            if kind:
                gaps.append(Gap(kind, where, e["empty"]))

    rows = c.get("totalization", {}).get("rows", [])
    imp = [r for r in rows if not r.get("samples") and classify_reason(r.get("empty", "")) == IMPOSSIBLE]
    unf = [r for r in rows if not r.get("samples") and r not in imp]
    if imp:
        gaps.append(Gap(IMPOSSIBLE, "totalization",
                        f"{len(imp)} of {len(rows)} CR §2 rows outside the domain or never hit "
                        f"(first: {imp[0].get('site')} {imp[0].get('row')}: {imp[0].get('empty')})"))
    if unf:
        gaps.append(Gap(NOTE, "totalization",
                        f"{len(unf)} of {len(rows)} CR §2 rows not hit by any sample, not a class CLAUDE.md "
                        f"requires (first: {unf[0].get('site')} {unf[0].get('row')}: {unf[0].get('empty')})"))
    return gaps


# --------------------------------------------------------------------------------------------
# The checks `sampling --confirm` runs, for report.evaluate


def domain_check(spec: DriverSpec, example_dir: Path, ss: SampleSet) -> List[str]:
    """sampling.domain_problems (every sample inside the C program's domain as the oracle runs it),
    cached beside the sample set under the same key: it is a function of the sample set."""
    import json
    import os
    from cqcheck import sampling
    cache = sampling._cache_dir() / f"{spec.example}.{sampling._cache_key(spec, Path(example_dir))}.domain.json"
    if cache.exists():
        from cqcheck import cachegc
        cachegc.used(cache)
        return list(json.loads(cache.read_text()))
    bad = list(sampling.domain_problems(spec, Path(example_dir), ss))
    cache.parent.mkdir(parents=True, exist_ok=True)
    tmp = cache.with_suffix(f".tmp{os.getpid()}")
    tmp.write_text(json.dumps(bad))
    tmp.replace(cache)
    return bad


def trip_samples(ss: SampleSet) -> List[int]:
    """The indices of the trip class's samples."""
    return sorted({e["sample"] for lp in ss.classes.get("trips", {}).get("loops", [])
                   for e in lp["trips"].values() if "sample" in e})


def confirm_trips(ss: SampleSet, runs: Dict[str, object]) -> List[str]:
    """sampling.confirm_trips over oracle runs keyed by the sample's JSON (sort_keys): each trip
    sample must give its count in the C oracle's trip counters. A trip sample with no run, or one
    that failed, is a disagreement."""
    import json
    from cqcheck import sampling

    def trip_run(smp):
        r = runs.get(json.dumps(smp, sort_keys=True))
        if r is None:
            raise RuntimeError(f"no C oracle run of trip sample {smp}")
        if r.failed:
            raise RuntimeError(f"oracle: sample {smp} cannot run: {r.reason}")
        return r.events, r.loops
    return sampling.confirm_trips(ss, trip_run)
