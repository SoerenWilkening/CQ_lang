# BRIEF_review_inc2_r2 — Inc 2 ROUND 2 (one lens) after the rebase onto the LANDED Inc 1
Read `$SP/briefs/BRIEF_common.md` (note: the MAIN CHECKOUT is now `main` at a3c1513 = Inc 0 + Inc 1 LANDED, built),
then from the repo record dir `docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/`:
`briefs/BRIEF_review_inc2_r1.md`, `impl_inc2.md`, `fix_inc2_r1.md`, `review_inc2_V1.md`, `review_inc2_V2.md`; then on
the rebased branch `docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1 (esp. §1.11 "what
worries me"); then `$SP/progress/rebase_inc2.md` (the conflict table and the gates re-run after the rebase); then
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 (the C-1 rounds — the in-loop discharge machinery Inc 2's merge out-rails now
meet). Agent name: `review_inc2_r2`. Model: opus. READ-ONLY (write only under `$SP/progress/review_inc2_r2_work/`).

## Binaries (name every path you use)
SUBJECT = `$SP0/wt/inc2` at 6ee3ea3 (Inc 2 rebased onto a3c1513; build current — verify with `find … -newer`).
INC-1-ONLY = the main checkout `/Users/sorenwilkening/Desktop/CQ_lang` at a3c1513 (built 05:20; verify). ORACLE =
`$SP0/wt/pre-3qlq` (52d7764, the pre-3qlq route surface — the value-arm cswap route + register `cq_phi`).
Control the harness (clean + known-bad) before trusting a number.

## The questions
1. **The increment's own reviewer flag, re-asked after Inc 1:** `emitSelectRegion` is now reachable from the value
   diamond with inputs `classifySelectRegion` would refuse — before Inc 1 the named class was "coherent Rz-lineage
   operands" (derived bases whose lineage carries a `cq_phi`). After Inc 1 `cq_phi` is register-free and no Rz
   lineage exists. So: enumerate what `classifySelectRegion` STILL refuses that the br-value classifier accepts
   (derived bases, aliases, fp bases, i1, and the NEW coherent operand class: a KICKBACK-PHASED register — a
   register whose branch carries a kickback phase: is copying it through `cqrt_copy_<W>_controlled` sound? It is a
   basis-label copy; the phase rides the amplitude, not the label — argue it and MEASURE `if (q==5) cq_phi(θ);
   if (c) p = R(p);` with `p` entangled with `q`, and the reverse order, on all three binaries), and for each
   construct the program, run on all three binaries, argue the unitary.
2. **The rebase itself:** re-run Inc 2's four twin gates and the 14-accept injection matrix on the rebased binary;
   confirm the value path emits no `cqrt_cswap` (census: `AbortParkEmit` only — grep + a full-corpus sweep of
   `ir-pass/test/*.ll` outputs) and no `!cq.branchphase` mark lands on a value-path gate (`#cqrt_rz_i1 ==
   #!cq.branchphase` per fixture, tree-wide); every fixture output that is NOT a value-path fixture is
   byte-identical between INC-1-ONLY and the SUBJECT (a `fxdiff` sweep of all 1673+ fixtures on both `cq-opt`s —
   list the movers; every mover must be a value-path fixture Inc 2 re-derived).
3. **Value arm + kickback interplay (new since Inc 1):** a kickback and a value diamond on the same register in
   sequence (both orders), in one loop body, a value arm whose condition is a compound tree (P3's `CondTreeEmit` is
   shared with `SelectMergeEmit` — the value merge uses the SAME network emitter: byte-identity between a `?:` with
   an `&&` condition and the diamond with `&&`), a switch with value arms + a kickback case (mixed → must decline),
   a kickback inside a value arm (mixed → must decline), a value arm inside a kickback nest (must decline).
4. **The dirty chain-final class (F-V1-4/F-V2-3) meets the C-1 machinery:** the leaked `R(p)` chain-final rail is
   left ALLOCATED and ENTANGLED with `out`. Can it be read by a later kickback's strip, by the Inc-1 in-loop
   discharge, or by the C-1 rounds' new paths? Specifically: (a) `invariantRegisterRoots` clause (ii-b) admits a
   control-owned merge out-rail as an invariant root — a VALUE-merge `out` rail IS one: a per-bit kickback loop
   whose condition reads `out` (with and without a carried register) — rolled == unrolled? and is the chain-final
   rail ever discharged or freed as a side effect (it must not be: it is entangled)? (b) the C-1 round-2/3 preheader
   commit (`commitOutOfLoopInPlaceOps`): a preheader `out = out + 7` on a value-merge out-rail before such a loop —
   committed in place? tripwire? (c) `ClaimedRailRoots` with a value-merge rail carried in a loop (`out =
   cq_theta(out,.1)` in the body). (d) a value diamond INSIDE a classically-bounded loop (must still decline —
   confirm the loop decline string) and the mixed loop with a value region in the body.
5. **§1.11's other worries:** the `ArithLowering` G6/G7 "weak tripwire" the merge's two-distinct-copy-sources
   property rests on — attack it with the C-1 rounds' new `InPlaceRailOps` writers in mind (a preheader commit on
   a value-arm BASE `p` before the diamond: does M-C now lower `p+7` in place and make the two copy sources ONE?);
   `forwardConsumerCount`'s fan-out bail keeping `p` alive (construct a `p` with exactly one consumer after the
   merge); V3's switch value path with a kickback-phased scrutinee.
Grade: `CONFIRMED-MISCOMPILE` / `LEAK` / `OVER-DECLINE` / `DOC` / `CLEAR`. Write `$SP/progress/review_inc2_r2.md`
(findings F-I2-k, reproducers under `$SP/progress/review_inc2_r2_work/`, what you ran, verdict line
`CLEAR` / `CLEAR-WITH-ITEMS` / `FINDINGS`). Return it as your final message.
