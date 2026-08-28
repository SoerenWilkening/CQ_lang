#!/usr/bin/env python3
"""census_01_guard_population.py — Inc-0 census 0.1: how many currently-GREEN
modules would the M-A guard (`declineLiveRecordRotations`) newly decline?

Settles Risk 3 of the record-family plan of record (bd test_C_libtooling-6uqc).
M-A is the permanent net that ships first: it declines a CHAINED `cq_theta`
whose wire carries LIVE UNOWNED RECORDS. Inc 1 ships the DESCENDANT half; Inc 3
adds the ANCESTOR half. This file measures both halves separately so the two
increments can be sized independently, and so "Inc 1 is shippable standalone" is
a measurement rather than a hope.

THREE PREDICATES, ALL ALWAYS COMPUTED
=====================================
`--predicate {ruled,ruled-spine-aware,plan-v1}` selects the HEADLINE population.
All three are computed on every run from the same parse of the same lowered
module, so the delta table this script prints is a difference between readings of
ONE measurement, not between runs. `ruled` is the default and is the OWNER-RULED
predicate encoded literally; `ruled-spine-aware` prices the ONE ambiguity found
while encoding it (see AMBIGUITY below) and is NOT a decision.

  `ruled`   (DEFAULT) — OWNER RULING 2026-08-27, comment "OWNER RULING
            2026-08-27" on bd test_C_libtooling-6uqc. A rail R counts against a
            chained theta T on wire W iff ALL of:
              (1) R is ENTANGLED with W — transitively, ANCESTORS and
                  DESCENDANTS. R may be `cq_template_*`-minted,
                  `cqrt_qram_load_<W>`-minted, OR `cqrt_alloc_<W>`-minted. The
                  alloc-minted inclusion is what plan-v1 got wrong: bd
                  test_C_libtooling-nepx's own leading example is `h0`, an
                  alloc rail (spike §9.2).
              (2) R is NOT DISCHARGED before T — no `cqrt_free(R)` and no `_unc`
                  adjointing R's own producer (an `_unc` whose OUT slot is R) at
                  a position before T.
              (3) R is DEAD AT T IN THE DATA SENSE — NO use of R after T except
                  its own discharge ops (`cqrt_free(R)`, an `_unc` whose
                  adjointed rail is R). A post-T `cqrt_measure_*(R)`, a template
                  call READING R, a cswap/route slot, a copy/tape sink, or a
                  plain-IR use such as `ret`/`store`/`phi` IS a data use, so R is
                  LIVE and EXEMPT. LIVE records are USER DATA: their dephasing is
                  source semantics, so the program is accepted.
              (4) R is not measured BEFORE T (collapse exemption).
              (5) R is not the wire itself.
            The ruling REVERSES plan-v1 on the two pinned accept fixtures
            `lowering_stale_record_{add,alias}_before_theta.ll` BY PRINCIPLE
            (their `%d` is measured after the theta ⇒ live ⇒ exempt), which is
            the acceptance test of this revision — see `--acceptance`.

  `ruled-spine-aware` — `ruled`, with clause 3 additionally NOT counting a
            SPINE-ONLY post-theta use: an `_unc` that merely READS R to
            discharge some other rail, and a compiler-emitted ADJOINT
            `cqrt_ry(R, -θ)` from `EmitInverse`. Reported, not chosen.

  `plan-v1` — the PLAN-OF-RECORD DRAFT predicate this census measured on
            2026-08-27 before the ruling, kept runnable so the two populations
            stay comparable. Records are `cq_template_*` / `cqrt_qram_load_*`
            rails ONLY (alloc rails counted in their own columns, never as
            hits); there is NO deadness clause (a record live into a later
            `cqrt_measure` still counts); and it applies the plan's
            control-discharged-compare carve-out (b).

  Carve-out (b) — "a compare rail that some `_unc` names AND some `cqrt_free`
  frees is Phase 4's to own" — is APPLIED under plan-v1 and NOT applied under
  `ruled`, because the ruling's five clauses do not contain it and plain
  liveness (2) already subsumes it on this corpus. The rails it WOULD have
  removed are counted under `ruled` as `would_exempt_discharged_compare` so the
  choice is visible rather than baked in. Measured today: 0 either way.

================================ WHAT IT MEASURES ==========================
Corpus: every `ir-pass/test/*.ll` fixture that LOWERS (cq-opt exit 0) plus every
`tests/e2e/*.c` slice that lowers. Both are lowered through the real pipeline
(`census_common.lower_ll` / `lower_slice`) into `build/.record_census/`.

Per lowered module, per function, in source-text call order:

  CHAINED THETA.  A `cqrt_ry_<W>(%h, angle)` call is a SOURCE theta iff the
  IMMEDIATELY PRECEDING call is the `cqrt_alloc_<W>` that minted `%h` (a source
  theta is the alloc+ry pair). Any other `cqrt_ry` is CHAINED. Reported
  alongside an ALTERNATE rule — chained iff `%h` is not alloc-minted OR some
  earlier `cqrt_ry` already touched `%h` — so the reader can see whether the
  "immediately preceding" clause is load-bearing. UNCHANGED by the ruling, AND
  SO IS the compiler-emitted-adjoint-Ry filter below (§ "ADJOINT-Ry FILTER"):
  both are preserved verbatim from the pre-ruling revision.

  ENTANGLEMENT.  A directed rail graph. A mint call adds `operand -> result`
  for every rail operand. A non-minting gate adds `read -> write` for every
  (rail read, rail write) pair from `free_pairing_check.classify()`'s effect
  model; `cqrt_cswap`'s two written slots are additionally joined to each other
  (that symbol is modelled `reads=(0,) writes=(1,2)` although a Fredkin
  physically reads all three — the bd 0gwl note in that file). `_unc` calls add
  NO edge: they are discharges, and are recorded as discharge events instead.
    * DESCENDANTS(h) = forward-reachable from h, minus h.
    * ANCESTORS(h)   = backward-reachable from h, minus h.
    * CORRELATED(h)  = undirected-reachable from h, minus h — an UPPER BOUND
      that also catches a sibling (a rail produced from an ancestor of h, hence
      correlated with h without being either an ancestor or a descendant).
      Reported, never a hit, under any predicate.

  LIVE (clause 2) at the theta's call index `i`.  Minted before `i`, no
  `cqrt_free(%r)` before `i`, and no `cq_template_..._unc(%r, …)` naming `%r` in
  its OUT slot before `i`.

  DEAD-IN-THE-DATA-SENSE (clause 3, the two `ruled*` predicates).  No call at index > i names
  `%r` in any slot, and no non-call line after the theta's line mentions `%r` —
  EXCEPT `cqrt_free(%r)` and an `_unc` whose OUT slot is `%r`. Non-call lines are
  scanned RAW over the function's own `define` line range, so `ret i32 %r`,
  `store`, `phi` and an `icmp` on a handle cannot slip through the call parser.

============================ APPROXIMATION DIRECTIONS ======================
Every one of these is reported in the output, never silently absorbed.

  A1  Program order is TEXTUAL order within a function (census_common
      APPROXIMATION 1). `multi_block_fns` counts the functions where that is not
      trivially exact. Sign: unknown; reported, not assumed. NOTE the ruling's
      clause 3 makes this approximation LOAD-BEARING in a way plan-v1's did not:
      "no use AFTER T" is a position question. In a multi-block function a use
      that textually follows T can dynamically precede it and vice versa.
  A2  No interprocedural edges. A rail handed to a Phase-6 clone is opaque.
      Sign for clause 1: UNDER-counts records. Sign for clause 3: a rail passed
      to a clone IS seen as a data use (the call names it), so clause 3 is
      unaffected in the safe direction.
  A3  An `cq_template_..._inv(...)` result is a rail the ABI does not name (bd
      8txa / bd 1739 hole 1). Such mints are classed `inv` and counted in their
      own column, INCLUDED in neither the record totals nor the alloc totals, and
      the count is printed so a nonzero value is impossible to miss.
  A4  Liveness ignores an `_inv`-shaped discharge, since an `_inv` names no rail.
      Sign: OVER-counts live records wherever the spine still emits `_inv`. A3's
      counter bounds it.
  A5  The lit corpus is hand-written IR. A fixture may declare a deliberately
      off-ABI `@cqrt_*` prototype to probe a guard; it parses and counts like any
      other call. It also cannot see TAINT (handles are `i32`), so a `cqrt_ry` on
      a deliberately UNTAINTED rail reads as a chained theta — the one measured
      false positive, `lowering_uncompute_sink_move_past_unwalked_gate.ll`
      (spike §9.3), which `--acceptance` re-checks under both predicates.
  A6  Clause 3's raw-line scan reads every `%token` on a non-call line as a use,
      including a `br`/`phi` BLOCK LABEL. In one LLVM function a block label and
      an SSA value cannot share a name, so on well-formed IR this is exact, not
      an over-count; it is listed because it is an assumption about the grammar.
  A7  `@llvm.dbg.*` calls are not data uses and are skipped by name. The lowered
      corpus is built without `-g`; the counter `dbg_uses_skipped` reports if
      that ever stops being true.

=================================== AMBIGUITY ==============================
ONE ambiguity was found while encoding the ruling, and it is REPORTED rather than
resolved here, because resolving it is an owner decision.

The ruling exempts a rail with any "data use" after T and says "a future free/
_unc is a discharge, not a data use". Read literally that exception covers only
`cqrt_free(R)` and the `_unc` whose adjointed rail IS R. But the LOWERED corpus
also contains two other post-theta mentions of R that no source program asked
for, and that DO NOT EXIST AT THE M-A SLOT the guard will occupy:

  * an `_unc` that READS R while discharging some OTHER rail — emitted by
    `uncompute` (run-line 415) or the Phase-4 teardown (321);
  * the compiler-emitted ADJOINT `cqrt_ry(R, -θ)` — emitted by `EmitInverse`.

M-A sits at `declineStaleRecordOps` (run-line 281). At that point the module has
no `_unc`, no `cqrt_free` and no adjoint Ry at all, so the real guard cannot see
either construct and would find R DEAD. Taking the ruling literally on LOWERED IR
therefore OVER-EXEMPTS relative to the guard being specified. This is the exact
sibling of the §1.5 adjoint-Ry defect (which cost this census an 8.6x error in
the pre-ruling revision), and it is measured here rather than assumed away:
`ruled` = literal, `ruled-spine-aware` = the reading that matches what the guard
can see. The two differ by 5 modules and 8 rails on today's corpus, and the
canonical case is `e2e-slice-io-chained-theta` — the very program spike §9.2
argued should count.

================================== RE-RUN ==================================
    python3 tools/record_census/census_01_guard_population.py \
        --json docs/prd/record-family/census-0.1-guard-population.json

    # the superseded pre-ruling population, same run, same corpus
    python3 tools/record_census/census_01_guard_population.py \
        --predicate plan-v1 \
        --json docs/prd/record-family/census-0.1-guard-population-plan-v1.json

    # the priced ambiguity (spine-only post-theta uses do not exist at the slot)
    python3 tools/record_census/census_01_guard_population.py \
        --predicate ruled-spine-aware \
        --json docs/prd/record-family/census-0.1-guard-population-spine-aware.json

    # the two acceptance tests of the ruling, printed with their witnesses
    python3 tools/record_census/census_01_guard_population.py --acceptance

Prints the totals, the delta vs plan-v1, and the per-module list; `--json` also
writes the full machine-readable record (BOTH predicates, always). First run
lowers the corpus (~100s wall at 8 threads); later runs hit the content-addressed
cache under `build/.record_census/`.
"""

import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import census_common as cc  # noqa: E402

fpc = cc.fpc

RY_RE = re.compile(rf"cqrt_ry_{fpc._W}")
ALLOC_RE = re.compile(rf"cqrt_alloc_{fpc._W}")
MEASURE_RE = re.compile(rf"cqrt_measure_{fpc._W}")
CMP_MINT_RE = re.compile(r"cq_template_(icmp|fcmp)_")

PREDICATES = ("ruled", "ruled-spine-aware", "plan-v1")

# Mint kinds that can be a RECORD under each predicate. `array` (a
# `cqrt_qram_alloc` table) and `tape` (a 7.6 output tape, kept by design) are in
# neither: the ruling names template-minted, qram_load-minted and alloc-minted
# rails, and nothing else. They are counted in their own column so a nonzero
# value is visible.
HIT_KINDS = {"ruled": ("record", "alloc"),
             "ruled-spine-aware": ("record", "alloc"),
             "plan-v1": ("record",)}
DEAD_CLAUSE = ("ruled", "ruled-spine-aware")


class FnModel:
    """The rail graph + event tables for one lowered function."""

    def __init__(self, lf):
        self.lf = lf
        self.calls = lf.calls
        self.call_lines = {c.line for c in self.calls}
        self.mint = {}        # value -> (idx, kind, call)
        self.fwd = {}         # value -> set(value)
        self.bwd = {}
        self.free_at = {}     # value -> [idx]
        self.unc_at = {}      # value -> [idx]   (an `_unc` NAMING the rail)
        self.measure_at = {}  # value -> [idx]
        self.unc_any = set()
        self.inv_mints = 0
        self.dbg_uses_skipped = 0
        # Clause-3 use index, built ONCE (a per-rail rescan of the call stream
        # is quadratic on the libm modules, and a census that is too slow to
        # re-run is a census nobody re-runs).
        self.use_call = {}       # value -> [(idx, line, sym)]  data uses
        self.use_spine = {}      # value -> [(idx, line, sym)]  SPINE-ONLY uses
        self.use_ir = {}         # value -> [(line, head)]  non-call IR uses
        self.ry_is_adjoint = {}  # call idx -> bool
        self._build()
        self._pair_adjoint_ry()
        self._build_use_index()

    def _edge(self, a, b):
        if a == b or a not in self.mint or b not in self.mint:
            return
        self.fwd.setdefault(a, set()).add(b)
        self.bwd.setdefault(b, set()).add(a)

    def _build(self):
        for idx, c in enumerate(self.calls):
            try:
                c.eff = fpc.classify(c.sym)
            except fpc.Unclassified:
                c.eff = None
            k = cc.mint_kind(c)
            if k == "inv":
                self.inv_mints += 1
            if k is not None and c.res is not None:
                self.mint[c.res] = (idx, k, c)
        for idx, c in enumerate(self.calls):
            eff = c.eff
            if c.sym == "cqrt_free" and c.vals:
                self.free_at.setdefault(c.vals[0], []).append(idx)
                continue
            if MEASURE_RE.fullmatch(c.sym) and c.vals:
                self.measure_at.setdefault(c.vals[0], []).append(idx)
                continue
            if eff is None:
                continue
            if eff.role == "unc" and c.vals:
                self.unc_at.setdefault(c.vals[0], []).append(idx)
                self.unc_any.add(c.vals[0])
                continue  # a discharge is not an entangling edge
            if eff.role == "inv":
                continue  # names no rail (A3/A4)
            reads = [c.vals[j] for j in c.read_idx() if j < len(c.vals)]
            if eff.mints in ("rail", "array", "tape") and c.res is not None:
                for r in reads:
                    self._edge(r, c.res)
                continue
            writes = [c.vals[j] for j in eff.writes if j < len(c.vals)]
            for r in reads:
                for w in writes:
                    self._edge(r, w)
            if c.sym == "cqrt_cswap" and len(writes) == 2:
                self._edge(writes[0], writes[1])
                self._edge(writes[1], writes[0])

    def _pair_adjoint_ry(self):
        """The §1.5 forward/adjoint `cqrt_ry` pairing, hoisted into the model so
        BOTH the theta-site filter and the clause-3 use scan can consult it.
        `lowerRotations` emits one `cqrt_ry` per user `@cq_theta`; `uncompute` /
        `EmitInverse` later emits the negated-angle adjoint on the same wire, and
        in lowered IR the two are textually indistinguishable."""
        pending = {}
        for i, c in enumerate(self.calls):
            if not RY_RE.fullmatch(c.sym) or len(c.args) < 2 or not c.vals:
                continue
            st = pending.setdefault(c.vals[0], [])
            if st and fpc.is_negation(st[-1], c.args[1]):
                self.ry_is_adjoint[i] = True
                st.pop()
            else:
                self.ry_is_adjoint[i] = False
                st.append(c.args[1])

    def _build_use_index(self):
        """Clause 3's use tables, in three categories.

        OWN DISCHARGE (never indexed — the ruling's explicit exception):
            `cqrt_free(%r)`, and an `_unc` whose ADJOINTED rail is `%r` (slot 0,
            the DD-3 out slot — this covers `cq_template_*_unc`,
            `cqrt_qram_load_*_unc` AND the `cqrt_qram_store_*[_controlled]_unc`
            pair, which `classify()` models with role 'gate' but which still
            writes slot 0).
        SPINE-ONLY (`use_spine`): an `_unc` that merely READS `%r` to discharge
            some OTHER rail, and a compiler-emitted ADJOINT `cqrt_ry(%r, -θ)`.
            These are DATA USES under the ruling read literally, and they are
            indexed separately because NONE OF THEM EXISTS AT THE M-A SLOT
            (`declineStaleRecordOps`, run-line 281): `_unc` and `cqrt_free` come
            from `uncompute` (415) and the Phase-4 teardown (321), the adjoint Ry
            from `EmitInverse`. See the ambiguity note in the module docstring.
        DATA (`use_call`): everything else — a measure, a template read, a
            cswap/route slot, a copy/tape sink, a clone argument.
        """
        for idx, c in enumerate(self.calls):
            if c.sym.startswith("llvm.dbg"):
                self.dbg_uses_skipped += len(set(c.vals))
                continue
            out0 = c.vals[0] if c.vals else None
            is_unc = c.sym.endswith("_unc")
            for v in dict.fromkeys(c.vals):
                if not v.startswith("%"):
                    continue
                if c.sym == "cqrt_free" and v == out0:
                    continue                      # its own discharge
                if is_unc and v == out0:
                    continue                      # its own producer's adjoint
                if is_unc or (self.ry_is_adjoint.get(idx) and v == out0):
                    self.use_spine.setdefault(v, []).append(
                        (idx, c.line, c.sym))
                    continue
                self.use_call.setdefault(v, []).append((idx, c.line, c.sym))
        for ln, txt in self.lf.raw_lines():
            if ln in self.call_lines:
                continue
            toks = fpc.SSA_NAME_RE.findall(txt)
            if not toks:
                continue
            head = txt.strip().split()
            head = head[0] if head else "?"
            for v in dict.fromkeys(toks):
                self.use_ir.setdefault(v, []).append((ln, head))

    # -- reachability -----------------------------------------------------
    def _reach(self, start, adj):
        seen, stack = set(), [start]
        while stack:
            v = stack.pop()
            for w in adj.get(v, ()):
                if w not in seen:
                    seen.add(w)
                    stack.append(w)
        seen.discard(start)
        return seen

    def descendants(self, h):
        return self._reach(h, self.fwd)

    def ancestors(self, h):
        return self._reach(h, self.bwd)

    def correlated(self, h):
        und = {}
        for a, bs in self.fwd.items():
            for b in bs:
                und.setdefault(a, set()).add(b)
                und.setdefault(b, set()).add(a)
        return self._reach(h, und)

    # -- predicates -------------------------------------------------------
    def live_at(self, r, i):
        """Ruling clause 2 (and plan-v1's only liveness clause): minted before
        the theta, not freed before it, not `_unc`-adjointed before it."""
        m = self.mint.get(r)
        if m is None or m[0] >= i:
            return False
        if any(j < i for j in self.free_at.get(r, ())):
            return False
        if any(j < i for j in self.unc_at.get(r, ())):
            return False
        return True

    def is_discharged_compare(self, r):
        m = self.mint.get(r)
        if m is None or not CMP_MINT_RE.match(m[2].sym):
            return False
        return r in self.unc_any and bool(self.free_at.get(r))

    def measured_before(self, r, i):
        return any(j < i for j in self.measure_at.get(r, ()))

    def data_uses_after(self, r, i, spine_is_use=True):
        """Ruling clause 3. -> [(line, what)] for every DATA use of `%r` strictly
        after the theta at call index `i`.

        A use is EXEMPT (a discharge, not a data use) iff it is `cqrt_free(%r)`
        or an `_unc` whose OUT slot (slot 0, the DD-3 order) is `%r` — i.e. the
        `_unc` that adjoints %r's OWN producer. Everything else counts: a
        `cqrt_measure_*`, a template call reading %r, a cswap/route slot, a
        copy/tape sink, a Phase-6 clone argument, and any plain-IR mention.

        `spine_is_use=False` is the `ruled-spine-aware` reading: it additionally
        drops the SPINE-ONLY uses (an `_unc` READ, a compiler-emitted adjoint Ry)
        on the ground that no such instruction exists yet at the M-A slot.
        Reported as an ambiguity, never silently chosen.
        """
        theta_line = self.calls[i].line
        out = [(ln, "call:" + s)
               for (idx, ln, s) in self.use_call.get(r, ()) if idx > i]
        if spine_is_use:
            out += [(ln, "call:" + s)
                    for (idx, ln, s) in self.use_spine.get(r, ()) if idx > i]
        out += [(ln, "ir:" + h)
                for (ln, h) in self.use_ir.get(r, ()) if ln > theta_line]
        out.sort()
        return out


def _fmt(r, m):
    return f"{r}={m.mint[r][2].sym}" if r in m.mint else r


def analyse_module(path, label, predicate=None):
    """-> per-module record. BOTH predicates are always computed; `predicate` is
    accepted (and ignored beyond validation) so callers can be explicit."""
    if predicate is not None and predicate not in PREDICATES:
        raise SystemExit(f"census: unknown predicate {predicate!r}")
    _, fns = cc.parse_lowered(path)
    out = {"module": label, "thetas": [], "multi_block_fns": 0,
           "inv_mints": 0, "n_fns": len(fns), "dbg_uses_skipped": 0}
    for lf in fns:
        if lf.nblocks > 1:
            out["multi_block_fns"] += 1
        m = FnModel(lf)
        out["inv_mints"] += m.inv_mints
        # ---- ADJOINT-Ry FILTER (measured defect, see the docstring) --------
        # `lowerRotations` emits ONE `cqrt_ry` per user `@cq_theta`; the
        # uncompute spine / `EmitInverse` then emits the NEGATED-angle adjoint
        # `cqrt_ry(h, -theta)` on the same wire. In lowered IR the two are
        # textually indistinguishable, so a naive "cqrt_ry whose handle was not
        # just alloc'd" reads every adjoint as a chained theta. Measured on
        # `lowering_theta_alloc_i32` (ONE `cq_theta`, TWO `cqrt_ry`). M-A runs
        # at the `declineStaleRecordOps` slot, LONG before `uncompute`, so an
        # adjoint Ry is not a site it can ever see. The pairing itself now lives
        # in `FnModel._pair_adjoint_ry` (clause 3's use scan needs it too).
        is_adjoint = m.ry_is_adjoint
        ry_seen = {}
        for i, c in enumerate(m.calls):
            if not RY_RE.fullmatch(c.sym) or not c.vals:
                continue
            h = c.vals[0]
            prev = m.calls[i - 1] if i > 0 else None
            src_primary = (prev is not None and ALLOC_RE.fullmatch(prev.sym)
                           and prev.res == h)
            alloc_minted = (m.mint.get(h, (None, None, None))[1] == "alloc")
            src_alt = alloc_minted and h not in ry_seen
            ry_seen.setdefault(h, i)
            if src_primary:
                continue  # source theta under the primary rule
            anc = m.ancestors(h)
            desc = m.descendants(h)
            corr = m.correlated(h)

            def bucket(vals, pred):
                """-> dict of the ruled/plan-v1 classification for one cone."""
                res = {"hits": [], "record": [], "alloc": [], "other_kind": [],
                       "exempt_measured": [], "exempt_compare": [],
                       "exempt_live_after": [], "not_live": [],
                       "would_exempt_compare": [], "live_after_spine_only": []}
                for r in sorted(vals):
                    if not m.live_at(r, i):          # clause 2
                        res["not_live"].append(r)
                        continue
                    kind = m.mint[r][1]
                    if m.measured_before(r, i):      # clause 4
                        res["exempt_measured"].append(r)
                        continue
                    if pred == "plan-v1" and m.is_discharged_compare(r):
                        res["exempt_compare"].append(r)
                        continue
                    if kind == "record":
                        res["record"].append(_fmt(r, m))
                    elif kind == "alloc":
                        res["alloc"].append(r)
                    else:
                        res["other_kind"].append(f"{r}:{kind}")
                    if kind not in HIT_KINDS[pred]:  # clause 1's mint classes
                        continue
                    if pred in DEAD_CLAUSE:
                        spine = (pred == "ruled")
                        uses = m.data_uses_after(r, i, spine_is_use=spine)
                        if uses:                     # clause 3 -> LIVE, exempt
                            res["exempt_live_after"].append(
                                {"rail": _fmt(r, m),
                                 "uses": [f"{ln}:{w}" for ln, w in uses[:6]],
                                 "n_uses": len(uses)})
                            if spine and not m.data_uses_after(
                                    r, i, spine_is_use=False):
                                res["live_after_spine_only"].append(_fmt(r, m))
                            continue
                        if m.is_discharged_compare(r):
                            res["would_exempt_compare"].append(_fmt(r, m))
                    res["hits"].append(_fmt(r, m))
                return res

            rec = {"fn": lf.name, "line": c.line, "wire": h,
                   "adjoint_paired": bool(is_adjoint.get(i)),
                   "chained_primary": True,
                   "chained_alt": not src_alt,
                   "by_predicate": {}}
            for pred in PREDICATES:
                a = bucket(anc, pred)
                d = bucket(desc, pred)
                cr = bucket(corr, pred)
                rec["by_predicate"][pred] = {
                    "ancestor_hits": a["hits"],
                    "descendant_hits": d["hits"],
                    "ancestor_records": a["record"],
                    "descendant_records": d["record"],
                    "ancestor_alloc_rails": a["alloc"],
                    "descendant_alloc_rails": d["alloc"],
                    "other_kind_rails": sorted(set(a["other_kind"]
                                                   + d["other_kind"])),
                    "correlated_hits": cr["hits"],
                    "correlated_records": cr["record"],
                    "exempt_measured": sorted(set(a["exempt_measured"]
                                                  + d["exempt_measured"])),
                    "exempt_discharged_compare": sorted(
                        set(a["exempt_compare"] + d["exempt_compare"])),
                    "would_exempt_discharged_compare": sorted(
                        set(a["would_exempt_compare"]
                            + d["would_exempt_compare"])),
                    "exempt_live_after": a["exempt_live_after"]
                    + d["exempt_live_after"],
                    "live_after_spine_only": sorted(
                        set(a["live_after_spine_only"]
                            + d["live_after_spine_only"])),
                }
            out["thetas"].append(rec)
        out["dbg_uses_skipped"] += m.dbg_uses_skipped
    # The PRIMARY view drops adjoint-paired Ry sites: they do not exist yet at
    # the slot M-A occupies. `thetas_incl_adjoint` keeps them, as the upper bound.
    out["thetas_incl_adjoint"] = out["thetas"]
    out["thetas"] = [t for t in out["thetas"] if not t["adjoint_paired"]]
    return out


# ---------------------------------------------------------------------------
# Population assembly.
# ---------------------------------------------------------------------------

def populations(mods, pred):
    """-> (inc1, inc3, neither) module lists under `pred`."""
    hits = [m for m in mods if m["thetas"]]
    inc1, inc3, neither = [], [], []
    for m in hits:
        d = any(t["by_predicate"][pred]["descendant_hits"] for t in m["thetas"])
        a = any(t["by_predicate"][pred]["ancestor_hits"] for t in m["thetas"])
        if d:
            inc1.append(m)
        elif a:
            inc3.append(m)
        else:
            neither.append(m)
    return inc1, inc3, neither


def _why(m, pred_from, pred_to):
    """One-line reason a module moved between the two predicates."""
    reasons = []
    for t in m["thetas"]:
        f = t["by_predicate"][pred_from]
        g = t["by_predicate"][pred_to]
        fh = set(f["ancestor_hits"]) | set(f["descendant_hits"])
        gh = set(g["ancestor_hits"]) | set(g["descendant_hits"])
        for r in sorted(fh - gh):
            if pred_to in DEAD_CLAUSE:
                e = next((x for x in g["exempt_live_after"]
                          if x["rail"] == r), None)
                if e:
                    reasons.append(f"{r} LIVE after theta "
                                   f"({', '.join(e['uses'][:2])})")
                else:
                    reasons.append(f"{r} dropped")
            else:
                reasons.append(f"{r} not a plan-v1 record")
        for r in sorted(gh - fh):
            kind = "alloc-minted" if "=cqrt_alloc" in r or "=" not in r \
                else "record"
            reasons.append(f"+{r} now counts ({kind})")
    return "; ".join(dict.fromkeys(reasons)) or "(no rail-level change)"


ACCEPTANCE = [
    ("lit:lowering_stale_record_add_before_theta", False,
     "pinned ACCEPT boundary — %d is measured AFTER the theta ⇒ LIVE ⇒ exempt"),
    ("lit:lowering_stale_record_alias_before_theta", False,
     "pinned ACCEPT boundary (diagonal-alias sibling) — same reason"),
    # FLIPPED True -> False on 2026-08-28 by M-C batch 2b (bd
    # test_C_libtooling-6uqc), DELIBERATELY, and it is this batch's headline. The
    # pin was written to hold bd test_C_libtooling-nepx OPEN: `h0`/`h1` were dead
    # ancestor records, live and entangled with the wire when the S-dagger Ry
    # fired, so the slice HAD to keep reporting an ancestor hit until the fix
    # shipped. Batch 2a removed the two `add`-minted ancestors; batch 2b removes
    # the last one by lowering `q -= off` in place (`cqrt_addc_i32(h0, -3)`), so
    # the slice is now a ONE-RAIL program and there is no ancestor left to hit.
    # A REGRESSION TO `True` HERE MEANS nepx CAME BACK — do not flip it again to
    # make a run green.
    #
    # HOW `False` IS ACTUALLY PRODUCED (2b Rule-13 round, F2 — say it so the pin
    # is not over-read): with both += sites AND the -= site in place, the source
    # Ry(+0.5) and the user's S-dagger Ry(-0.5) now sit on ONE rail with exactly
    # negated angles, so `_pair_adjoint_ry` (blind spot A8) drops the S-dagger
    # site BEFORE any ancestor question is asked — the primary view reports ZERO
    # chained thetas here. The pin's substantive claim is nevertheless
    # independently true: `thetas_incl_adjoint` shows ancestor_hits=[] and
    # descendant_hits=[] for BOTH sites, and the SHIPPED guard is immune (it
    # keys on emitter-recorded user rotations, not on angle pairing). The pin
    # still catches the named regression — an out-of-place sub puts the
    # S-dagger back on a template rail, un-pairs it, and the ancestor HIT
    # returns.
    ("e2e:e2e-slice-control-seq-grover", False,
     "bd nepx FIXED by M-C 2a+2b: every reassignment lowers in place, so the "
     "slice mints no ancestor rail at all ⇒ must be a MISS"),
    ("lit:lowering_uncompute_sink_move_past_unwalked_gate", True,
     "KNOWN ARTEFACT (spike §9.3, blind spot A5): already-lowered fixture whose "
     "rail its own comment declares UNTAINTED, so the real guard would not fire. "
     "Expected to REMAIN a census hit under both predicates — pinned here so it "
     "cannot silently disappear and be mistaken for a real population change"),
]


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--json")
    ap.add_argument("--repo", default=cc.REPO)
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--predicate", choices=PREDICATES, default="ruled",
                    help="headline population (both are always computed)")
    ap.add_argument("--acceptance", action="store_true",
                    help="print the ruling's acceptance tests and exit nonzero "
                         "if any fails")
    args = ap.parse_args(argv)
    pred = args.predicate
    other = "plan-v1" if pred != "plan-v1" else "ruled"

    import concurrent.futures as cfut
    work = []
    for name, path, neg in cc.lit_fixtures(args.repo):
        work.append(("lit:" + name, path, None))
    for s in cc.e2e_slices(args.repo):
        if s["kind"] in ("single", "multi"):
            work.append(("e2e:" + s["name"], None, s))

    def go(item):
        label, path, sl = item
        if path is not None:
            rc, out, _ = cc.lower_ll(path, args.repo)
        else:
            rc, out, _ = cc.lower_slice(sl, args.repo)
        if rc != 0 or out is None:
            return None
        return analyse_module(out, label)

    with cfut.ThreadPoolExecutor(max_workers=args.jobs) as ex:
        mods = [m for m in ex.map(go, work) if m is not None]

    hits = [m for m in mods if m["thetas"]]
    hits_ub = [m for m in mods if m["thetas_incl_adjoint"]]
    by_pred = {p: populations(mods, p) for p in PREDICATES}
    inc1, inc3, neither = by_pred[pred]
    o1, o3, _ = by_pred[other]

    def names(lst):
        return sorted(m["module"] for m in lst)

    alloc_only = [m for m in neither
                  if any(t["by_predicate"][pred]["ancestor_alloc_rails"]
                         or t["by_predicate"][pred]["descendant_alloc_rails"]
                         for t in m["thetas"])]
    corr_only = [m for m in neither
                 if any(t["by_predicate"][pred]["correlated_hits"]
                        for t in m["thetas"])]

    def agg(p, key):
        return sum(len(t["by_predicate"][p][key]) for m in mods
                   for t in m["thetas"])

    n_theta = sum(len(m["thetas"]) for m in mods)
    declined_pred = set(names(inc1)) | set(names(inc3))
    declined_other = set(names(o1)) | set(names(o3))
    dropped = sorted(declined_other - declined_pred)
    added = sorted(declined_pred - declined_other)
    by_name = {m["module"]: m for m in mods}

    report = {
        "predicate": pred,
        "ruling": "OWNER RULING 2026-08-27, bd test_C_libtooling-6uqc",
        "corpus": {"modules_lowered": len(mods),
                   "lit": sum(1 for m in mods if m["module"].startswith("lit:")),
                   "e2e": sum(1 for m in mods if m["module"].startswith("e2e:"))},
        "chained_thetas": n_theta,
        "chained_thetas_incl_adjoint_ry": sum(len(m["thetas_incl_adjoint"])
                                              for m in mods),
        "modules_with_chained_theta": len(hits),
        "modules_with_chained_theta_incl_adjoint_ry": len(hits_ub),
        "inc1_newly_declined": names(inc1),
        "inc3_additional": names(inc3),
        "chained_theta_no_record": names(neither),
        "chained_theta_alloc_ancestor_only": names(alloc_only),
        "chained_theta_correlated_only": names(corr_only),
        "exempt_measured_hits": agg(pred, "exempt_measured"),
        "exempt_discharged_compare_hits": agg(pred, "exempt_discharged_compare"),
        "would_exempt_discharged_compare_hits":
            agg(pred, "would_exempt_discharged_compare"),
        "exempt_live_after_hits": agg(pred, "exempt_live_after"),
        "ambiguity_live_after_spine_only_rails":
            agg("ruled", "live_after_spine_only"),
        "ambiguity_spine_aware_extra_modules": sorted(
            (set(names(by_pred["ruled-spine-aware"][0]))
             | set(names(by_pred["ruled-spine-aware"][1])))
            - (set(names(by_pred["ruled"][0]))
               | set(names(by_pred["ruled"][1])))),
        "other_kind_rails_seen": agg(pred, "other_kind_rails"),
        "multi_block_fns": sum(m["multi_block_fns"] for m in mods),
        "total_fns": sum(m["n_fns"] for m in mods),
        "inv_mints_total": sum(m["inv_mints"] for m in mods),
        "dbg_uses_skipped": sum(m["dbg_uses_skipped"] for m in mods),
        "chained_rule_disagreements": sorted(
            m["module"] for m in mods
            if any(t["chained_primary"] != t["chained_alt"]
                   for t in m["thetas"])),
        f"delta_vs_{other}": {
            "inc1": names(by_pred[other][0]),
            "inc3": names(by_pred[other][1]),
            "dropped_out": [{"module": n, "reason": _why(by_name[n], other, pred)}
                            for n in dropped],
            "newly_in": [{"module": n, "reason": _why(by_name[n], other, pred)}
                         for n in added],
        },
        "modules": hits,
    }

    print(f"predicate: {pred}   (both computed; delta below is vs {other})")
    print(f"corpus: {report['corpus']['modules_lowered']} lowered modules "
          f"({report['corpus']['lit']} lit, {report['corpus']['e2e']} e2e)")
    print(f"chained thetas: {n_theta} in {len(hits)} modules "
          f"(upper bound incl. compiler-emitted adjoint Ry: "
          f"{report['chained_thetas_incl_adjoint_ry']} in {len(hits_ub)})")
    print(f"Inc 1 (dead-DESCENDANT half) newly declines : {len(inc1)} modules")
    print(f"Inc 3 (dead-ANCESTOR half) adds             : {len(inc3)} modules")
    print(f"chained theta, no counting record           : {len(neither)} modules "
          f"({len(alloc_only)} have a live ALLOC-minted neighbour; "
          f"{len(corr_only)} have a live CORRELATED (sibling) record)")
    print(f"exemption hits: measured={report['exempt_measured_hits']} "
          f"discharged-compare={report['exempt_discharged_compare_hits']} "
          f"(would-be={report['would_exempt_discharged_compare_hits']}) "
          f"LIVE-after-theta={report['exempt_live_after_hits']}")
    sa = report["ambiguity_spine_aware_extra_modules"]
    print(f"AMBIGUITY (spine-only post-theta uses — an `_unc` READ or a "
          f"compiler-emitted adjoint Ry, neither of which EXISTS at the M-A "
          f"slot): {report['ambiguity_live_after_spine_only_rails']} rails, "
          f"{len(sa)} extra modules under `ruled-spine-aware`")
    for n in sa:
        print(f"      spine-aware-only: {n}")
    print(f"approximation counters: multi_block_fns="
          f"{report['multi_block_fns']}/{report['total_fns']} "
          f"inv_mints={report['inv_mints_total']} "
          f"dbg_uses_skipped={report['dbg_uses_skipped']} "
          f"other_kind_rails={report['other_kind_rails_seen']} "
          f"chained-rule disagreements="
          f"{len(report['chained_rule_disagreements'])}")
    print()
    print(f"DELTA vs {other}: {len(declined_other)} -> {len(declined_pred)} "
          f"declining modules  ({len(dropped)} dropped out, {len(added)} new)")
    for n in dropped:
        print(f"  - {n}\n        {_why(by_name[n], other, pred)}")
    for n in added:
        print(f"  + {n}\n        {_why(by_name[n], other, pred)}")
    print()
    for key, lst in (("INC1", inc1), ("INC3", inc3)):
        for m in sorted(lst, key=lambda x: x["module"]):
            for t in m["thetas"]:
                b = t["by_predicate"][pred]
                if not (b["descendant_hits"] or b["ancestor_hits"]):
                    continue
                print(f"  {key} {m['module']} fn={t['fn']} line={t['line']} "
                      f"wire={t['wire']}")
                if b["descendant_hits"]:
                    print(f"        desc: {', '.join(b['descendant_hits'])}")
                if b["ancestor_hits"]:
                    print(f"        anc : {', '.join(b['ancestor_hits'])}")
                if b["exempt_live_after"]:
                    print(f"        exempt (LIVE after theta): "
                          f"{', '.join(e['rail'] for e in b['exempt_live_after'])}")

    rc = 0
    if args.acceptance:
        print("\nACCEPTANCE TESTS (ruling 2026-08-27):")
        for mod, want_hit, why in ACCEPTANCE:
            m = by_name.get(mod)
            if m is None:
                print(f"  MISSING {mod} — not in the lowered corpus")
                rc = 1
                continue
            got = any(t["by_predicate"]["ruled"]["ancestor_hits"]
                      or t["by_predicate"]["ruled"]["descendant_hits"]
                      for t in m["thetas"])
            ok = (got == want_hit)
            rc |= (0 if ok else 1)
            print(f"  {'PASS' if ok else 'FAIL'} {mod}: "
                  f"ruled={'HIT' if got else 'exempt'} "
                  f"(want {'HIT' if want_hit else 'exempt'})  — {why}")
            for t in m["thetas"]:
                b = t["by_predicate"]["ruled"]
                p = t["by_predicate"]["plan-v1"]
                print(f"       line {t['line']} wire={t['wire']}  "
                      f"plan-v1 anc={p['ancestor_hits']} desc={p['descendant_hits']}"
                      f" | ruled anc={b['ancestor_hits']} desc={b['descendant_hits']}")
                for e in b["exempt_live_after"]:
                    print(f"         exempt {e['rail']}: used at "
                          f"{', '.join(e['uses'])}")

    if args.json:
        with open(args.json, "w") as f:
            json.dump(report, f, indent=1, sort_keys=True)
        print(f"\nwrote {args.json}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
