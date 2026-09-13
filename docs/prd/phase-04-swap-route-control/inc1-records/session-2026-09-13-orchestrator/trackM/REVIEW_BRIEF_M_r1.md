# Rule-13 review brief, round 1 — Track M (bd `boi6` D-B, `8xaw`): the REGION-MERGE-φ rail leaf for the 4.4 DATA SELECT

Written 2026-09-13 by the orchestrator. Model: opus. Worktree `/Users/sorenwilkening/Desktop/CQ_mphi`, branch
`mphi-rail-leaf` (base `main` 8659a77), `build/` current (`cq-opt` sha256 `ae216b3727f5b1ec…` per `GATES.md`
— your ONE build-side obligation is `shasum -a 256 build/ir-pass/cq-opt` matching it). Protocol:
`../PROTOCOL.md`, row "review": **NO build, NO suite**; `GATES.md` is fact for that hash (`ir-pass-lit`
1907/1 XFAIL/0; injection 56 mutations 0 MISSED; corpus 2696 rows 21 DECLINE→ACCEPT + 3 string moves, 0
regressions, 0 both-accept IR changes); at most ONE fixture re-run. ORACLE
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (`fbbe0820…`, read-only). Do not edit
`ir-pass/`, `include/`, `tests/`, `tools/` anywhere. Read in order: `BRIEF_M.md` (the decisions), the
orchestrator's H-6 ruling (IMPL_M.md §7.4 / the `_sdagger` fixture header), `IMPL_M.md` (ALL — §1 sites, §2
H-1's counterfactual, §3 the rungs + H-6, §4/§4c, §5 the traces read line by line, §6 corpus, §7),
`SCOPE_M.md` (§0.3, §0.4 T1, §1 the 24-site table, §2.1, §3 H-1..H-10, §4), `GATES.md`, `probes/README.md` +
`probes/impl/`, the diff (`git diff -- ir-pass`) and the new fixtures/slices (`git status --short`),
`CLAUDE.md` (Prime Directive; Rules 1, 6, 7, 8, 12, 13, 14; CORRECTNESS RISK §1 the r9e5 row, §2 the rail
ladder, §3 L1/L2/L4/L9, §4, §5 `3d8q`).

## What changed

Grammar: `CondTree::RailPhiLeaves` + `isCondRailPhiShape` + `AllowRailPhi=false` (`SelectClassify.h`),
ROOT-ONLY φ arm in `collectCondTree` (`SelectClassify.cpp:642`), rung 0 `preppedRailPhiRegion` (`:483`) =
`R.Kind == BranchRegion && R.Merge == P && (ClassArm || ClassArmFalse) == InPlaceRotation && !Shadow.empty()`
— **the `RailLadderProven` conjunct was DROPPED** (orchestrator item 2: a compare-conditioned prep + a select
on its output, `i2_cmpladder`, was refused by that conjunct alone; now ACCEPT 21 lines), rungs (i)/(ii)
over `condProvenance(P)` (`:975`), gate 2c seeded from the φ into `RailProv` (`:1094`), `RailLadderProven`
(`:1270`). Emitter: `SelectMergeEmit.cpp:150/:271` re-read the condition off the select (H-1; the reverted
line makes the accept a `control flow` decline, ×3 — the emitter was walking the erased φ);
`RegionFlatten.cpp:108/:205/:210`; `Specialization.cpp:304`; `ArmClassify.cpp` 0 lines; `CondTreeEmit.cpp`
0 lines. Customers: the owner's file 29 lines = T1; `m16` run-time `a` 31 lines (3 frees); `i2_cmpladder`
21; `_uncond` 28; `_int` 28; `va` 19 unchanged; `U1_owner_regfree_phi` (`if (b1 == 0)`) 29. H-6 ruled ADMIT
(`m15` = a CHAINED S† on the condition's own name; `m15u` rail spelling accepts on the ORACLE at 29). 7
`NOROUTE-NOT: phi` fixtures re-anchored. Two `compare_files` gates (base-prefix 16 lines; twin 10-line
select half after a rail rename), each attacked with 5 mutants.

## Where to look — over-ACCEPT is the unforgivable bug; grade over-DECLINE too (owner ruling)

1. **The state vector of every accept, re-derived from the stage-1 IR, not from the record.** The owner's
   file (29): `h1` is a PREPPED register (`Ry(.5)|0⟩` on `b0=0`, `|0⟩` on `b0=1`); the CNOT copy
   `cnot(h1,h7)` on a `|0⟩` ancilla — basis-faithful; the two X-bracketed `copy_i32_controlled` write
   `out = y ? a−3 : a`; un-copy returns `h7` to `0` on every branch. Then `m16` (run-time `a`, 31 lines, 3
   frees) — name the three freed rails and prove each `|0⟩` at its free; `i2_cmpladder` (21) — the prep
   is under a COMPARE (flag minted and stripped in the pred) and the select's CNOT reads the prep output:
   is the compare flag's strip ordered BEFORE the select's gates in the stream, and does the prep's M-β
   target (the hoisted theta) dominate the select's insertion point? Then `_uncond`, `_int`, `U1`, the
   `_sdagger` (30) fixture.
2. **Dropping `RailLadderProven` from rung 0.** The conjunct answered "did the RAIL ladder run for the
   region"; the replacement relies on `ClassArm == InPlaceRotation` meaning "M-β will RAUW this φ to a
   theta call". Find a region claimed `InPlaceRotation` whose merge φ M-β does NOT RAUW to a `cq_theta_i1`
   CALL: the un-negated true-edge prep (target `T`, not `TNeg` — a call, fine); an in-place ARM (not a
   prep) on a register `r` disjoint from the condition — `if (b0) r = cq_theta(r,.5); if (r) …` where `r`
   is `_Bool`: the merge φ is `[theta, r_old]` — M-β RAUWs to the hoisted theta which is CHAINED on `r_old`
   — is that φ a legitimate rail leaf (one wire) and does rung (ii)/(iii) over `condProvenance(P)` see
   `r_old`'s reads? the `i32`-width in-place arm (`int r`) whose merge φ is `i32` — `isCondRailPhiShape`
   requires `i1`, confirm; the ANGLE-SELECT region kind (folded if/else angle) — is its `ClassArm`
   `InPlaceRotation`? if so its merge φ must NOT be admitted (which field distinguishes it?); a region with
   BOTH `ClassArm` and `ClassArmFalse` set; the 4.5 switch; the in-loop rolled prep (must be refused before
   rung 0 — which fence?).
3. **Emission ORDER and block lifetime (L9).** Rung 0 admits the φ at classification; `lowerControlRegions`
   emits in Kahn/plan-index order. Construct: the select in the merge block FOLLOWED (same block) by a
   THIRD region's `br` on `b1` or on `a` (the merge block's terminator is classified BEFORE the block's
   selects — `ControlDetect.cpp` block order — so plan index = [prep, region3, select]): does region3's
   pred-hoist land BEFORE the select's gates in the stream, and is that source order? (`if (b1) a -= 3;
   if (a == 2) cq_phi(.3);` and `if (b1) a -= 3; if (b1) cq_phi(.3);` — the second is the filed `3qps`
   leaf-grammar decline; confirm the first's ORDER in the trace against source.) Then the reverse: a
   region whose merge block hosts TWO selects on the φ (`m07`-style, `a -= 3; a += 2` — did the ORACLE
   accept it only because of ±… folding? measure the subject's stream and its order).
4. **H-1's fix is a re-read, not a check.** After the prep's flatten the φ is erased; the select's
   condition operand now IS the theta call. But `R.Condition` (raw, dangling) is still stored in the plan
   — grep every OTHER reader of `R.Condition` for a `SelectRegion` (`RegionFlatten`, the alias loop in
   `lowerControlRegions`, `declineClassicalMuxes`' region view, `reverifyRailCondReads`' record — the
   `markRailCondRead` at `CondTreeEmit.cpp:248` records WHICH value: the re-read theta call (good) or the
   plan's dangling `Condition`?). A read of freed memory that happens to compare equal is a Release-build
   silent hazard, not a crash.
5. **The round-2 window (L1) through the select.** Construct the 9pum two-TU window: `b0` derived from a
   6.5 `%out`; the prep on `b1` under `b0`; the select on `b1`. Round 1: `%out` untainted ⇒ the prep region
   is NOT claimed in round 1 ⇒ the select's rung 0 finds no region ⇒ `control flow` decline in round 1
   (LOUD, before round 2 ever runs) — is that what happens, or does round 1 skip the select and round 2
   see a claimed region? Either way no silent path — but confirm the STRING and that no accept sneaks
   through with the φ unlowered (SCOPE §2.2 (b2): a surviving tainted-condition select is declined by
   nothing and crashes in `lowerRotations`).
6. **`3d8q` customers.** `p3d8q_sibling{,_rail}.c` accept on the subject (31/30); the rail one accepts on
   the ORACLE — pre-existing P1 hole. Confirm, and add the φ spelling to bd `3d8q`'s reproducer list in
   your report; do NOT grade it as this increment's over-accept, DO grade any NEW shape that the φ
   admission reaches and the rail spelling does not.
7. **Over-declines met in passing** (`m15i` compare/rail DT-prong asymmetry; `m31` ROOT-ONLY; `p20` → the
   wire fence — is `p20`'s decline correct? its arm theta is CHAINED on the condition's own wire: the
   register the select reads was rotated in place by the arm — the source reads the post-rotation
   basis, which is what the CNOT copy after M-β would read too… argue whether `p20` is a genuine wire
   hazard or an over-decline, from the state vector); grade each.
8. **Every accept: `-O1` reachability + state vector; every decline: is the circuit invalid?** Plain C
   first; every fixture's `CHECK` counts against the subject's real output (one spot-check allowed).

## Method

Scratch `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/ddf48412-8498-4d8b-9bac-51279fb090c0/scratchpad/trackM_review/`;
SUBJECT vs ORACLE per probe; grade CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC;
verdict BLOCK / CLEAR-WITH-ITEMS / CLEAR. Report `review_M_r1.md` beside this file, probes
`review_M_r1_probes/` with a runner. Final message ≤30 lines: verdict, findings one line each with grade +
reproducer, items 2 (which `InPlaceRotation` regions' φ M-β does not turn into a theta CALL), 3 (the
emission-order result) and 5 (the round-2 string) answered explicitly.
