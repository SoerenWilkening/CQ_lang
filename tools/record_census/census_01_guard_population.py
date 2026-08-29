#!/usr/bin/env python3
"""census_01_guard_population.py — Inc-0 census 0.1: how many currently-GREEN
modules would the M-A guard (`warnLiveRecordRotations`) newly REPORT?

⚠ THE GUARD WARNS, IT DOES NOT DECLINE (owner ruling 2026-08-29, bd
test_C_libtooling-lyyf, shipped as M-A Increment 7b). Everything below was
written while it was a `DS_Error`, and the ANALYSIS it models is unchanged — but
read every "decline" in this file as "report": `opt` now prints `warning: …` and
exits ZERO, the module lowers, and the record is left allocated. Two consequences
for this census specifically, both real: the CORPUS now contains the modules the
guard fires on (they emit lowered IR, where before they emitted none), and
`--validate-guard` reads the VERDICT off stderr instead of the exit code — see
the VALIDATION section, which also explains why that made its confusion table
strictly stronger.

Settles Risk 3 of the record-family plan of record (bd test_C_libtooling-6uqc).
M-A is the permanent net that ships first: it reports a CHAINED `cq_theta`
whose wire carries LIVE UNOWNED RECORDS. Inc 1 ships the DESCENDANT half; Inc 3
adds the ANCESTOR half. This file measures both halves separately so the two
increments can be sized independently, and so "Inc 1 is shippable standalone" is
a measurement rather than a hope.

2026-08-28 REVISION — THE SHIPPED PREDICATE AND THE A8 UPGRADE (bd rtg5)
========================================================================
M-A SHIPPED (Inc 1 `50b1b7e`, Inc 3 `b4e329b`). This file was written to SIZE
that guard before it existed; from b4e329b on, its job is to MODEL IT. Two
divergences were open and both are now closed here:

  1. CLAUSE 3 was the RETIRED "mentioned later" reading. The shipped guard
     requires an OBSERVING SINK reached by lineage (owner rulings F1+F2,
     2026-08-28). The new default predicate `shipped-b4e329b` mirrors
     `warnLiveRecordRotations` clause by clause — record set, discharge,
     observing-sink walk, measure, wire, and the clause-6 existence skip — in
     `shipped_guard_model.py`. `ruled` / `ruled-spine-aware` / `plan-v1` remain
     computable for the DELTA TABLE ONLY; none of them is the compiler's
     predicate any more.
  2. BLIND SPOT A8 (SPIKE §1.4): chained-theta SITES came from the LOWERED view,
     where a user's chained `cq_theta` and the spine's negated-angle adjoint
     `cqrt_ry` are textually identical, and `_pair_adjoint_ry` guessed between
     them by angle. It guessed WRONG IN BOTH DIRECTIONS once M-C put both
     rotations on ONE rail (it dropped `seq-grover`'s S-dagger and could promote a
     spine adjoint to a phantom site). Sites now come from the PRE-LOWERING
     `@cq_theta` view — `--site-source source`, the DEFAULT — which cannot
     confuse the two because the adjoint does not exist yet at that stage. The
     old classifier is kept behind `--site-source lowered` for the delta.

SITE SOURCE (`--site-source {source,lowered}`; BOTH always computed)
--------------------------------------------------------------------
  `source` (DEFAULT) — enumerate every `@cq_theta_*` call in the PRE-LOWERING
      module (the lit fixture as committed, or an e2e slice's stage-1 IR), in
      textual order per function, with a CHAINED flag computed the way the pass
      computes it (`RotationLowering.cpp`: `Chained = taint.Tainted.count(arg0)`;
      here `source_ir.FnAnalysis`'s forward taint, whose source is `@cq_theta`
      alone, Rule 3). Then MAP those onto the lowered function's `cqrt_ry_*`
      calls in program order by GREEDY ANGLE MATCHING: the k-th user theta takes
      the next unmatched `cqrt_ry` whose angle operand equals its own. Every
      `cqrt_ry` left unmatched is COMPILER-EMITTED (a spine adjoint) and is not a
      site. The SITES are the mapped rotations whose user theta was CHAINED —
      which is exactly `taint.UserChainedRotations`, the shipped guard's own
      site set, recovered without the emitter's help.
      MISMATCHES ARE LOUD, NEVER SILENT: a user theta whose angle is not found
      among the remaining `cqrt_ry`, a function that holds user thetas but does
      not appear in the lowered module, or a lowered function with fewer
      rotations than user thetas, all flag the module `site_mapping_failed`. A
      flagged module FALLS BACK to the lowered view (the over-counting direction)
      and is listed in the output and the JSON.
  `lowered` — the pre-A8 rule, preserved verbatim: a `cqrt_ry` is a SOURCE theta
      iff the immediately preceding call is the `cqrt_alloc` that minted its
      handle, and `_pair_adjoint_ry`'s per-handle angle stack drops what it reads
      as a compiler adjoint. Kept ONLY so the A8 delta is a measurement.

  KNOWN RESIDUAL OF THE MAPPING (direction: UNDER-counts sites). A stage that
  DUPLICATES a theta before `lowerRotations` — `unrollConstTripLoops`, the
  PredMux fixpoint — yields more `cqrt_ry` than there are user thetas, all with
  the same angle; greedy matching binds the first ones and reads the copies as
  adjoints. No count mismatch is raised, because there is no missing angle. The
  `--validate-guard` confusion table below is the check that would catch it:
  a duplicated site the census drops shows up as a guard decline the census
  cannot explain.

FOUR PREDICATES, ALL ALWAYS COMPUTED
=====================================
`--predicate {shipped-b4e329b,ruled,ruled-spine-aware,plan-v1}` selects the
HEADLINE population. All four are computed on every run from the same parse of
the same lowered module, so the delta table this script prints is a difference
between readings of ONE measurement, not between runs.

  `shipped-b4e329b` (DEFAULT) — the guard AS SHIPPED at commit b4e329b. Modelled
            in `shipped_guard_model.py`, which mirrors
            `ir-pass/src/RotationLowering.cpp` clause by clause and carries its
            own divergence counters (`SpineOps` invisibility, the per-argument
            clone hop). Position is a REAL CFG question here — dominators plus
            forward reachability, matching `WireWalk.h`'s `provablyBefore` —
            not textual order, because clauses 2/3/4/6 are all position tests
            and 822 of 1363 functions in this corpus have more than one block.

  `ruled`   — OWNER RULING 2026-08-27, comment "OWNER RULING
            2026-08-27" on bd test_C_libtooling-6uqc. **RETIRED as a model of
            the compiler on 2026-08-28** — its clause 3 is the "mentioned later"
            reading the F1 ruling replaced. Kept for the delta table. A rail R
            counts against a
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

=========================== VALIDATION (`--validate-guard`) ================
The census's verdict is only worth what it agrees with. `--validate-guard`
compares, for every module in the corpus that holds at least one chained-theta
site, the census verdict (HIT = "the guard fires here") against the module's
ACTUAL verdict under `build/ir-pass/cq-opt`.

⚠ THE ACTUAL VERDICT IS READ FROM STDERR SINCE M-A INCREMENT 7b (owner ruling
2026-08-29, bd test_C_libtooling-lyyf). The guard now emits a `DS_Warning` and
`opt` exits ZERO whether or not it fired, so the EXIT CODE no longer carries the
answer — this comparison used to key on `rc != 0` and, read literally after the
severity change, reported all 25 in-tree guard fixtures as UNEXPLAINED
disagreements (measured). The verdict is now "did `kMsgLiveRecord` appear on
stderr", which is the same fact the old exit code stood proxy for.

THE CHANGE MADE THE TABLE STRICTLY STRONGER, and that is worth stating because
the old shape had a documented blind half. Before 7b the corpus was the set of
modules that LOWER, so a module the guard DECLINED emitted no lowered IR and was
not in the corpus at all: **every census HIT was a disagreement by construction**
and the guard's own fixtures were reported separately as "not modellable". Now
every module lowers, so both confusion cells are observable:

    HIT  / warns   agreement — the census predicted the report and got it
    HIT  / silent  DISAGREEMENT — the census over-predicts (the old, and still
                   the only explained, direction)
    MISS / warns   DISAGREEMENT — the census UNDER-predicts. This cell was
                   structurally unreachable before 7b and is the one worth
                   watching: it means the shipped guard fires where the model
                   says it should not.
    MISS / silent  agreement

================================== RE-RUN ==================================
    # the live population under the SHIPPED predicate (default) + the deltas
    python3 tools/record_census/census_01_guard_population.py \
        --json docs/prd/record-family/census-0.1-guard-population-shipped-b4e329b.json

    # the A8 site-source delta and the predicate delta, as their own artifact
    python3 tools/record_census/census_01_guard_population.py \
        --delta-json docs/prd/record-family/census-0.1-site-source-delta.json

    # the census verdict vs the real `cq-opt` verdict, per module
    python3 tools/record_census/census_01_guard_population.py --validate-guard

    # the superseded predicates, same run, same corpus (delta table only)
    python3 tools/record_census/census_01_guard_population.py --predicate ruled
    python3 tools/record_census/census_01_guard_population.py --predicate plan-v1
    python3 tools/record_census/census_01_guard_population.py \
        --predicate ruled-spine-aware

    # the pinned acceptance tests, printed with their witnesses (exit nonzero on
    # failure)
    python3 tools/record_census/census_01_guard_population.py --acceptance

    # the pre-lowering cross-check (unchanged: it deliberately asks the census
    # for its LOWERED site view, so the two models stay independent)
    python3 tools/record_census/source_ir.py --validate

Prints the totals, the deltas, and the per-module list; `--json` also writes the
full machine-readable record (ALL predicates and BOTH site sources, always).
First run lowers the corpus (~100s wall at 8 threads); later runs hit the
content-addressed cache under `build/.record_census/`.
"""

import argparse
import json
import os
import re
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import census_common as cc  # noqa: E402
import shipped_guard_model as sgm  # noqa: E402
import source_ir as src  # noqa: E402

fpc = cc.fpc

RY_RE = re.compile(rf"cqrt_ry_{fpc._W}")
ALLOC_RE = re.compile(rf"cqrt_alloc_{fpc._W}")
MEASURE_RE = re.compile(rf"cqrt_measure_{fpc._W}")
CMP_MINT_RE = re.compile(r"cq_template_(icmp|fcmp)_")

SHIPPED = "shipped-b4e329b"
PREDICATES = (SHIPPED, "ruled", "ruled-spine-aware", "plan-v1")
LEGACY_PREDICATES = ("ruled", "ruled-spine-aware", "plan-v1")
SITE_SOURCES = ("source", "lowered")

# Mint kinds that can be a RECORD under each predicate. `array` (a
# `cqrt_qram_alloc` table) and `tape` (a 7.6 output tape, kept by design) are in
# neither: the ruling names template-minted, qram_load-minted and alloc-minted
# rails, and nothing else. They are counted in their own column so a nonzero
# value is visible.
HIT_KINDS = {"ruled": ("record", "alloc"),
             "ruled-spine-aware": ("record", "alloc"),
             "plan-v1": ("record",)}
DEAD_CLAUSE = ("ruled", "ruled-spine-aware")


# ---------------------------------------------------------------------------
# A8 UPGRADE — chained-theta SITES from the PRE-LOWERING `@cq_theta` view.
#
# The lowered view cannot tell a user's chained `cq_theta` from the spine's
# negated-angle adjoint (both are `cqrt_ry_<W>(%h, angle)`), and the angle-stack
# heuristic it used instead is wrong in BOTH directions once M-C keeps a
# reassignment on one rail (SPIKE §1.4 blind spot A8). The pre-lowering view has
# no adjoint to confuse: `lowerRotations` emits exactly one `cqrt_ry` per user
# `@cq_theta`, in the same order, with the SAME angle Value — so an in-order
# greedy match on the angle recovers the emitter's own bookkeeping.
# ---------------------------------------------------------------------------

def angle_key(arg):
    """A comparable key for a normalised `<ty> <value>` angle operand.

    NUMERIC where it can be, textual otherwise, because the two views print the
    same LLVM constant differently: a hand-written fixture may spell `double 0.5`
    while `cq-opt`'s printer emits `double 5.000000e-01`, and both must key the
    same. An SSA-named angle (`double %g`) keys on the name, which is preserved
    verbatim by the lowering (the pass copies the Value, it does not rebuild it).
    """
    toks = arg.split()
    if len(toks) < 2:
        return ("?", arg)
    ty, v = toks[0], toks[-1]
    lv = v.lower()
    if lv.startswith("0x"):
        # `0xK`/`0xL`/`0xM`/`0xH` are the extended-precision spellings; compare
        # them textually. A bare `0x…` is an IEEE double bit pattern.
        if len(lv) > 2 and lv[2] in "klmh":
            return (ty, lv)
        try:
            return (ty, struct.unpack(">d", bytes.fromhex(lv[2:]))[0])
        except Exception:
            return (ty, lv)
    try:
        return (ty, float(v))
    except ValueError:
        return (ty, v)


def _call_args(text):
    """Normalised argument list of a call INSTRUCTION LINE, via fpc's parser."""
    body = text if text.startswith(" ") else " " + text
    m = fpc.CALL_RE.match(body)
    if not m:
        return None
    open_at = body.index("(", m.end() - 1)
    j = fpc.balanced(body, open_at)
    return [fpc.norm_arg(a) for a in fpc.split_args(body[open_at + 1:j])]


def user_thetas(pre_path):
    """-> {fn_name: [(ordinal, chained, angle_key, line)]} over PRE-LOWERING IR.

    CHAINED is the pass's own test (`RotationLowering.cpp`:
    `Chained = taint.Tainted.count(arg0)`), modelled by `source_ir.FnAnalysis`'s
    forward taint whose sole source is `@cq_theta` (Rule 3). A theta with a
    classical arg-0 is a SOURCE theta and mints its wire, so it can carry no
    record and is not a guard site — but it IS kept in the ordinal list, because
    it consumes a `cqrt_ry` and the mapping is positional.
    """
    out = {}
    for name, instrs in src.parse_functions(pre_path).items():
        fa = src.FnAnalysis(name, instrs)
        rows = []
        for ins in instrs:
            if not (ins.callee and src.THETA_RE.match(ins.callee)):
                continue
            args = _call_args(ins.text)
            if not args or len(args) < 2:
                rows.append((len(rows), False, None, ins.line))
                continue
            chained = bool(ins.operands) and ins.operands[0] in fa.tainted
            rows.append((len(rows), chained, angle_key(args[1]), ins.line))
        if rows:
            out[name] = rows
    return out


def map_theta_sites(pre_rows, calls):
    """Map user thetas onto a lowered function's `cqrt_ry` calls.

    GREEDY, IN ORDER: the k-th user theta takes the next still-unmatched
    `cqrt_ry` whose angle key equals its own. -> (mapped, failures) where
    `mapped` is {ry call index: (ordinal, chained, source_line)}.
    """
    ry = [(i, c) for i, c in enumerate(calls)
          if RY_RE.fullmatch(c.sym) and len(c.args) >= 2]
    used, mapped, failures = set(), {}, []
    for ordinal, chained, akey, line in pre_rows:
        if akey is None:
            failures.append(f"theta#{ordinal}@{line}: unparsable angle")
            continue
        hit = None
        for pos, (idx, c) in enumerate(ry):
            if pos in used:
                continue
            if angle_key(c.args[1]) == akey:
                hit = pos
                break
        if hit is None:
            failures.append(f"theta#{ordinal}@{line}: angle {akey!r} not found "
                            f"among {len(ry) - len(used)} unmatched cqrt_ry")
            continue
        used.add(hit)
        mapped[ry[hit][0]] = (ordinal, chained, line)
    return mapped, failures


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


def analyse_module(path, label, predicate=None, pre_path=None,
                   site_source="lowered"):
    """-> per-module record. ALL predicates and BOTH site sources are always
    computed; `predicate` is accepted (and ignored beyond validation) so callers
    can be explicit, and `site_source` selects which view fills `thetas`.

    `site_source` DEFAULTS TO `lowered` so that `source_ir.py --validate` keeps
    asking this census for its own independent (lowered-IR) site verdict — that
    cross-check is only worth running while the two models stay independent.
    `main()` passes `source`, the post-A8 default.
    """
    if predicate is not None and predicate not in PREDICATES:
        raise SystemExit(f"census: unknown predicate {predicate!r}")
    if site_source not in SITE_SOURCES:
        raise SystemExit(f"census: unknown site source {site_source!r}")
    _, fns = cc.parse_lowered(path)
    ir_by_fn = src.parse_functions(path)  # NON-call lines, for the shipped model
    pre_by_fn = user_thetas(pre_path) if pre_path else None
    out = {"module": label, "sites": [], "multi_block_fns": 0,
           "inv_mints": 0, "n_fns": len(fns), "dbg_uses_skipped": 0,
           "site_mapping_failed": [], "pre_lowering_view": pre_path is not None,
           "spine_indistinguishable_hops": 0, "clone_hops_unchecked": 0,
           "unreachable_uses_skipped": 0}
    for lf in fns:
        if lf.nblocks > 1:
            out["multi_block_fns"] += 1
        m = FnModel(lf)
        sf = sgm.ShippedFn(lf, ir_by_fn.get(lf.name))
        mapped = {}
        if pre_by_fn is not None:
            rows = pre_by_fn.get(lf.name, [])
            mapped, failures = map_theta_sites(rows, m.calls)
            for f in failures:
                out["site_mapping_failed"].append(f"{lf.name}: {f}")
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
            # ---- SITE MEMBERSHIP, in the two views (A8 upgrade) -------------
            # LOWERED: the pre-A8 rule, verbatim — not a source theta under the
            # "immediately preceding alloc" test, and not angle-paired as a
            # compiler adjoint.
            in_low_all = not src_primary
            in_low = in_low_all and not is_adjoint.get(i)
            # SOURCE: this `cqrt_ry` was matched to a user `@cq_theta` whose
            # arg-0 was tainted. That IS `taint.UserChainedRotations`.
            mp = mapped.get(i)
            in_src = bool(mp) and bool(mp[1])
            if not (in_low_all or in_src):
                continue
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
                   "chained_primary": not src_primary,
                   "chained_alt": not src_alt,
                   "in_lowered_view": in_low,
                   "in_lowered_view_incl_adjoint": in_low_all,
                   "in_source_view": in_src,
                   "source_theta_ordinal": mp[0] if mp else None,
                   "source_theta_line": mp[2] if mp else None,
                   "by_predicate": {}}
            # ---- the SHIPPED predicate (the default) ------------------------
            v = sf.verdict(i)
            hits = v["hits"]
            rec["by_predicate"][SHIPPED] = {
                "ancestor_hits": [x["rail"] for x in hits
                                  if x["origin"] in ("ancestor", "sibling")],
                "descendant_hits": [x["rail"] for x in hits
                                    if x["origin"] == "descendant"],
                "hits": [x["rail"] for x in hits],
                "hit_origins": {x["rail"]: x["origin"] for x in hits},
                "records": v["records"],
                "skipped_clause6": v["skipped_clause6"],
                "exempt": v["exempt"],
                # legacy key names, so the shared report code can read either
                "ancestor_records": [], "descendant_records": [],
                "ancestor_alloc_rails": [], "descendant_alloc_rails": [],
                "other_kind_rails": [], "correlated_hits": [],
                "correlated_records": [],
                "exempt_measured": [e["rail"] for e in v["exempt"]
                                    if e["clause"] == 4],
                "exempt_discharged_compare": [],
                "would_exempt_discharged_compare": [],
                "exempt_live_after": [{"rail": e["rail"],
                                       "uses": [e["witness"]], "n_uses": 1}
                                      for e in v["exempt"] if e["clause"] == 3],
                "live_after_spine_only": [],
            }
            for pred in LEGACY_PREDICATES:
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
            out["sites"].append(rec)
        out["dbg_uses_skipped"] += m.dbg_uses_skipped
        out["spine_indistinguishable_hops"] += sf.spine_indistinguishable_hops
        out["clone_hops_unchecked"] += sf.clone_hops_unchecked
        out["unreachable_uses_skipped"] += sf.unreachable_uses_skipped
    if pre_by_fn is not None:
        lowered_names = {lf.name for lf in fns}
        for name, rows in pre_by_fn.items():
            if name not in lowered_names and any(r[1] for r in rows):
                out["site_mapping_failed"].append(
                    f"{name}: holds {sum(1 for r in rows if r[1])} chained user "
                    f"theta(s) but no lowered function of that name")
    # The three views. `thetas_incl_adjoint` is the pre-A8 upper bound; the two
    # named views are the A8 delta; `thetas` is the one the headline uses.
    out["thetas_incl_adjoint"] = [t for t in out["sites"]
                                  if t["in_lowered_view_incl_adjoint"]]
    out["thetas_lowered"] = [t for t in out["sites"] if t["in_lowered_view"]]
    out["thetas_source"] = [t for t in out["sites"] if t["in_source_view"]]
    # A module whose mapping FAILED falls back to the lowered view — the
    # OVER-counting direction — and stays on the loud list either way.
    fallback = bool(out["site_mapping_failed"]) or pre_by_fn is None
    out["site_source_fallback"] = fallback and site_source == "source"
    if site_source == "source" and not fallback:
        out["thetas"] = out["thetas_source"]
    else:
        out["thetas"] = out["thetas_lowered"]
    return out


# ---------------------------------------------------------------------------
# Population assembly.
# ---------------------------------------------------------------------------


def populations(mods, pred, view="thetas"):
    """-> (inc1, inc3, neither) module lists under `pred`, over site view `view`.

    The Inc-1 / Inc-3 split is HISTORICAL — it sized two increments that have
    both shipped. Under `shipped-b4e329b` the guard is ONE guard, so read the
    split as provenance (which closure reached the rail) and the UNION as the
    population.
    """
    hits = [m for m in mods if m[view]]
    inc1, inc3, neither = [], [], []
    for m in hits:
        d = any(t["by_predicate"][pred]["descendant_hits"] for t in m[view])
        a = any(t["by_predicate"][pred]["ancestor_hits"] for t in m[view])
        if d:
            inc1.append(m)
        elif a:
            inc3.append(m)
        else:
            neither.append(m)
    return inc1, inc3, neither


def module_hit(m, pred, view="thetas"):
    """Would the guard decline this module, under `pred` over site view `view`?"""
    return any(t["by_predicate"][pred]["ancestor_hits"]
               or t["by_predicate"][pred]["descendant_hits"]
               for t in m[view])


def _why(m, pred_from, pred_to, view="thetas"):
    """One-line reason a module moved between the two predicates."""
    reasons = []
    for t in m[view]:
        f = t["by_predicate"][pred_from]
        g = t["by_predicate"][pred_to]
        fh = set(f["ancestor_hits"]) | set(f["descendant_hits"])
        gh = set(g["ancestor_hits"]) | set(g["descendant_hits"])
        for r in sorted(fh - gh):
            if pred_to == SHIPPED:
                e = next((x for x in g["exempt"] if x["rail"] == r), None)
                if e:
                    reasons.append(f"{r} exempt by clause {e['clause']} "
                                   f"({e['witness']})")
                elif r in g["skipped_clause6"]:
                    reasons.append(f"{r} minted AFTER the gate (clause 6)")
                elif r not in g["records"]:
                    reasons.append(f"{r} not in the shipped record set")
                else:
                    reasons.append(f"{r} dropped")
            elif pred_to in DEAD_CLAUSE:
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


def _why_sites(m):
    """One-line reason a module's SITE SET differs between the two views."""
    bits = []
    for t in m["sites"]:
        if t["in_source_view"] and not t["in_lowered_view"]:
            why = ("angle-paired as a compiler adjoint (A8)"
                   if t["adjoint_paired"] else
                   "read as a source theta by the alloc-adjacency rule")
            bits.append(f"+line {t['line']} wire={t['wire']}: user "
                        f"@cq_theta#{t['source_theta_ordinal']} at source line "
                        f"{t['source_theta_line']}, {why} in the lowered view")
        elif t["in_lowered_view"] and not t["in_source_view"]:
            why = ("mapped to a SOURCE (unchained) user theta"
                   if t["source_theta_ordinal"] is not None else
                   "matched NO user @cq_theta — compiler-emitted or hand-written")
            bits.append(f"-line {t['line']} wire={t['wire']}: {why}")
    return "; ".join(bits) or "(no site-level change)"


# ---------------------------------------------------------------------------
# ACCEPTANCE — the pins. `--acceptance` exits non-zero if any fails.
#
# These are not a test suite; they are the four claims this census is not
# allowed to lose. Each names the regression it catches.
# ---------------------------------------------------------------------------

ACCEPTANCE = [
    ("lit:lowering_stale_record_add_before_theta",
     {"sites_source": 1, "shipped_hit": False},
     "pinned ACCEPT boundary (owner ruling 2026-08-27) — the record %h_op is "
     "measured AFTER the gate, so clause 3's sink walk reaches a "
     "`cqrt_measure_i32` and the rail is LIVE user data. A HIT here means the "
     "observing-sink walk stopped seeing a direct measurement"),
    ("lit:lowering_stale_record_alias_before_theta",
     {"sites_source": 1, "shipped_hit": False},
     "the diagonal-alias sibling of the same boundary, one hop removed"),
    # THE A8 PIN, AND IT IS THE HEADLINE OF THIS REVISION.
    #
    # Before the upgrade this pin was VACUOUS and said so in its own comment:
    # `_pair_adjoint_ry` dropped the S-dagger site (M-C 2b had put the source Ry
    # and the user's S-dagger on ONE rail with exactly negated angles), so the
    # census reported ZERO chained thetas here and "MISS" was a statement about
    # a site it could not see. It now asserts BOTH halves:
    #   * the SITE IS FOUND in the pre-lowering view (`sites_source` >= 1) — the
    #     user's `a = cq_theta(a, -0.5)` at slice_control_seq_grover.c;
    #   * and it is a MISS — every record on that wire is discharged before the
    #     gate (the region's compare is `_unc`'d and freed first), which is why
    #     the shipped guard accepts the slice and its golden is byte-identical.
    # `lowered_sites: 0` records the DEFECT itself, so the A8 delta stays
    # measurable rather than becoming folklore: the old classifier still cannot
    # see this site, and that is the whole reason the default moved.
    ("e2e:e2e-slice-control-seq-grover",
     {"sites_source_min": 1, "shipped_hit": False, "lowered_sites": 0},
     "bd nepx FIXED by M-C 2a+2b: the one-rail program. The S-dagger SITE must "
     "be FOUND from the pre-lowering view (blind spot A8 dropped it) and must "
     "be a MISS (nothing undischarged stands at the gate). A regression to HIT "
     "means nepx came back; a regression to 0 source sites means A8 came back"),
    # THE A5 ARTEFACT PIN, RE-DISPOSITIONED BY THE SAME UPGRADE.
    #
    # It used to assert "remains a census HIT". That was right for a census
    # whose sites came from the lowered text and wrong about the compiler: this
    # fixture is authored in ALREADY-LOWERED form, its `cqrt_ry` is hand-written,
    # it is in NO emitter-recorded set, and `TaintPropagation.h` says so
    # explicitly — the guard cannot fire on it BY CONSTRUCTION. The upgrade makes
    # the census agree, so the pin now asserts the agreement AND keeps the
    # artefact visible: zero sites in the source view, still a HIT in the
    # lowered one.
    ("lit:lowering_uncompute_sink_move_past_unwalked_gate",
     {"sites_source": 0, "shipped_hit": False, "lowered_view_hit": True},
     "KNOWN ARTEFACT (spike §9.3, blind spot A5): hand-written `cqrt_ry` in an "
     "already-lowered fixture, on a rail its own comment declares UNTAINTED. "
     "The pre-lowering view sees no `@cq_theta` at all, which is exactly what "
     "the guard sees; the LOWERED view still calls it a hit, and that gap is "
     "the artefact class — pinned so it stays visible instead of vanishing"),
]


def check_acceptance(by_name):
    """-> (rc, [lines]). Every pin prints its witness, pass or fail."""
    rc, lines = 0, []
    for mod, want, why in ACCEPTANCE:
        m = by_name.get(mod)
        if m is None:
            lines.append(f"  MISSING {mod} — not in the lowered corpus")
            rc = 1
            continue
        got = {
            "sites_source": len(m["thetas_source"]),
            "sites_lowered": len(m["thetas_lowered"]),
            "shipped_hit": module_hit(m, SHIPPED, "thetas"),
            "lowered_view_hit": module_hit(m, SHIPPED, "thetas_lowered"),
        }
        fails = []
        if "sites_source" in want and got["sites_source"] != want["sites_source"]:
            fails.append(f"sites_source={got['sites_source']} "
                         f"want {want['sites_source']}")
        if "sites_source_min" in want \
                and got["sites_source"] < want["sites_source_min"]:
            fails.append(f"sites_source={got['sites_source']} "
                         f"want >={want['sites_source_min']}")
        if "lowered_sites" in want \
                and got["sites_lowered"] != want["lowered_sites"]:
            fails.append(f"sites_lowered={got['sites_lowered']} "
                         f"want {want['lowered_sites']}")
        for k in ("shipped_hit", "lowered_view_hit"):
            if k in want and got[k] != want[k]:
                fails.append(f"{k}={got[k]} want {want[k]}")
        rc |= (1 if fails else 0)
        lines.append(f"  {'FAIL' if fails else 'PASS'} {mod}: "
                     f"sites(source)={got['sites_source']} "
                     f"sites(lowered)={got['sites_lowered']} "
                     f"shipped={'HIT' if got['shipped_hit'] else 'MISS'}"
                     + (f"   [{'; '.join(fails)}]" if fails else ""))
        lines.append(f"       {why}")
        for t in m["sites"]:
            b = t["by_predicate"][SHIPPED]
            views = ("source" if t["in_source_view"] else "") + \
                    ("+lowered" if t["in_lowered_view"] else "")
            lines.append(f"       line {t['line']} wire={t['wire']} "
                         f"view=[{views or 'neither'}] "
                         f"records={b['records']} hits={b['hits']}")
            for e in b["exempt"]:
                lines.append(f"         exempt {e['rail']} by clause "
                             f"{e['clause']} at {e['witness']}")
            for r in b["skipped_clause6"]:
                lines.append(f"         clause-6 skip (minted after gate): {r}")
    return rc, lines


# ---------------------------------------------------------------------------
# `--validate-guard` — the census verdict vs the REAL `cq-opt` verdict.
#
# EVERY EXPLANATION BELOW IS A MEASUREMENT, and a module that disagrees without
# one prints UNEXPLAINED and fails the check. That is the whole point: an
# "explained disagreement" list nobody is forced to extend is a list that grows
# silently (the SPIKE §2R.5 lesson, in miniature).
# ---------------------------------------------------------------------------

KNOWN_DISAGREEMENTS = {
    "lit:lowering_uncompute_sink_move_past_unwalked_gate":
        "A5 artefact — already-lowered fixture, hand-written `cqrt_ry` in no "
        "emitter-recorded set, rail declared UNTAINTED by its own comment. "
        "Reachable only under `--site-source lowered`; the default view reports "
        "0 sites here and therefore agrees with the compiler.",
    "lit:lowering_uncompute_borrowed_operand_free_order":
        "A5 artefact — same class (SPIKE §2R.5): three hand-written "
        "`cqrt_ry_i32` in an already-lowered fixture. Reachable only under "
        "`--site-source lowered`.",
    "lit:lowering_reject_live_record_clone_unused_arg":
        "S2, the model's DOCUMENTED clone-hop divergence, observed for the "
        "first time (M-A Increment 7b, 2026-08-29). The guard's clone hop is "
        "PER ARGUMENT (`cloneArgReachesResult` — an argument the callee never "
        "READS gets no hop, the Inc-3 round-2 N3 finding); parameter use is a "
        "property of the callee BODY, which shipped_guard_model.py deliberately "
        "does not resolve interprocedurally, so it hops unconditionally and "
        "EXEMPTS the record the guard counts. shipped_guard_model.py §S2 states "
        "the divergence and its direction (\"exempts more than the guard\") and "
        "counts every such hop in `clone_hops_unchecked`. THIS IS THE ONLY CELL "
        "OF ITS KIND ON TODAY\'S CORPUS, and it is a MISS/warns — the cell that "
        "was structurally unreachable while the guard declined, because a "
        "declining module emitted no lowered IR and never entered the corpus. "
        "Making it visible is what the severity change bought this table.",
}


def validate_guard(mods, verdicts, view="thetas", pred=SHIPPED):
    """-> (rc, report dict, [lines]).

    `verdicts` maps module label -> (rc, stderr) from the real `cq-opt` run that
    produced (or refused to produce) the lowered IR this census read.
    """
    rows = {"hit/warns": [], "hit/silent": [],
            "miss/warns": [], "miss/silent": []}
    for m in mods:
        if not m[view]:
            continue
        label = m["module"]
        _rc0, err = verdicts.get(label, (0, ""))
        # THE VERDICT IS THE STDERR MESSAGE, NOT THE EXIT CODE (M-A Increment 7b,
        # owner ruling 2026-08-29 / bd lyyf): the guard warns and `opt` exits
        # zero either way, so `rc != 0` now means "some OTHER stage declined"
        # and says nothing about this one.
        actual = "warns" if sgm.MSG_LIVE_RECORD in err else "silent"
        key = ("hit" if module_hit(m, pred, view) else "miss") + "/" + actual
        rows.setdefault(key, []).append(label)
    # Modules that never reached this guard because an EARLIER stage declined
    # loudly. They are outside the corpus (no lowered IR), exactly as the
    # guard's own fixtures used to be.
    other_declines = sum(1 for lbl, (rc0, err) in verdicts.items()
                         if rc0 != 0 and sgm.MSG_LIVE_RECORD not in err)
    over = sorted(rows.get("hit/silent", []))
    under = sorted(rows.get("miss/warns", []))
    dis = over + under
    unexplained = [d for d in dis if d not in KNOWN_DISAGREEMENTS]
    lines = [
        "",
        f"VALIDATION vs the real guard (`cq-opt` STDERR, message: "
        f"\"{sgm.MSG_LIVE_RECORD}\")",
        f"  site view: {view}    predicate: {pred}",
        "",
        "  modules WITH >=1 chained-theta site, in the lowered corpus:",
        f"    census HIT  / cq-opt WARNS   : {len(rows.get('hit/warns', []))}"
        f"   <- agreement",
        f"    census HIT  / cq-opt SILENT  : {len(over)}"
        f"   <- DISAGREEMENT (census OVER-predicts)",
        f"    census MISS / cq-opt WARNS   : {len(under)}"
        f"   <- DISAGREEMENT (census UNDER-predicts — the cell that was "
        f"unreachable before Increment 7b)",
        f"    census MISS / cq-opt SILENT  : {len(rows.get('miss/silent', []))}"
        f"   <- agreement",
        "",
        f"  NOT MODELLABLE (an EARLIER stage declined, so no lowered IR):",
        f"    fixtures declining elsewhere : {other_declines}",
    ]
    for d in dis:
        lines.append(f"    DISAGREE {d}")
        lines.append("      " + KNOWN_DISAGREEMENTS.get(d, "UNEXPLAINED"))
    rc = 1 if unexplained else 0
    if unexplained:
        lines.append(f"  FAIL: {len(unexplained)} UNEXPLAINED disagreement(s)")
    else:
        lines.append("  OK: zero unexplained disagreements")
    report = {
        "site_view": view, "predicate": pred,
        "census_hit_cqopt_warns": sorted(rows.get("hit/warns", [])),
        "census_hit_cqopt_silent": over,
        "census_miss_cqopt_warns": under,
        "census_miss_cqopt_silent": len(rows.get("miss/silent", [])),
        "unexplained_disagreements": unexplained,
        "other_declines": other_declines,
        "explanations": {d: KNOWN_DISAGREEMENTS.get(d, "UNEXPLAINED")
                         for d in dis},
    }
    return rc, report, lines


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--json")
    ap.add_argument("--delta-json",
                    help="write the site-source + predicate delta artifact")
    ap.add_argument("--repo", default=cc.REPO)
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--predicate", choices=PREDICATES, default=SHIPPED,
                    help="headline population (all are always computed)")
    ap.add_argument("--site-source", choices=SITE_SOURCES, default="source",
                    help="where chained-theta SITES come from (both are always "
                         "computed; `source` is the post-A8 default)")
    ap.add_argument("--acceptance", action="store_true",
                    help="print the pinned acceptance tests and exit nonzero "
                         "if any fails")
    ap.add_argument("--validate-guard", action="store_true",
                    help="print the census-vs-cq-opt confusion table and exit "
                         "nonzero on an UNEXPLAINED disagreement")
    args = ap.parse_args(argv)
    pred = args.predicate
    view = "thetas"

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
            rc0, out, err = cc.lower_ll(path, args.repo)
            pre = path
        else:
            rc0, out, err = cc.lower_slice(sl, args.repo)
            pre, _ = cc.stage1_ll(sl, args.repo)
        if rc0 != 0 or out is None:
            return label, rc0, err, None
        return label, rc0, err, analyse_module(out, label, pre_path=pre,
                                               site_source=args.site_source)

    with cfut.ThreadPoolExecutor(max_workers=args.jobs) as ex:
        raw = list(ex.map(go, work))
    verdicts = {lbl: (rc0, err or "") for lbl, rc0, err, _ in raw}
    mods = [m for _, _, _, m in raw if m is not None]

    by_name = {m["module"]: m for m in mods}
    hits = [m for m in mods if m["thetas"]]
    hits_ub = [m for m in mods if m["thetas_incl_adjoint"]]
    by_pred = {p: populations(mods, p, view) for p in PREDICATES}
    inc1, inc3, neither = by_pred[pred]

    def names(lst):
        return sorted(m["module"] for m in lst)

    def agg(p, key, v=view):
        return sum(len(t["by_predicate"][p][key]) for m in mods for t in m[v])

    n_theta = sum(len(m["thetas"]) for m in mods)
    n_theta_src = sum(len(m["thetas_source"]) for m in mods)
    n_theta_low = sum(len(m["thetas_lowered"]) for m in mods)

    # ---- the A8 SITE-SOURCE delta, under the SELECTED predicate -------------
    declined_src = {m["module"] for m in mods
                    if module_hit(m, pred, "thetas_source")}
    declined_low = {m["module"] for m in mods
                    if module_hit(m, pred, "thetas_lowered")}
    site_gained = sorted(m["module"] for m in mods
                         if len(m["thetas_source"]) > len(m["thetas_lowered"]))
    site_lost = sorted(m["module"] for m in mods
                       if len(m["thetas_source"]) < len(m["thetas_lowered"]))
    mapping_failed = sorted(m["module"] for m in mods if m["site_mapping_failed"])

    # ---- the PREDICATE delta, on the SELECTED site view --------------------
    other = "ruled" if pred != "ruled" else "plan-v1"
    declined_pred = set(names(inc1)) | set(names(inc3))
    o1, o3, _ = by_pred[other]
    declined_other = set(names(o1)) | set(names(o3))
    dropped = sorted(declined_other - declined_pred)
    added = sorted(declined_pred - declined_other)

    alloc_only = [m for m in neither
                  if any(t["by_predicate"][pred]["ancestor_alloc_rails"]
                         or t["by_predicate"][pred]["descendant_alloc_rails"]
                         for t in m[view])]
    corr_only = [m for m in neither
                 if any(t["by_predicate"][pred]["correlated_hits"]
                        for t in m[view])]

    vrc, vreport, vlines = validate_guard(mods, verdicts, view, pred)

    # ---- PROVENANCE. Which compiler, which tree, which corpus. -------------
    # This census measures a MOVING target: the lit corpus is a glob and the
    # binary is whatever `build/` last produced. An artifact that does not say
    # WHICH is the "number measuring the wrong program" failure mode with extra
    # steps, so the tool key (SHA-256 of the cq-opt + plugin bytes, the cache's
    # own key) and the dirty-file list are written into every report.
    import subprocess as _sp

    def _git(*a):
        try:
            return _sp.run(["git"] + list(a), cwd=args.repo, text=True,
                           capture_output=True).stdout.strip()
        except Exception:
            return "?"
    prov = {"tool_key": cc.tool_key(args.repo),
            "git_head": _git("rev-parse", "HEAD"),
            "worktree_dirty": [ln for ln in _git("status", "--porcelain").split("\n")
                               if ln.strip()],
            "lit_fixtures": len([1 for lbl in verdicts if lbl.startswith("lit:")])}

    # Clause-by-clause exemption tally (the shipped predicate only) — a headline
    # of "0 would decline" is only readable next to WHY nothing counted.
    by_clause = {2: 0, 3: 0, 4: 0}
    n_records = 0
    src_structurally_source = []
    for m in mods:
        for t in m[view]:
            n_records += len(t["by_predicate"][SHIPPED]["records"])
            for e in t["by_predicate"][SHIPPED]["exempt"]:
                by_clause[e["clause"]] = by_clause.get(e["clause"], 0) + 1
        for t in m["sites"]:
            # A site the SOURCE view calls chained while the lowered stream
            # shows an `alloc`+`ry` pair at it: `source_ir`'s taint is an UPPER
            # BOUND (it propagates through a classical-returning call the real
            # pass scrubs — SPIKE §10, `spec_reseed_theta_source`). Direction:
            # over-counts SITES, which is the safe side, but it is a real
            # divergence from `taint.UserChainedRotations` and is counted here
            # rather than left to be rediscovered.
            if t["in_source_view"] and not t["chained_primary"]:
                src_structurally_source.append(f"{m['module']}:{t['line']}")

    report = {
        "provenance": prov,
        "shipped_records_examined": n_records,
        "exempt_by_clause": {str(k): v for k, v in sorted(by_clause.items())},
        "source_sites_structurally_alloc_minted": sorted(src_structurally_source),
        "predicate": pred,
        "site_source": args.site_source,
        "models": "shipped guard mirrored from ir-pass/src/RotationLowering.cpp "
                  "at commit b4e329b (Inc 3); see shipped_guard_model.py",
        "ruling": "OWNER RULINGS 2026-08-27 (x2), 2026-08-28 F2 + F1, bd "
                  "test_C_libtooling-6uqc",
        "corpus": {"modules_lowered": len(mods),
                   "lit": sum(1 for m in mods if m["module"].startswith("lit:")),
                   "e2e": sum(1 for m in mods if m["module"].startswith("e2e:")),
                   "lit_fixtures_total": sum(1 for lbl in verdicts
                                             if lbl.startswith("lit:"))},
        "chained_thetas": n_theta,
        "chained_thetas_source_view": n_theta_src,
        "chained_thetas_lowered_view": n_theta_low,
        "chained_thetas_incl_adjoint_ry": sum(len(m["thetas_incl_adjoint"])
                                              for m in mods),
        "modules_with_chained_theta": len(hits),
        "modules_with_chained_theta_incl_adjoint_ry": len(hits_ub),
        "would_decline": sorted(declined_pred),
        "would_decline_by_closure": {"descendant": names(inc1),
                                     "ancestor_or_sibling": names(inc3)},
        "chained_theta_no_record": names(neither),
        "chained_theta_alloc_ancestor_only": names(alloc_only),
        "chained_theta_correlated_only": names(corr_only),
        "site_source_delta": {
            "sites_source_view": n_theta_src,
            "sites_lowered_view": n_theta_low,
            "modules_gaining_sites": site_gained,
            "modules_losing_sites": site_lost,
            "would_decline_source_view": sorted(declined_src),
            "would_decline_lowered_view": sorted(declined_low),
            "decline_only_under_source": sorted(declined_src - declined_low),
            "decline_only_under_lowered": sorted(declined_low - declined_src),
            "site_mapping_failed": mapping_failed,
            "per_module": [{"module": n, "why": _why_sites(by_name[n])}
                           for n in sorted(set(site_gained) | set(site_lost))],
        },
        "exempt_measured_hits": agg(pred, "exempt_measured"),
        "exempt_live_after_hits": agg(pred, "exempt_live_after"),
        "shipped_model_counters": {
            "spine_indistinguishable_hops":
                sum(m["spine_indistinguishable_hops"] for m in mods),
            "clone_hops_unchecked":
                sum(m["clone_hops_unchecked"] for m in mods),
            "unreachable_uses_skipped":
                sum(m["unreachable_uses_skipped"] for m in mods),
            "clause6_skipped_rails": agg(pred, "skipped_clause6")
            if pred == SHIPPED else None,
        },
        "multi_block_fns": sum(m["multi_block_fns"] for m in mods),
        "total_fns": sum(m["n_fns"] for m in mods),
        "inv_mints_total": sum(m["inv_mints"] for m in mods),
        "dbg_uses_skipped": sum(m["dbg_uses_skipped"] for m in mods),
        f"delta_vs_{other}": {
            "declining": sorted(declined_other),
            "dropped_out": [{"module": n,
                             "reason": _why(by_name[n], other, pred, view)}
                            for n in dropped],
            "newly_in": [{"module": n,
                          "reason": _why(by_name[n], other, pred, view)}
                         for n in added],
        },
        "validation": vreport,
        "modules": hits,
    }

    print(f"predicate: {pred}   site-source: {args.site_source}   "
          f"(all predicates and both site sources computed; deltas below)")
    print(f"corpus: {report['corpus']['modules_lowered']} lowered modules "
          f"({report['corpus']['lit']} lit, {report['corpus']['e2e']} e2e) "
          f"out of {report['corpus']['lit_fixtures_total']} lit fixtures")
    print(f"provenance: HEAD {prov['git_head'][:9]}  tool_key "
          f"{prov['tool_key'][:12]}  dirty files {len(prov['worktree_dirty'])}")
    print(f"chained-theta SITES: {n_theta} in {len(hits)} modules "
          f"[source view {n_theta_src} · lowered view {n_theta_low} · "
          f"lowered incl. compiler adjoint Ry "
          f"{report['chained_thetas_incl_adjoint_ry']} in {len(hits_ub)}]")
    print(f"WOULD DECLINE under {pred}: {len(declined_pred)} modules "
          f"({len(inc1)} via a descendant record, {len(inc3)} via an "
          f"ancestor/sibling record)")
    print(f"chained theta, no counting record           : {len(neither)} "
          f"modules")
    print(f"records examined by the SHIPPED clause-1 walk over these sites: "
          f"{n_records}  (always the shipped walk, whatever --predicate says: a "
          f"'0 would decline' headline is only readable beside the number of "
          f"records that were examined and then discharged)")
    print(f"exemptions by clause: 2 (discharged before the gate)="
          f"{by_clause.get(2, 0)}  3 (observed after the gate)="
          f"{by_clause.get(3, 0)}  4 (measured before the gate)="
          f"{by_clause.get(4, 0)}  |  clause-6 skips (minted after the gate)="
          f"{report['shipped_model_counters']['clause6_skipped_rails']}")
    if src_structurally_source:
        print(f"source-view sites the LOWERED stream shows as alloc-minted "
              f"(source_ir over-taint, over-counts sites): "
              f"{len(src_structurally_source)} — "
              f"{', '.join(src_structurally_source)}")
    print(f"shipped-model divergence counters: "
          f"spine-indistinguishable hops="
          f"{report['shipped_model_counters']['spine_indistinguishable_hops']} "
          f"unchecked clone hops="
          f"{report['shipped_model_counters']['clone_hops_unchecked']} "
          f"unreachable uses skipped="
          f"{report['shipped_model_counters']['unreachable_uses_skipped']}")
    print(f"approximation counters: multi_block_fns="
          f"{report['multi_block_fns']}/{report['total_fns']} "
          f"inv_mints={report['inv_mints_total']} "
          f"dbg_uses_skipped={report['dbg_uses_skipped']}")
    print()
    print(f"A8 SITE-SOURCE DELTA (source vs lowered), predicate {pred}:")
    print(f"  sites   : {n_theta_low} (lowered) -> {n_theta_src} (source)")
    print(f"  declines: {len(declined_low)} (lowered) -> {len(declined_src)} "
          f"(source)")
    print(f"  modules gaining sites : {len(site_gained)}")
    for n in site_gained:
        print(f"    + {n}\n        {_why_sites(by_name[n])}")
    print(f"  modules losing sites  : {len(site_lost)}")
    for n in site_lost:
        print(f"    - {n}\n        {_why_sites(by_name[n])}")
    if mapping_failed:
        print(f"  !! SITE MAPPING FAILED in {len(mapping_failed)} module(s) — "
              f"each FELL BACK to the lowered view (over-counting direction):")
        for n in mapping_failed:
            for f in by_name[n]["site_mapping_failed"][:4]:
                print(f"      {n}: {f}")
    else:
        print("  site mapping failures : 0")
    print()
    print(f"PREDICATE DELTA vs {other}: {len(declined_other)} -> "
          f"{len(declined_pred)} declining modules "
          f"({len(dropped)} dropped out, {len(added)} new)")
    for n in dropped:
        print(f"  - {n}\n        {_why(by_name[n], other, pred, view)}")
    for n in added:
        print(f"  + {n}\n        {_why(by_name[n], other, pred, view)}")
    print()
    for m in sorted((by_name[n] for n in sorted(declined_pred)),
                    key=lambda x: x["module"]):
        for t in m[view]:
            b = t["by_predicate"][pred]
            if not (b["descendant_hits"] or b["ancestor_hits"]):
                continue
            print(f"  HIT {m['module']} fn={t['fn']} line={t['line']} "
                  f"wire={t['wire']}")
            if b["descendant_hits"]:
                print(f"        desc: {', '.join(b['descendant_hits'])}")
            if b["ancestor_hits"]:
                print(f"        anc : {', '.join(b['ancestor_hits'])}")

    rc = 0
    if args.validate_guard:
        for ln in vlines:
            print(ln)
        rc |= vrc
    if args.acceptance:
        print(f"\nACCEPTANCE PINS (predicate {SHIPPED}, site-source "
              f"{args.site_source}):")
        arc, alines = check_acceptance(by_name)
        for ln in alines:
            print(ln)
        rc |= arc
        # The pins are only meaningful if the census still agrees with the
        # compiler, so `--acceptance` runs the guard validation too.
        for ln in vlines:
            print(ln)
        rc |= vrc

    if args.json:
        with open(args.json, "w") as f:
            json.dump(report, f, indent=1, sort_keys=True)
        print(f"\nwrote {args.json}")
    if args.delta_json:
        delta = {"predicate": pred,
                 "site_source_delta": report["site_source_delta"],
                 f"delta_vs_{other}": report[f"delta_vs_{other}"],
                 "predicate_populations": {
                     p: sorted({m["module"] for m in mods
                                if module_hit(m, p, view)})
                     for p in PREDICATES},
                 "predicate_populations_lowered_site_view": {
                     p: sorted({m["module"] for m in mods
                                if module_hit(m, p, "thetas_lowered")})
                     for p in PREDICATES},
                 "validation": vreport}
        with open(args.delta_json, "w") as f:
            json.dump(delta, f, indent=1, sort_keys=True)
        print(f"wrote {args.delta_json}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
