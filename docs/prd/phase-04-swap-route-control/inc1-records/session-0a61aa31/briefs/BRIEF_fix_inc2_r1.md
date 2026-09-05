# BRIEF_fix_inc2_r1 — Inc 2 (value arms by controlled-copy merge), ROUND-1 FIX agent
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_impl_inc2.md`, `$SP/progress/impl_inc2.md`, then
`$SP/progress/review_inc2_V1.md` and `$SP/progress/review_inc2_V2.md` in full, and
`$SP/progress/OWNER_QUESTIONS.md` (OQ-22 carries the orchestrator's disposition for F-V1-1).
Agent name: `fix_inc2_r1`. Model: opus.

## Where you work
Worktree `$SP/wt/inc2`, branch `3qlq-inc2` (tip 8c526d9, build current). SUBJECT-BEFORE = a copy of the
current binary you take BEFORE editing (`cp -f build/ir-pass/cq-opt $SP/progress/inc2_before_cq-opt`, same
for the .so); ORACLE = `$SP/wt/pre-3qlq`. Do NOT rebase onto Inc 1 yet — the orchestrator does that after
Inc 1 lands; keep your commits file-local to the value path.

## From V1
- **F-V1-1 (OQ-22): KEEP the widening and PIN it.** The diamond routed through `emitSelectRegion` sets
  `taint.HandleWidth[Out]`; a downstream cast / Q+Q compare on the merged register now accepts. Write the
  five plain-C programs (`$SP/progress/review_inc2_V1/probe/g1_i8_cast, g3_i64_cast, g2_i8_qq, g4_i16_qq,
  s3_out_qq_i32`) as ACCEPT fixtures (CHECKs derived from the output; whole-file NOROUTE negatives; counts
  in their own prefix) with headers stating: oracle declined (string), subject accepts, the stream is the
  4.4 select merge's own, and the width table is the mechanism; add ONE e2e slice for the i32 Q+Q compare
  after a value arm with its golden; correct the two hand-back sentences in your notes. If while pinning
  you find a width where the accepted stream is WRONG (a laundered width that mismatches the template
  chosen), that is a finding — stop and report, do not pin it.
- **F-V1-2:** pre-fence `compareFlagMintable` (the width half) at detection beside F-QQCOND so
  `emitSelectRegion` cannot fail after the flatten; hand-IR fixture if constructible (V1 says it needs an
  i128 condition, which is F-V1-9's pre-existing gap — if unconstructible, add the fence + a comment
  naming why no fixture exists).
- **F-V1-3:** fix the totality table's fp row rationale (the fp merge is lifted to a select BEFORE
  detection — `n1_fp_diamond.ll`); mark the value path's fp backstop as unreached, with a hand-IR
  fixture if you can construct a diamond that reaches it, else a comment.
- **F-V1-4:** the chain-final rail is NOT `_unc`'d/freed — correct the PRD (§3 "Value arm by controlled
  copy" and §7.1) with an errata note in the Inc-2 notes (`RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1) and in the
  slice headers: "left allocated and entangled with out; sound while p is retained (keep-source-live);
  follow-on 3qlq.5 frees it".
- **F-V1-5:** accept fixture pinning that M-C does NOT convert the hoisted chain head in place
  (`a2`/`h2`/`h3` shapes) + add the value merge to the G6/G7 "weak tripwire" comment's consumer list in
  `ArithLowering.cpp`.
- **F-V1-6:** correct the rationale sentence ("`0 sdiv n` on a |0> rail" → "the route's rail held a
  superposition of p0 and 0, so the totality obligation was identical"); note the `INT_MIN/-1` arm is
  exercised by nothing.
- **F-V1-7:** promote the negated-polarity twin pair (`if (q != 5)`) to a slice pair + `cmp` gate.
- **F-V1-9:** `bd create` an issue for the pre-existing unclaimed `icmp i128` branch condition (title:
  "control layer neither claims nor declines a tainted i128 compare branch condition (pre-3qlq)"), with
  the two hand-IR reproducers copied under `docs/prd/phase-04-swap-route-control/inc2-records/`.

## From V2
- **F-V2-1:** `SwitchValueEmit.cpp:1-30` header (byte-identical to main) describes the RETIRED cswap route in the
  present tense and cites a deleted include; also `SwitchRouteEmit.h:53-55` and the `CaseStream` doc comment
  (`:89-91`) — rewrite all three for the preload + XOR-delta mechanism (note: SwitchRouteEmit.cpp is being
  rewritten by Inc 1b for the PHASE switch — touch only the VALUE-side comments, and expect a rebase).
- **F-V2-2:** `slice_control_value_derived.c:3-5,12` claims a twin + gate that do not exist; CMakeLists is right
  — fix the header ("no twin: its select twin declines `control flow` on both binaries").
- **F-V2-3 = F-V1-4** (chain final / switch deltas `d_i` left DIRTY, not `_unc`'d: route 9/3 → Inc 2 4/4 dirty on
  value_diamond; switch 5/3 → 5/5): correct PRD §3/§7.1 via the notes errata + `SwapRouteEmit.cpp:438`'s "exactly
  as the route left them"; state that 3qlq.5 (free the source) is UNSOUND BY DEFAULT under this leak class and
  needs the deltas/finals discharged first.
- **F-V2-4:** the cswap census says four call sites; measured SEVEN (NestedRouteEmit ×4 — deleted by Inc 1b anyway —
  SwitchRouteEmit :159/:172 (Inc 1b retires), AbortParkEmit :381) plus EmitInverse.cpp:261 can re-emit one; correct
  the notes (the material claim — zero value-path sites, 5 → 3 goldens — holds).
- **F-V2-5 (fix before commit):** the 7 re-derived accepts dropped ALL `CHECK-NEXT` contiguity (28 → 0 in
  control_swap_value_ifelse.ll); an injected `cqrt_ry_i32` before the first controlled copy passes all prefixes in
  7 of 8 accepts. Restore a contiguous `CHECK`→`CHECK-NEXT` chain from the flag mint through the second copy to
  the strip/free in every accept (derive from the output), keeping the NOROUTE/count prefixes; validate with V2's
  injection ($SP/progress/review_inc2_V2/).
- **F-V2-6 (fix before commit):** `control_swap_value_accept_div_const.ll` is blind to a DROPPED FLAG STRIP (a
  dirty free = hidden measurement) and to a dropped chain `_unc`/rail free — pin the `icmp_*_unc` before the
  `cqrt_free(%F)` with CHECK-NEXT; add a `CCNT` count to `accept_nonclobber` (a duplicated merge copy passes
  today); add the switch-half ACCEPT discriminator for the totality fence (`p/3` inside a switch case).
- `SwitchValueEmit.cpp:133` silently `continue`s on a shape its comment calls malformed — make it bail loudly
  like its neighbours (unreachable at HEAD; pin by comment if no fixture is constructible).
- V2 built a basis-state evaluator over the emitted gate list as an INDEPENDENT witness for value regions
  (pure permutations, so classical evaluation on basis inputs IS a complete check of the permutation and of
  "freed at |0>"); it is NOT a statevector simulation. Reference it in the notes as a measurement V2 made; do
  NOT add it as a ctest gate (owner decision 2026-06-10 on simulations stands — the orchestrator will put the
  question to the owner).

## Also
Red-green every fixture (main/before binary vs yours); STRICT 2b on every reproducer; re-run the three
(now four) twin gates; lit on your binary in the background; write the notes file §1. Hand back per
BRIEF_common with per-finding status and fixture names.
