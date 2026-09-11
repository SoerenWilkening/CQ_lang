# Rule-13 review brief, round 1 — Track A.1: the compare-select FENCE PARITY (bd `9pum` + `r10v` + `r903`(b))

Branch `compare-select-parity` (off `main` 0c7380c), worktree `/Users/sorenwilkening/Desktop/CQ_trackA`,
`build/` current (DO NOT rebuild; DO NOT edit `ir-pass/`, `include/`, `tests/`, `tools/`). Tree under
review: `IMPL_A1.md` beside this file (read its §7 open questions O-1..O-7 FIRST — the implementer flagged
O-7 and O-3 as the places to attack). ORACLE: `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
+ `libCQPass.so` (main 0c7380c, read-only). Gates already run by the implementer: `ir-pass-lit` Passed
(1795/1794+1 XFAIL), `^e2e-` 379/379, full `ctest -j6` 388/389 with `e2e-loop-twin-matrix` red on
contention (6 `exited -9` under load 113–140) and Passed alone (1012 s), `cq-opt-equivalence-full` 1796
fixtures 0 mismatches. You need not re-run the full suite; re-run `ir-pass-lit` and whatever you touch.

## What changed (`git diff main -- ir-pass/src ir-pass/include`; 156 non-comment lines)

This increment is DECLINE-ONLY by intent: the three plain-C reproducers below ACCEPT on the oracle and
DECLINE on the subject, and the corpus diff over all 1776 `main` fixtures is `0 RCDIFF · 0 DIAGDIFF ·
0 OUTDIFF`; 8 probe-corpus movers, all ACCEPT→DECLINE.

* `r10v`: `int b = cq_theta(0,.5); for (i<3) { int a = (b == 1) ? i : 5; acc += cq_measure(a) + cq_measure(b); }`
  → `condition measured before the control route` (oracle: trip ≥2 mints `icmp_eq(h0,1)` after
  `cqrt_measure_i32(h0)`).
* `r903`(b): `int m = cq_measure(q); if (q > 3) cq_phi(.3);` → same string (oracle: mint after measure).
* `9pum` (two TUs, `session-r9e5/review_b1_r2_probes/multi/e13_*`): `y` a 6.5 `%out` derivative, `b =
  cq_theta(y,.25); b3 = cq_theta(y,.9); a = (b==1)?2:5;` → `condition predates a non-diagonal gate` (oracle:
  the flag minted from the post-`.9` register).

Mechanism:
1. `railWireNamesBackward` / `railMeasuredBeforeReadPoint` seed widened `CallInst*` → `Value*` (one
   spelling for rail and compare seeds; names kept — O-1).
2. **Rung (ii) gained a PER-ACTIVATION BARRIER** (`ArmClassify.cpp:1967/1999`): the wire ORIGIN is admitted
   as a barrier only when it is a SOURCE theta; without it 5 shipped in-loop accepts moved (an
   iteration-local register is re-minted each trip). **This is an ACCEPT-direction widening of a
   Rule-13-core predicate inside a decline-only increment — O-7 — attack it first.**
3. `condCmpMeasuredBeforeReadPoint` (`:2033`) called at `SelectClassify.cpp:867` (read point `Sel`) and
   `ArmClassify.cpp:4483` (read point `Pred->getTerminator()`); seeded from the `condProvenance` CONE, not
   the direct operands (O-2). `condDataUseDisposition`'s `MeasuredEarly` untouched.
4. `TaintSet::CmpCondReads` + `markCmpCondRead`, written INSIDE `lowerCompareToFlag`
   (`CompareLowering.cpp:304`) under `recordCondRead`, default TRUE — 19 call sites / 8 files IN;
   OUT: `Specialization::mintCondNetwork` (writes `cloneTaint` — O-5), `rewriteCompare` (explicit false),
   `Switch*Emit` (mint via `emitEqFlag`, no `CmpInst` — O-4).
5. `reverifyCmpCondReads` (`:2249`) at `CQLoweringPass.cpp:440` and `:864` beside the rail twin: rung (ii)
   ungated; **rung (iii) asked only when taint-aware DIRTY ∧ taint-blind CLEAN** (the taint set enters
   `findNonDiagonalWireGate` in exactly one place, the F-1b-1 crossing, so the difference isolates the
   round-2 rail merge). Two rejected spellings are recorded: one-entry-per-cone-member cost 14 in-loop
   accepts; an unconditional rung-(iii) re-ask cost 12 (the flatten + round-2 rail collapse erase the
   barrier phi).

## Where to look

1. **O-7, the per-activation barrier.** The wire origin admitted as a barrier "only when it is a SOURCE
   theta": construct the loop where the origin IS a source theta (`cqrt_alloc` per trip) but the measured
   register is NOT re-minted on every path (a conditional mint; a mint hoisted by LICM as a `cq_theta`
   with an invariant seed — then it is minted ONCE and the barrier claim is false; a source theta in the
   preheader whose value is loop-carried through a phi; a source theta inside a nested loop; an
   irreducible cycle `LoopInfo` cannot see — the drbq S7 lesson). For each: does rung (ii) now ACCEPT a
   control minted from a register a previous activation measured? That is the r10v miscompile re-opened by
   the fix's own widening.
2. **O-3, the stated residual.** "A gate already reachable taint-blind at round 1 whose wire the round-2
   merge then changes is not re-examined, because the flatten erased the positions." Try to build it: a
   compare on a wire that at round 1 already has a taint-blind-reachable non-diagonal gate (so the
   classifier RULED on it positionally — `ProvenPostRegion`, or the DT prong for rails) and whose wire a
   round-2 merge then EXTENDS (a chained theta on a `%out`-derived sibling). If the round-1 ruling was
   positional and the position no longer exists after the flatten, what does the re-ask compare against?
   Measure with two-TU plain C (the `e13` recipe) and hand IR.
3. **The DIRTY∧CLEAN gate on rung (iii).** "taint-aware dirty and taint-blind clean" isolates the F-1b-1
   crossing — but is that the ONLY way round-2 taint can change `findNonDiagonalWireGate`'s answer? The
   walker's forward users, `phiTracksWire`, `gateIsHarmless`, the barrier set — any of them consult
   taint? If a second taint-dependent path exists, the gate suppresses a legitimate re-ask. Also the
   converse: taint-blind DIRTY at round 1 means the classifier already declined — unless the classifier's
   round-1 question was a DIFFERENT walk (the positional DT prong vs the position-free re-ask): a program
   accepted positionally at round 1 (S†-style, `ProvenPostRegion`) whose wire is then extended at round 2 —
   is it re-asked position-free (over-decline of the S†) or not at all (the O-3 residual)?
4. **The cone (O-2).** Seeding rung (ii) from `condProvenance`'s cone instead of the direct operands:
   wider = more declines; but is the cone complete for a compare whose operand is a CAST or an in-place
   `add`/`xor` relabelling of the measured register (the wire, not the name — F-B1R1-1)? `q2 = q + 1`
   in place, `m = cq_measure(q)`, `a = (q2 == 1) ? …` — measured before? And `zext`/`trunc` (out of place:
   a fresh rail — is `q`'s measurement then correctly NOT a decline for a select on the cast's rail? and
   is the cast's rail entangled with the measured `q` in a way that matters?).
5. **The switch (O-4).** `Switch*Emit` mints via `emitEqFlag`, no `CmpInst`, no record: `int m =
   cq_measure(q); switch (q) { case 1: cq_phi(.3); … }` and the round-2 window on a switch scrutinee. The
   implementer's probe declined EARLIER on both binaries — find one that does not (a switch shape the
   4.5 classifier accepts) and measure both rungs there. If the switch has the same hole, it is a
   pre-existing finding to FILE, not a blocker — say which.
6. **`mintCondNetwork` (O-5).** A specialised clone whose condition tree mints compares with no record:
   a rail/compare condition inside a `@__cq_q_*` body with a measured-before or a sibling theta in the
   caller — measure.
7. **Over-decline audit.** For every new decline fixture, argue the circuit is genuinely invalid
   (post-measure control or a stale name = no-cloning) — any decline of a VALID circuit is a finding under
   the owner's expressiveness ruling. Specifically re-measure: the flat measure-AFTER (accept), a
   measurement of a DIFFERENT register on the path (accept), the onward-classified compare with no sibling
   (accept), the S† after a compare select (this increment must NOT have changed it — it declined on `main`
   and is A.2's), two selects on one compare (whatever `main` did), and every `slice_control_*` golden
   byte-unchanged (the implementer says yes; spot-check 10).
8. **`-O1` reachability**: for every new decline, the plain-C spelling or "hand IR only".

## Method

Read `IMPL_A1.md`, `BRIEF_A1.md`, `probes/README.md`; run the probes and every new fixture on both
binaries; write your corpus under
`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/trackA_review/`
(plain C `-O1` first via `/usr/local/opt/llvm@19/bin/clang -Iinclude -include CQ.h -O1 -emit-llvm -S`,
then `build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S`, link
`libcq_templates.a` then `libcq_runtime.a`, run, `tools/free_pairing_check.py`; two-TU via `llvm-link`
as in `session-r9e5/review_b1_r2_probes/run_multi.sh`; hand IR second). Every accept argued from the
state vector (Rule 2). Grade CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC.
Verdict BLOCK / CLEAR-WITH-ITEMS / CLEAR. Report to `session-9pum/review_a1_r1.md`, probes to
`session-9pum/review_a1_r1_probes/` with a runner. Final message ≤30 lines: verdict, each finding in one
line with its grade, and the O-7 / O-3 outcomes explicitly.
