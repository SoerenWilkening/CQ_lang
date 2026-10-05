#!/usr/bin/env python3
"""shipped_guard_model.py — a TEXT MODEL OF THE SHIPPED M-A GUARD (b4e329b).

⚠ DATED SNAPSHOT, NOT THE GUARD'S DEFINITION (marked 2026-10-05, bd gl3x / bd
cmr9). It mirrors the guard at b4e329b and nothing later; no ctest or lit run
calls it. Since then the guard's clause 4 has diverged: an unguarded
`cqrt_tape_write_<W>(tape, R)` before the gate also exempts `R` (bd gl3x), and a
measurement exempts only if no gate writes `R` between it and the gate
(`railUnmovedInWindow`, bd cmr9). This model still reads clause 4 as
"measured before the gate". The definition is `recordIsExemptAt`
(`ir-pass/src/RotationLowering.cpp`, contract in
`ir-pass/include/RotationLowering.h`). Re-sync before using this model's
verdicts as a measurement of the shipped guard.

WHAT THIS IS
============
A line-for-line mirror, over LOWERED IR text, of `warnLiveRecordRotations`
(`ir-pass/src/RotationLowering.cpp` ~:590-1352, contract in
`ir-pass/include/RotationLowering.h` :80-190) as it SHIPPED in commit b4e329b
("Inc 3 — M-A ANCESTOR half + copy-destination class + the observing-sink
clause 3"). It exists because census 0.1 encoded the RETIRED clause-3 reading
("a post-gate MENTION exempts") and therefore measured a predicate the compiler
no longer has (bd `test_C_libtooling-rtg5`).

It models, per chained-rotation site `T` on wire `W`:

  CLAUSE 1  the record set — three closures over ONE shared set:
              (a) ANCESTORS of `W`, backward through `cq_template_*` /
                  `cqrt_qram_load_*` / `__cq_q_*` rail operands, through
                  phi/select routers, and across the COPY-DESTINATION edge
                  (a rail that is a void `cqrt_copy_<W>[_controlled]`'s DST
                  hops back to its SRC and CTRL). `cqrt_alloc_*` is a record but
                  its operand is a classical seed, so the walk stops there.
              (b) DESCENDANTS of `W`, forward, pushing clone RESULTS and
                  following the copy SRC->DST edge.
              (c) DESCENDANTS OF EVERY ANCESTOR (the "transitively entangled"
                  sibling closure).
            `cqrt_qram_alloc_*` (the QRAM ARRAY class) stops the walk dead in
            both directions — ruled deferred.
  CLAUSE 2  not discharged before `T` (`cqrt_free(R)`, or an `_unc` whose OUT
            slot is `R`; `cqrt_qram_store_*_unc` excluded — it mints no rail).
  CLAUSE 3  DEAD as user data at `T` — no post-gate use of `R` whose lineage
            reaches an OBSERVING SINK (`reachesObservingSink`'s SINK / HOP /
            NON-USE grammar, F1+F2+round-2 N1/N2/N3 as shipped).
  CLAUSE 4  not measured before `T` (the b4e329b reading; see the DATED
            SNAPSHOT note above for what the shipped guard asks today).
  CLAUSE 5  not `W` itself.
  CLAUSE 6  `R` EXISTS at `T` — `provablyBefore(T, R)` is false.

POSITION IS MODELLED WITH A REAL CFG, NOT WITH TEXTUAL ORDER
------------------------------------------------------------
The guard's `provablyBefore(A, B)` is `DT.dominates(A, B) &&
!isPotentiallyReachable(B, A)` (WireWalk.h). Clauses 2/3/4/6 are all position
questions, so census 0.1's blind spot A1 ("program order = textual order") is
LOAD-BEARING for every one of them. This model therefore builds, per function
and lazily, the CFG that `free_pairing_check.parse_module` already recovered:

  * `dominates(a, b)` — the classic iterative dataflow dominator computation over
    the block list in textual order (LLVM prints blocks in RPO for the shapes
    here). An UNREACHABLE `b` is dominated by everything, mirroring LLVM's own
    vacuous answer, which is what makes the guard's F3 finding reproducible.
  * `potentially_reachable(from, to)` — forward BFS over the successor graph,
    memoized; a block is in its own reach set iff it sits on a cycle, which is
    exactly the loop back edge that makes the guard's clause-6 modality bite.
  * F3 — a use in a block with no entry path observes nothing, so it is skipped
    before the position test, as `recordIsExemptAt` does.

WHAT IT STILL CANNOT SEE (all reported as counters, never absorbed)
-------------------------------------------------------------------
  S1  `taint.SpineOps` is EMITTER-RECORDED and has no textual signature. The
      guard reads it through `isTeardownUse`, which runs BEFORE the hop arms, so
      a SpineOps-recorded `cqrt_cnot` / `cqrt_toffoli` / `cqrt_copy_*_controlled`
      is a NON-USE for the guard and a HOP for this model. Every such hop is
      counted in `spine_indistinguishable_hops`. DIRECTION: this model EXEMPTS
      more than the guard, i.e. it UNDER-reports the guard's population. The only
      emitter that puts such gates in `SpineOps` today is `BreakReversePlay`
      (`clearAndFree` / `clearChainAndFree`), so the residual is confined to the
      7.4 loop-break slices. `_unc`, `cqrt_free` and the negated-angle adjoint
      rotations are ALSO in `SpineOps`, but each is recognizable by NAME here and
      is a non-use for an independent reason, so they carry no such residual.
  S2  The clone hop is per-argument in the guard (`cloneArgReachesResult` —
      "an argument the callee never READS gets no hop"). Parameter use is a
      property of the CALLEE BODY, which this text model does not interprocedurally
      resolve, so it HOPS unconditionally and counts every one in
      `clone_hops_unchecked`. DIRECTION: exempts more than the guard.
  S3  QRAM store -> subsequent load is walked with the real `provablyBefore`
      above, but the array cell CONTENT is never modelled (as in the guard).
  S4  A record is a value defined by a CALL. A rail arriving as a function
      PARAMETER (a Phase-6 clone body's argument) is `Opaque` here exactly as
      `classifyRail` makes it Opaque there (an `Argument` is not a `CallInst`).

NOT A SECOND SPELLING OF THE GUARD (Rule 14 note)
-------------------------------------------------
This is a MEASUREMENT model, not a predicate the compiler consults. It is kept
in one file, named after the commit it mirrors, so that "the census models the
shipped guard" is checkable by reading two files side by side rather than by
trusting a sentence. Every divergence above is a counter in the output.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import census_common as cc  # noqa: E402

fpc = cc.fpc

OPAQUE, RECORD, ROUTER, QRAM = "opaque", "record", "router", "qram-array"

# `RotationLowering.cpp`'s `kMsgLiveRecord`, character for character. The
# validation harness matches `cq-opt` stderr against this, so a drift here shows
# up as "the guard reported something else", never as a silent pass.
#
# STDERR IS NOW THE ONLY CHANNEL (M-A Increment 7b, owner ruling 2026-08-29 / bd
# test_C_libtooling-lyyf): the guard emits a `DS_Warning` and `opt` exits ZERO
# whether or not it fired, so a matcher that keyed on the exit code would report
# every one of the guard's own fixtures as a disagreement. `census_01`'s
# `validate_guard` was corrected for that; anything else comparing verdicts must
# do the same.
MSG_LIVE_RECORD = ("cq rotation lowering: non-diagonal gate over a live "
                   "derived record")


# ---------------------------------------------------------------------------
# Symbol predicates — one per named helper in RotationLowering.cpp.
# ---------------------------------------------------------------------------

def is_record_producer(c):
    """`isRecordProducer` — a NON-VOID `cq_template_*` / `cqrt_qram_load_*`."""
    if c.res is None:
        return False
    s = c.sym
    if s.endswith("_unc") or s.endswith("_inv"):
        return False
    return s.startswith("cq_template_") or s.startswith("cqrt_qram_load_")


def is_alloc_rail(c):
    """`isAllocRail` — `cqrt_alloc_*` (NOT `cqrt_qram_alloc_*`; disjoint prefixes)."""
    return c.sym.startswith("cqrt_alloc_")


def is_qram_array(c):
    """`isQramArrayHandle` — severance class 4, ruled deferred."""
    return c.sym.startswith("cqrt_qram_alloc_")


def is_clone_hop(c):
    """`isCloneCallHop` — a non-void `@__cq_q_*` that is not the `_unc` twin."""
    return (c.res is not None and c.sym.startswith("__cq_q_")
            and not c.sym.endswith("_unc"))


def is_copy_gate(c):
    """`isCopyGate` — a VOID `cqrt_copy_<W>[_controlled]`, DST last, arity 2|3."""
    return (c.res is None and c.sym.startswith("cqrt_copy_")
            and len(c.vals) in (2, 3))


def qram_store_arr_pos(c):
    """`isQramStoreGate` -> the ARRAY operand index, or None."""
    if c.res is not None or not c.sym.startswith("cqrt_qram_store_"):
        return None
    if c.sym.endswith("_controlled") and len(c.vals) == 4:
        return 1
    if not c.sym.endswith("_controlled") and len(c.vals) == 3:
        return 0
    return None


def is_discharge_of(c, r):
    """`isDischargeOf` — `cqrt_free(R)`, or an out-first `_unc` whose OUT is R.

    `cqrt_qram_store_*_unc` is excluded exactly as in the guard: it takes the
    same args as its forward and mints no rail, so it discharges none.
    """
    if c.sym == "cqrt_free":
        return len(c.vals) == 1 and c.vals[0] == r
    if not c.sym.endswith("_unc") or c.sym.startswith("cqrt_qram_store_"):
        return False
    return len(c.vals) >= 1 and c.vals[0] == r


def is_teardown_name(sym):
    """The NAME-recognizable half of `isTeardownUse`.

    `cqrt_free` and the `_unc` family are compiler-emitted only (Rule 6 /
    `EmitInverse`), so the name IS the proof. The rotation arm and the
    `taint.SpineOps` arm are handled by the caller: under the F2 ruling ALL
    rotations are non-uses anyway, and `SpineOps` has no textual signature (S1).
    """
    return sym == "cqrt_free" or sym.endswith("_unc")


# ---------------------------------------------------------------------------
# One function: CFG + def/use index + the two clause-1 walks + clause 3.
# ---------------------------------------------------------------------------

class ShippedFn:
    """The shipped guard's view of ONE lowered function.

    `lf` is a `census_common.LoweredFn` (fpc call stream + raw line range);
    `instrs` is `source_ir.parse_functions()`'s instruction list for the SAME
    function, used only for the NON-CALL lines (`ret`, `phi`, `select`, plain
    IR), which the call parser does not model.
    """

    def __init__(self, lf, instrs):
        self.lf = lf
        self.calls = lf.calls
        self.call_lines = {c.line for c in self.calls}
        self.idx_of_line = {c.line: i for i, c in enumerate(self.calls)}
        # NON-call instructions only — a call line is owned by the fpc parse.
        self.ir = [i for i in (instrs or []) if i.line not in self.call_lines]

        self.def_call = {}   # value -> Call
        self.def_ir = {}     # value -> Instr
        self.use_call = {}   # value -> [Call]
        self.use_ir = {}     # value -> [Instr]
        for c in self.calls:
            if c.res is not None:
                self.def_call[c.res] = c
        for ins in self.ir:
            if ins.res is not None:
                self.def_ir[ins.res] = ins
        for c in self.calls:
            for v in dict.fromkeys(c.vals):
                if v.startswith("%"):
                    self.use_call.setdefault(v, []).append(c)
        for ins in self.ir:
            for v in dict.fromkeys(ins.operands):
                if v.startswith("%"):
                    self.use_ir.setdefault(v, []).append(ins)

        self._cfg = None
        self._reach = {}
        # Divergence counters (S1/S2 in the module docstring).
        self.spine_indistinguishable_hops = 0
        self.clone_hops_unchecked = 0
        self.unreachable_uses_skipped = 0

    # -- CFG ---------------------------------------------------------------
    def _build_cfg(self):
        """Block-of-line, entry, dominators, successors. Built lazily: only a
        function that actually holds a guard site pays for it."""
        line_block, cur = {}, "%__entry"
        for ln, txt in self.lf.raw_lines():
            m = fpc.LABEL_RE.match(txt)
            if m:
                cur = "%" + m.group(1)
                continue
            line_block[ln] = cur
        blocks = [b for b, _, _ in self.lf.fn.blocks]
        # fpc opens a phantom "%__entry" before the first label; when the
        # function's first block IS labelled, that phantom is empty (no calls,
        # no terminator) and the real entry is the next block.
        entry = blocks[0] if blocks else "%__entry"
        for label, calls, term in self.lf.fn.blocks:
            if calls or term:
                entry = label
                break
        succ = {b: [s for s in self.lf.fn.succ.get(b, []) if s in set(blocks)]
                for b in blocks}
        # Reachability from entry.
        seen, stack = {entry}, [entry]
        while stack:
            b = stack.pop()
            for s in succ.get(b, ()):
                if s not in seen:
                    seen.add(s)
                    stack.append(s)
        # Dominators: init to ALL, refine only over reachable blocks, so an
        # unreachable block stays dominated by everything (LLVM's vacuous
        # answer, and the reason the guard needed its F3 reachability test).
        allb = set(blocks)
        dom = {b: set(allb) for b in blocks}
        if entry in dom:
            dom[entry] = {entry}
        order = [b for b in blocks if b in seen and b != entry]
        changed = True
        while changed:
            changed = False
            for b in order:
                ps = [p for p in self.lf.fn.preds.get(b, []) if p in seen]
                if ps:
                    new = set(dom[ps[0]])
                    for p in ps[1:]:
                        new &= dom[p]
                else:
                    new = set()
                new.add(b)
                if new != dom[b]:
                    dom[b] = new
                    changed = True
        self._cfg = {"line_block": line_block, "entry": entry, "succ": succ,
                     "dom": dom, "reachable": seen, "blocks": blocks}

    def cfg(self):
        if self._cfg is None:
            self._build_cfg()
        return self._cfg

    def block_of(self, line):
        return self.cfg()["line_block"].get(line, self.cfg()["entry"])

    def reachable_line(self, line):
        return self.block_of(line) in self.cfg()["reachable"]

    def _reach_from(self, b):
        """Blocks reachable from `b` in >= 1 step (so `b` is in its own reach
        set iff `b` sits on a cycle)."""
        if b in self._reach:
            return self._reach[b]
        succ = self.cfg()["succ"]
        seen, stack = set(), list(succ.get(b, ()))
        while stack:
            x = stack.pop()
            if x in seen:
                continue
            seen.add(x)
            stack.extend(succ.get(x, ()))
        self._reach[b] = seen
        return seen

    def dominates(self, la, lb):
        ba, bb = self.block_of(la), self.block_of(lb)
        if ba == bb:
            return la < lb
        if bb not in self.cfg()["reachable"]:
            return True  # vacuous, as LLVM's DT answers for an unreachable use
        return ba in self.cfg()["dom"].get(bb, set())

    def potentially_reachable(self, lfrom, lto):
        bf, bt = self.block_of(lfrom), self.block_of(lto)
        if bf == bt:
            return lto > lfrom or bf in self._reach_from(bf)
        return bt in self._reach_from(bf)

    def provably_before(self, la, lb):
        """`WireWalk.h`'s `provablyBefore(A, B)`: IF B executes, A already did,
        AND A never runs again after it."""
        return self.dominates(la, lb) and not self.potentially_reachable(lb, la)

    # -- clause 1 ----------------------------------------------------------
    def classify_rail(self, v):
        ins = self.def_ir.get(v)
        if ins is not None and ins.opcode in ("phi", "select"):
            return ROUTER
        c = self.def_call.get(v)
        if c is None:
            return OPAQUE
        if is_qram_array(c):
            return QRAM
        if is_record_producer(c) or is_alloc_rail(c) or is_clone_hop(c):
            return RECORD
        return OPAQUE

    def _collect_ancestors(self, wire, rs):
        """`collectAncestorRecords` — returns the SEEDS for the sibling pass."""
        seeds, work, visited = [], [wire], {wire}

        def enqueue(v):
            if v and v.startswith("%") and v not in visited:
                visited.add(v)
                work.append(v)

        while work:
            v = work.pop()
            k = self.classify_rail(v)
            if k == QRAM:
                continue
            if k != OPAQUE:
                rs.push(v, "ancestor")
                seeds.append(v)
            # (c) COPY-DESTINATION edge, backward.
            for c in self.use_call.get(v, ()):
                if not is_copy_gate(c):
                    continue
                n = len(c.vals)
                if c.vals[n - 1] != v:
                    continue
                enqueue(c.vals[n - 2])
                if n == 3:
                    enqueue(c.vals[0])
            if k == ROUTER:
                for op in self.def_ir[v].operands:
                    enqueue(op)
                continue
            c = self.def_call.get(v)
            if c is None:
                continue
            if is_alloc_rail(c):
                continue  # (b) classical seed — stop
            if not (is_record_producer(c) or is_clone_hop(c)):
                continue
            for op in c.vals:  # (a) PRODUCER edge
                # `isa<Instruction>(Op)`: a literal is a Constant and a formal
                # parameter is an Argument — both stop the walk.
                if op.startswith("%") and (op in self.def_call
                                           or op in self.def_ir):
                    enqueue(op)
        return seeds

    def _collect_descendants(self, seed, rs, seen, origin):
        """`collectDescendantRecords`."""
        if seed in seen:
            return
        seen.add(seed)
        work = [seed]
        while work:
            v = work.pop()
            if self.classify_rail(v) == QRAM:
                continue
            for c in self.use_call.get(v, ()):
                if is_copy_gate(c):
                    n = len(c.vals)
                    if c.vals[n - 2] != v:
                        continue
                    dst = c.vals[n - 1]
                    if dst in seen:
                        continue
                    seen.add(dst)
                    rs.push(dst, origin)
                    work.append(dst)
                    continue
                if not (is_record_producer(c) or is_clone_hop(c)):
                    continue
                if c.res is None or c.res in seen:
                    continue
                seen.add(c.res)
                rs.push(c.res, origin)
                work.append(c.res)

    def record_set(self, wire):
        """Clause 1's three passes over ONE shared set -> [(rail, origin)]."""
        rs = _RecordSet(self, wire)
        seeds = self._collect_ancestors(wire, rs)
        seen = set()
        self._collect_descendants(wire, rs, seen, "descendant")
        for s in seeds:
            self._collect_descendants(s, rs, seen, "sibling")
        return rs.out, rs.origin

    # -- clause 3 ----------------------------------------------------------
    def reaches_observing_sink(self, use_line, use_obj, r):
        """`reachesObservingSink` — SINKS / HOPS / NON-USES verbatim.

        `use_obj` is a `Call` or a `source_ir.Instr`; the walk carries the
        INCOMING value with each use because a copy gate and a QRAM store
        classify by WHICH SLOT the tracked value sits in.
        """
        work, seen_use, scanned = [], set(), set()

        def push_use(in_v, u, line):
            if not self.reachable_line(line):
                self.unreachable_uses_skipped += 1
                return  # F3 — an instruction that can never execute observes nothing
            k = (in_v, line)
            if k in seen_use:
                return
            seen_use.add(k)
            work.append((in_v, u, line))

        def push_value(v):
            if not v or not v.startswith("%") or v in scanned:
                return
            scanned.add(v)
            for c in self.use_call.get(v, ()):
                push_use(v, c, c.line)
            for ins in self.use_ir.get(v, ()):
                push_use(v, ins, ins.line)

        push_use(r, use_obj, use_line)
        while work:
            in_v, u, _ln = work.pop()
            if not isinstance(u, fpc.Call):
                # A non-call instruction. `ret` is a SINK (escape); a router
                # HOPS; everything else observes nothing.
                if u.opcode == "ret":
                    return True
                if u.opcode in ("phi", "select") and u.res:
                    push_value(u.res)
                continue
            n_args = len(u.vals)
            sym = u.sym
            # ── SINKS ──
            if sym.startswith("cqrt_measure_"):
                return True
            if sym.startswith("cqrt_tape_write_"):
                if n_args >= 2 and u.vals[n_args - 1] == in_v:
                    return True          # the WRITTEN slot
                if n_args == 3 and u.vals[0] == in_v:
                    return True          # the CTRL slot of the guarded write (N2)
            # ── NON-USES ──
            if is_teardown_name(sym) or sym.endswith("_inv"):
                continue
            if sym.startswith("cqrt_ry_") or sym.startswith("cqrt_rz_"):
                continue                 # the F2 ruling: a rotation observes nothing
            if sym in ("cqrt_cswap", "cqrt_x"):
                continue                 # route / bracket gates
            # ── HOPS ──
            if ((sym == "cqrt_cnot" and n_args == 2)
                    or (sym == "cqrt_toffoli" and n_args == 3)):
                for k in range(n_args - 1):     # a CONTROL hops to the TARGET (N1)
                    if u.vals[k] == in_v:
                        self.spine_indistinguishable_hops += 1
                        push_value(u.vals[n_args - 1])
                        break
                continue
            if is_copy_gate(u):
                if (u.vals[n_args - 2] == in_v
                        or (n_args == 3 and u.vals[0] == in_v)):
                    if n_args == 3:
                        self.spine_indistinguishable_hops += 1
                    push_value(u.vals[n_args - 1])
                continue
            arr_pos = qram_store_arr_pos(u)
            if arr_pos is not None:
                if not any(k != arr_pos and u.vals[k] == in_v
                           for k in range(n_args)):
                    continue
                arr = u.vals[arr_pos]
                for load in self.use_call.get(arr, ()):
                    if load.res is None:
                        continue
                    if (not load.sym.startswith("cqrt_qram_load_")
                            or load.sym.endswith("_unc")):
                        continue
                    if not self.provably_before(u.line, load.line):
                        continue  # "SUBSEQUENT" only
                    push_value(load.res)
                continue
            if is_clone_hop(u):
                # S2: `cloneArgReachesResult` needs the CALLEE BODY. Hop, and
                # count it — this model exempts more than the guard here.
                self.clone_hops_unchecked += 1
                push_value(u.res)
                continue
            if is_record_producer(u):
                push_value(u.res)
                continue
            # Everything else: not a sink, not a hop — the decline direction.
        return False

    # -- clauses 2/3/4 for one record --------------------------------------
    def record_is_exempt_at(self, r, t_line):
        """`recordIsExemptAt` -> (exempt, clause, witness)."""
        for c in self.use_call.get(r, ()):
            if is_discharge_of(c, r) and self.provably_before(c.line, t_line):
                return True, 2, f"{c.line}:{c.sym}"
            if (c.sym.startswith("cqrt_measure_")
                    and self.provably_before(c.line, t_line)):
                return True, 4, f"{c.line}:{c.sym}"
        uses = [(c.line, c) for c in self.use_call.get(r, ())]
        uses += [(i.line, i) for i in self.use_ir.get(r, ())]
        uses.sort(key=lambda x: x[0])
        for line, u in uses:
            if not self.reachable_line(line):
                continue
            if not self.provably_before(t_line, line):
                continue
            if self.reaches_observing_sink(line, u, r):
                what = u.sym if isinstance(u, fpc.Call) else "ir:" + u.opcode
                return True, 3, f"{line}:{what}"
        return False, None, None

    # -- the whole verdict for one site ------------------------------------
    def verdict(self, t_idx):
        """-> dict for the `cqrt_ry` at call index `t_idx`, mirroring the loop
        body of `warnLiveRecordRotations`."""
        t = self.calls[t_idx]
        wire = t.vals[0] if t.vals else None
        out = {"wire": wire, "line": t.line, "hits": [], "records": [],
               "skipped_clause6": [], "exempt": []}
        if wire is None:
            return out
        records, origin = self.record_set(wire)
        for r in records:
            c = self.def_call[r]
            out["records"].append(f"{r}={c.sym}")
            if self.provably_before(t.line, c.line):
                out["skipped_clause6"].append(f"{r}={c.sym}")
                continue
            ok, clause, why = self.record_is_exempt_at(r, t.line)
            if ok:
                out["exempt"].append({"rail": f"{r}={c.sym}", "clause": clause,
                                      "witness": why})
                continue
            out["hits"].append({"rail": f"{r}={c.sym}",
                                "origin": origin.get(r, "?")})
        return out


class _RecordSet:
    """`RecordSet` — clause 5 (never the wire) + dedupe across the three walks."""

    def __init__(self, fn, wire):
        self.fn = fn
        self.wire = wire
        self.out = []
        self.seen = set()
        self.origin = {}

    def push(self, v, origin):
        if v == self.wire:
            return
        if v not in self.fn.def_call:
            return  # only a CALL can be a record (`dyn_cast<CallInst>`)
        if self.fn.classify_rail(v) != RECORD:
            return
        if v in self.seen:
            return
        self.seen.add(v)
        self.out.append(v)
        self.origin[v] = origin


# ---------------------------------------------------------------------------
# SELFTEST — `python3 shipped_guard_model.py --selftest`
#
# A model that has only ever been run on a corpus where the right answer is
# "MISS everywhere" is a model nobody should trust (the
# `free_pairing_check_test.py` precedent, CLAUDE.md's "a checker nobody has
# tried to fool"). These probes are hand-written LOWERED IR, held INLINE — not
# committed lit fixtures — because they test THIS FILE, not the compiler.
# Each names the clause it exercises and its expected verdict.
# ---------------------------------------------------------------------------

_PROLOGUE = """
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_x(i32)
declare void @cqrt_cswap(i32, i32, i32)
declare void @cqrt_cnot(i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_qram_alloc_i32(i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)
declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)
"""

# (name, body, ry-ordinal-under-test, expected hit rails, why)
_PROBES = [
    ("c3-dead-descendant", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
""", 1, ["%r"], "a descendant record with NO user at all is dead => HIT"),

    ("c3-observed-descendant", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
""", 1, [], "measured AFTER the gate => LIVE user data => exempt"),

    ("c3-rotation-is-not-an-observation", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  call void @cqrt_rz_i32(i32 %r, double 1.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
""", 1, ["%r"], "the F2 ruling: a phase on a never-observed register is a NON-USE"),

    ("c3-route-is-not-an-observation", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %w = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  call void @cqrt_cswap(i32 %r, i32 %h, i32 %w)
  call void @cqrt_x(i32 %r)
  ret i32 0
""", 1, ["%r"],
     "F1: a cswap/x route brings a value back to its own rail, so it observes "
     "nothing => %r is dead => HIT. NOTE THE OTHER HALF, which this probe "
     "measured rather than assumed: the WORK RAIL %w is NOT a record either — "
     "clause 1's walk follows producer / clone / copy-destination edges only, "
     "and a `cqrt_cswap` is none of them, so a Phase-4 route never puts its own "
     "work rail in the record set"),

    ("c3-hop-through-template-to-measure", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %s = call i32 @cq_template_add_i32_hl(i32 %r, i32 1)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
""", 1, [], "a template READ hops; the hop reaches a measure => exempt"),

    ("c3-cnot-control-hops-to-target", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %anc = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %f = call i32 @cq_template_icmp_sgt_i32_hl(i32 %r, i32 3)
  call void @cqrt_cnot(i32 %f, i32 %anc)
  %m = call i32 @cqrt_measure_i32(i32 %anc)
  ret i32 %m
""", 1, [], "round-2 N1: a CONTROL hops to the TARGET ancilla, which is measured"),

    ("c3-cnot-target-unobserved", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %anc = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %f = call i32 @cq_template_icmp_sgt_i32_hl(i32 %r, i32 3)
  call void @cqrt_cnot(i32 %f, i32 %anc)
  ret i32 0
""", 1, ["%r"],
     "the N1 DISCRIMINATOR: clause 3's walk hops CONTROL->TARGET, reaches the "
     "ancilla, and finds nothing reading it => no exemption => HIT. AND THE "
     "ASYMMETRY THIS PROBE PINS: %anc is NOT itself a record. Clause 3 hops "
     "through `cqrt_cnot`/`cqrt_toffoli` (round-2 N1) but clause 1 does NOT "
     "follow them, so a condition-tree ancilla never enters the record set. "
     "Directionally that is an ACCEPT, and it is unmeasured whether any shape "
     "reaches it: every emitter that mints such an ancilla "
     "(`SelectMergeEmit`, `ArmClassify`) strips and frees it inside its own "
     "region, which discharges it under clause 2 long before a later gate"),

    ("c3-tape-ctrl-slot-is-a-sink", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %t = call i32 @cqrt_tape_alloc()
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %f = call i32 @cq_template_icmp_sgt_i32_hl(i32 %r, i32 3)
  %e = call i32 @cqrt_tape_write_i32_controlled(i32 %f, i32 %t, i32 %h)
  ret i32 0
""", 1, [], "round-2 N2: the CTRL slot of a guarded tape write reveals the flag"),

    ("c2-discharged-before-the-gate", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  call void @cq_template_mul_i32_hl_unc(i32 %r, i32 %h, i32 3)
  call void @cqrt_free(i32 %r)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  ret i32 0
""", 1, [], "clause 2: `_unc` on its OWN out slot + free, provably before T"),

    ("c4-measured-before-the-gate", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  ret i32 %m
""", 1, [], "clause 4: collapsed before the gate, nothing left to dephase"),

    ("c6-minted-after-the-gate", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  ret i32 0
""", 1, [], "clause 6: a rail minted after the gate is not standing at it"),

    ("c1-ancestor-alloc-rail", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %p = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)
  call void @cqrt_ry_i32(i32 %p, double 2.500000e-01)
  ret i32 0
""", 1, ["%h"],
     "clause 1(a): the ALLOC-minted parent of an out-of-place template result"),

    ("c1-copy-destination", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %o = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h, i32 %o)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  ret i32 0
""", 1, ["%o"],
     "clause 1: the DST of a void copy is a record with no producer edge"),

    ("c1-qram-array-stops-the-walk", """
  %a = call i32 @cqrt_qram_alloc_i32(i32 4, i32 0)
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_qram_store_i32(i32 %a, i32 %h, i32 %h)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  ret i32 0
""", 1, [],
     "severance class 4 is ruled DEFERRED: the walk never enters the array"),

    ("c5-the-wire-is-never-a-record", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  ret i32 0
""", 1, [], "clause 5: the in-place gate chain on the same handle"),

    ("c3-branch-arm-use-exempts-permissively", """
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  br i1 %c, label %arm, label %out
arm:
  %m = call i32 @cqrt_measure_i32(i32 %r)
  br label %out
out:
  ret i32 0
""", 1, [],
     "the DOCUMENTED permissive edge (`b1`): dominance, not post-dominance"),

    ("c6-loop-back-edge-keeps-the-record", """
  br label %body
body:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %r = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  br i1 %c, label %body, label %out
out:
  ret i32 0
""", 1, ["%r"],
     "the clause-6 MODALITY: a back edge re-runs T over the record, so the "
     "textually-later mint still counts"),
]


def _selftest():
    import tempfile
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import source_ir as si
    fails = 0
    for name, body, ordinal, want, why in _PROBES:
        text = ("define i32 @probe(i32 %u, i1 %c) {\n" + body + "}\n"
                + _PROLOGUE)
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "probe.ll")
            with open(p, "w") as f:
                f.write(text)
            _, fns = cc.parse_lowered(p)
            instrs = si.parse_functions(p).get("probe")
            sf = ShippedFn(fns[0], instrs)
            rys = [i for i, c in enumerate(sf.calls)
                   if c.sym.startswith("cqrt_ry_")]
            v = sf.verdict(rys[ordinal])
            got = sorted(x["rail"].split("=")[0] for x in v["hits"])
        ok = got == sorted(want)
        fails += 0 if ok else 1
        print(f"  {'PASS' if ok else 'FAIL'} {name}: hits={got} "
              f"want={sorted(want)}")
        print(f"       {why}")
        if not ok:
            print(f"       records={v['records']} exempt={v['exempt']} "
                  f"clause6={v['skipped_clause6']}")
    print(f"\n{len(_PROBES) - fails}/{len(_PROBES)} probes pass")
    return 1 if fails else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(_selftest())
    print(__doc__)
