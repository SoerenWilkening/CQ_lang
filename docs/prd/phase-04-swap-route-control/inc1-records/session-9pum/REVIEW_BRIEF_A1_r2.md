# Rule-13 review brief, round 2 — Track A.1 (compare-select fence parity), reviewing the round-1 FIX

Worktree `/Users/sorenwilkening/Desktop/CQ_trackA`, branch `compare-select-parity`, `build/` current (do
NOT rebuild; do NOT edit `ir-pass/`, `include/`, `tests/`, `tools/`). Read in order: `review_a1_r1.md`
(the BLOCK), `FIX_BRIEF_A1_R1.md`, `FIX_A1_R1.md` (what was built, its ERRATA, its Q-1..Q-5), then
`IMPL_A1.md`, `BRIEF_A1.md`. ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` +
`libCQPass.so` (read-only). Gates already run on the fix: `ir-pass-lit` 1803/1802+1 XFAIL; e2e 382/382;
full `ctest -j6` 392/392 (1253 s loaded); `cq-opt-equivalence-full` 1803 / 0; corpus diff 1776 `0/0/0`;
probe diff 129 probes, 17 movers (15 ACCEPT→DECLINE target shapes, 2 DECLINE→ACCEPT `b1`/`b2` pinned).
Re-run `ir-pass-lit` and what you touch; not the full suite.

## What the fix did

* F-A1-1: rung (iii)'s round-2 re-ask is a SET DIFFERENCE. `WireWalk.{h,cpp}` gain a `Covered` exempt-set
  parameter and an enumerating sibling `collectNonDiagonalWireGates`, both faces over ONE implementation
  `walkNonDiagonalWireGates`; `reverifyCmpCondReads` enumerates the taint-BLIND gates and hands them back as
  `Covered` (containment `blind ⊆ round-1 ⊆ final` written at the call site). `k7`+`lib3` and `o3_kick`
  ACCEPT→DECLINE; `k8`/`k9`/`k6` unchanged. Mutation M-1 (exempt set disabled) reddens EXACTLY the 12
  in-loop accepts and NOT the S† control (the earlier claim that "re-ask everything costs the S†" was
  false and is corrected); M-2 (the old boolean) reddens exactly the new k7 decline.
* F-A1-2: two rail in-loop iteration-local accepts pinned (lit ×2, e2e rolled/unrolled pair, 12 = 12);
  ⚠ on `main` the ROLLED form declines and the UNROLLED accepts — a rolled ≠ unrolled split the barrier
  closes. ERRATA in IMPL §5 and BRIEF head.
* F-A1-3: new `condCmpOperandSeeds` (direct tainted operands) seeds rung (ii) at both askers via
  `CmpCondRead::OperandSeeds`; rung (iii) keeps the cone; `railWireNamesBackward` now crosses
  `taint.InPlaceRailOps`. `c1`/`c10` accept; `c2`/`c9` KEEP declining and are correct (`-O1` folds the cast /
  rewrites the compare back onto the parent, so the direct operand IS the measured register — r903(b)
  verbatim), pinned. The in-place DECLINE face measured UNREACHABLE (pre-empted by
  `LoopLowering::staleRailRecordRead`; probes `ip1`/`ip3`) — Q-3.
* F-A1-4 probes + bd `lo7u`; F-A1-5 docs (the `Seeds.empty()` accept-direction skip with argument +
  retirement trigger; O-5 measured; the rung-(iii) divergence between ladders stated).

## Where to look (attack the FIX, then re-attack the increment through it)

1. **Q-1, the exempt set by IDENTITY.** A gate the classifier ACCEPTED at round 1 (positionally —
   `ProvenPostRegion` via the DT prong, or the S† after a phase region) is exempt at round 2 by identity.
   Round 2 can change the WIRE that gate sits on (a `%out`-derived sibling chained in — the k7 shape — is
   caught because the sibling is NOT exempt). Find the case where the exempt gate's own RULING becomes
   false without any new gate: the round-1 positional proof depended on a DT/reachability fact that the
   round-2 FLATTEN or the loop collapse invalidates (the flatten erases blocks; a gate "provably after every
   execution of the select" at round 1 may sit in a block the flatten merged so that it now executes on a
   path the round-1 DT did not have); an exempt gate whose ARG-0 was classical at round 1 (so "non-diagonal
   gate on the wire" meant one thing) and is a chained theta at final taint (the F-B1R2-1 mechanism applied
   to the EXEMPT gate itself rather than to a sibling — is a gate whose CHAINED-ness changed the same
   gate by identity? then exempting it by identity re-opens the window). Two-TU plain C first.
2. **The containment `blind ⊆ round-1 ⊆ final`.** The blind set is computed at reverify time with
   taint-blind ancestry; round 1's set was computed at classify time with round-1 taint. Is blind really a
   SUBSET of what round 1 saw — a gate round 1 saw through a round-1-tainted parent that the blind walk
   cannot cross (round-1 taint > blind)? Then a gate in `round1 \ blind` is re-asked position-free and
   DECLINES a program round 1 accepted positionally — an over-decline (Q-2 says 0 movers measured; find
   one from plain C or show why the walker's ancestry makes the sets equal).
3. **`collectNonDiagonalWireGates` vs `findNonDiagonalWireGate`.** One implementation, two faces —
   confirm by mutation that the enumerating face visits exactly the gates the return-first face could
   return (a gate reachable only through a path the return-first walk pruned after its first hit).
4. **F-A1-3's two crossings.** `condCmpOperandSeeds` on direct operands + `railWireNamesBackward` crossing
   `InPlaceRailOps`: (a) an in-place relabelling BETWEEN the measure and the compare (`m = cq_measure(q);
   q += 1 /*in place*/; a = (q == 5) ? …`) — measured before? (b) a cast the direct operand goes through
   that `-O1` does NOT fold (a `sext` to i64 kept live) — the operand is the cast rail (fresh), the measure
   is of `q`: accept is CORRECT only if the cast rail is not the measured rail — confirm from the trace;
   (c) Q-5: the Q+Q compare (`(q == r) ? …`) with `q` measured before — both operands must be seeded.
5. **Q-4, the `OperandSeeds`-empty skip** — when is it empty for a tainted compare? A compare whose only
   tainted operand is a CONSTANT-folded value at round 1 that becomes a rail at round 2 (`%out`-derived):
   is the record's seed set then empty at record time and never refreshed? That is the 9pum window again,
   one field over.
6. **The rail side of F-A1-2.** The per-activation barrier admits the wire ORIGIN when it is a SOURCE
   theta: `b1`/`b2` accept correctly. Now the origin is a source theta in the preheader whose result is
   loop-carried through a header phi (NOT iteration-local) with `cq_measure(b)` in the body — must decline
   (post-measure control on trip 2). And the drbq Inc-3 in-loop controlled-Ry arm with `cq_measure` of the
   condition in the body.
7. **Every accept fixture the fix added: `-O1` reachability + the state-vector argument**; every decline:
   the circuit is genuinely invalid (post-measure control or a stale name). List any decline of a VALID
   circuit as OVER-DECLINE (the owner's ruling).

## Method

Scratch `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/trackA_review2/`;
plain C `-O1` first (two-TU via `llvm-link` as in `session-r9e5/review_b1_r2_probes/run_multi.sh`), hand
IR second; both binaries; grade CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC;
verdict BLOCK / CLEAR-WITH-ITEMS / CLEAR. Report `session-9pum/review_a1_r2.md`, probes
`session-9pum/review_a1_r2_probes/` with a runner. Final message ≤30 lines: verdict, findings one line
each with grade, the Q-1 and containment outcomes explicitly.
