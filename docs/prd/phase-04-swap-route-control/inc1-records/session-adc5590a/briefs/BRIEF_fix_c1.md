# BRIEF_fix_c1 — the C-1 FIX ROUND on 3qlq Inc 1 (the clearance BLOCK), bounded
Read `$SP/briefs/BRIEF_common.md` first. Then, from the repo record dir
`docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/`: `clearance.md` IN FULL (§2.2 is your
subject; §2.3, §4, §5 are the rest of what is owed), `fix_r1.md` (the F-L5-1 fix — `invariantRegisterRoots` —
and its own progress discipline), `fix_r2.md` (F-R1-1 — clause (ii-b) + the second collapse pass; its
mutation-validation pattern is the one to repeat), `briefs/BRIEF_fix_r2.md` (the shape of a fix brief that
worked), and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2's ⭐ once-only-stage table. Then the code: read
`ir-pass/src/LoopLowering.cpp` lines 2780–3200 COMPLETELY (the `invariantRegisterRoots` header comment, its
clauses (i)/(ii)/(ii-b)/(iii)/(iii-b), `markIfRailLocal`, `collapseFlattenedLoopRails`), the
`collapseRailPhisIn` return contract at ~2431–2540 and its step (4) at ~2672–2690 (what a `Collapsed` return
leaves behind: the rail phis are RAUW'd to their root mints and ERASED), and the consumers of
`taint.IterationLocalBlocks` in `ir-pass/src/Uncomputation.cpp` and `FreePoint.cpp` (grep
`IterationLocalBlocks`, `canRepeat`, `TermIterLocal`, `ControlOwnedRails`).
Agent name: `fix_c1`. Model: opus.

## Where you work
Create worktree `$SP/wt/fix-c1` on a NEW branch `3qlq-inc1-fix-c1` from `3qlq-inc1` (542d588):
`git -C /Users/sorenwilkening/Desktop/CQ_lang worktree add $SP/wt/fix-c1 -b 3qlq-inc1-fix-c1 3qlq-inc1`.
Configure + build there IN THE BACKGROUND (BRIEF_common "Build"; log to `$SP/progress/fix_c1_build.log`) — do
the reading and write the red fixtures while it builds. PRE-FIX SUBJECT = the main checkout's binary
(542d588, never rebuilt). ORACLE = `$SP0/wt/pre-3qlq`. Copy `$SP0/progress/clearance_work/run.sh` to
`$SP/progress/fix_c1_work/run.sh` and add a 4th case `fix` → your worktree's build. Put reproducers under
`$SP/progress/fix_c1_work/p/`, outputs under `.../out/`.

## C-1 — what is wrong (clearance §2.2; reproduce it FIRST on the pre-fix subject, do not trust the record)
```c
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
```
(`clearance_c1/d1i_mixed_invariant_interf.c`; its hand-unrolled twin `d1iu_…_unrolled.c`; both traces are
committed beside them.) ROLLED on 542d588: `opt` exit 0, verify-clean, STRICT 2b `0 violation(s)`,
`cq_template_and_i32_hl` **3 / `and_i32_hl_unc` 0** — three entangled which-path records of `q`'s bits live
through `cqrt_ry_i32(h0, 0.9)`. UNROLLED: 3/3. The pre-3qlq ORACLE on the old-surface twin
(`$SP0/progress/clearance_work/p/d1o_*.c`, `d1ou_*.c`): rolled == unrolled, 37 = 37. A REGRESSION against the
oracle of exactly the class round 1 (F-L5-1) and round 2 (F-R1-1) graded CONFIRMED MISCOMPILE.

ROOT CAUSE (`LoopLowering.cpp:3164–3179` + `:2877–2887`): `collapseFlattenedLoopRails` calls
`collapseRailPhisIn`, which returns `Collapsed` for `r`'s header phi with `Roots = {r's mint}`, and then hands
`markIfRailLocal` ONLY those roots. `markIfRailLocal` reads `%q` (defined outside `L`, tainted, not `onRail`)
and refuses — "an accumulating loop-invariant tainted input" — so NOTHING is marked and the body's `and`/`lshr`
temps are never discharged. `invariantRegisterRoots` (the F-L5-1 fix that would have admitted `%q`) is reached
ONLY on `NotClaimed`, and its clause (i) refuses any tainted header phi anyway. The mixed loop is served by
neither path. **The fix's own proof already covers `%q`**: clause (ii)'s argument is that a ROOT MINT lowers to
`cqrt_alloc_<W>` + `cqrt_ry_<W>` and fails `ChainWalk::isInteriorTerminalHandle` clause (I1), so it can never
be the PREHEADER forward gate whose `At` lands in the K-times body — a property of the ROOT, not of whether
some OTHER register crosses the back edge.

## The fix — option (a), the capability (Rule 17: this is inside P6's target shape and D4's own idiom)
In `collapseFlattenedLoopRails`, on `Collapsed`, ALSO admit the loop-invariant ROOT MINTS (and clause (ii-b)
control-owned merge out-rails) beside the carried roots before `markIfRailLocal`, on the identical (I1)
proof. Design constraints you must respect (each is a hazard measured in this file's history):
1. **A SEPARATE candidate set, then union.** `invariantRegisterRoots` fills `RootsOut` INCREMENTALLY and can
   return `false` after inserting some roots (`:3010` `RootsOut.insert(Root)` inside the loop). Never let a
   failed extension pollute the carried `Roots` that `markIfRailLocal` is then called with — compute the
   invariant roots into a TEMP set; on success union it into `Roots`; on failure call `markIfRailLocal` with
   the carried roots ONLY, i.e. today's behaviour, byte-identical (measure that: every pre-existing accept
   fixture and golden must not move).
2. **Skip the candidates the collapse already owns.** After `Collapsed`, the body reads `r`'s ROOT MINT
   directly (the phi was RAUW'd to it), so `%r0` is a `Cand` whose in-loop user IS an in-place gate — clause
   (iii) would refuse it and the whole extension with it. A candidate whose `peelInPlaceBase(…, AsLowered=true)`
   is already in the carried `Roots` is the collapse's business and must be SKIPPED, not judged. Spell that as
   a parameter (`const SmallPtrSetImpl<Value*> *CarriedRoots`) — one function, one spelling, Rule 14; do not
   copy the clause list.
3. **Clause (i) after a collapse.** State in the comment (and MEASURE by reading `collapseRailPhisIn`) that
   `Collapsed` implies ZERO tainted header phis remain (step (4) erased them) — so clause (i) still holds
   post-collapse, and `markIfRailLocal`'s own `TI && isa<PHINode>(I) && BB == Header` refusal is the second
   fence. If `Collapsed` can leave a tainted header phi behind (a rail the collapse did NOT claim while
   claiming another), that is an OWNER QUESTION and the extension must refuse that loop.
4. **Q-R1-1 stays refused, byte-identical.** A hoisted loop-invariant TEMPLATE rail (`int p = q*3;` / `long p = q;`
   / `int p = q+r;` before the loop — `$SP0/progress/clearance_work/p/{d2,d3,b7}_*.c`, and the mixed spelling
   `int p=q*3; for(){ if((p>>i)&1) cq_phi(θ); r=cq_theta(r,.1); }`) must still NOT be marked and must produce
   the SAME trace as on 542d588 (the leak, Prime-Directive direction). Pin the mixed spelling as a CONTROL
   fixture (an accept whose `UCNT`/whatever prefix asserts the `and_unc` count is what 542d588 emits — i.e. it
   pins that the widening did NOT reach it). Do NOT widen (ii) to template rails — that is the owner's Q-R1-1.
5. **The two collapse passes.** `collapseFlattenedLoopRails` runs at round 1 and again over the round-2
   DELTA (`AlreadyProcessed`). A loop that was `Collapsed` at round 1 has its phis ERASED, so a round-2 re-offer
   of the same loop (an onward region opening inside it) returns `NotClaimed` and then sees `%r0` with an in-body
   in-place gate → `invariantRegisterRoots` false → nothing new marked, while the ROUND-1 MARKING STANDS
   (Q-R2-1: marking only grants). Construct that program (mixed loop + an onward 6.5 `%out`-conditioned
   kickback in the SAME body — see `control_phase_kickback_onward_inloop.ll`'s header for the two-TU recipe),
   measure rolled vs unrolled on your binary, and record the disposition. If it leaks or is wrong, that is a
   finding to fix in the same round (the once-only-stage class, notes §2 table) or an OWNER QUESTION.
6. **The 8h7d.5 question, answered in writing** (in the notes §3 and the hand-back): the closure you widened
   is "the Roots `markIfRailLocal` treats as THE REGISTER". What OTHER sets/predicates are computed over
   that closure? At least: `markIfRailLocal`'s `onRail`/`AnyLocal`/escape test; `Uncomputation.cpp`'s
   `IterationLocalBlocks` consumers (`canRepeat`, the §4/§2.9 multiplicity pair — re-derive the preheader-gate
   vs body-`At` multiplicity for a root that is now admitted BESIDE a carried rail: can a carried rail's
   recovered gate in the preheader pair with an `At` in the marked body?); `FreePoint`'s `TermIterLocal`;
   `staleRailRecordRead` (step 2b) — does admitting `%q` create a rail RECORD read the collapse's proof did
   not cover (the post-loop `q = cq_theta(q, .9)` and the body's reads of `%q`)?; `ControlOwnedRails`;
   `railGateBetween`/`collectRailGates` if either touches Roots. For each: the answer, and the mutation or
   program that MEASURES it.
If, after doing the work, the (I1) argument does NOT carry for the mixed shape, do NOT ship a silent leak and
do NOT quietly narrow: write the OWNER QUESTION with the measurement, and ship option (b) — a LOUD decline of
the mixed shape at the P6 admission (`classifyPhaseKickback` step 7 or wherever the in-loop admission lives),
string mirrored by a fixture — as the interim. Say which option shipped in the first line of the hand-back.

## Red-green (Rule 12) — write these RED first, against the pre-fix subject
- `ir-pass/test/control_phase_kickback_mixed_invariant_carried_inloop.ll` — ACCEPT: `d1i`'s `clang -O1` module
  (keep `!llvm.loop` verbatim, drop `@main`), `UCNT-COUNT-3` of `cq_template_and_i32_hl_unc` INSIDE the body,
  the `lshr_hl_unc` likewise, counts in their OWN prefixes, `NOROUTE` pure-negative whole-file (no `cqrt_cswap`,
  no `cqrt_rz_` at any width but `i1`, no `_controlled`), handle names DERIVED from the pass output, and the
  `#cqrt_rz_i1 == #!cq.branchphase` pin (`MDCNT`). Model it on `control_phase_kickback_onward_inloop.ll`
  (header truth: say what was wrong, where, and the witness). RED on 542d588 (count 0), GREEN on yours.
- The Q-R1-1 CONTROL fixture from constraint 4 (`..._reject_…` is the wrong name — it ACCEPTS and LEAKS;
  name it `control_phase_kickback_mixed_hoisted_template_leak_control.ll` or similar, header says exactly what
  it pins and why the leak is the Prime-Directive disposition until Q-R1-1 is ruled).
- A DECLINE fixture for whatever the extension REFUSES loudly, if anything does (if option (b) ships, this is
  its mirror). If every refusal in this path is a silent non-marking (a leak) rather than a diagnostic, say
  so explicitly in the hand-back and pin the leak-controls instead — do not invent a diagnostic.
- e2e: `tests/e2e/slice_control_phase_perbit_loop_mixed.c` (= `d1i`, with a header in the style of
  `slice_control_phase_perbit_loop.c` saying what it measures and why it exists) + `…_mixed_unrolled.c`
  (= `d1iu`), both goldens generated by the FULL pipeline on your binary with STRICT 2b, registered in
  `tests/e2e/CMakeLists.txt` beside the perbit block (line ~4596) plus the `cmp` twin gate
  `e2e-phase-perbit-loop-mixed-twin-identical` (line ~4676 pattern). Confirm the rolled golden is
  BYTE-IDENTICAL to the unrolled one AND to `clearance_c1/d1iu_mixed_invariant_interf.subj.trace`.
- **The B3 fixture** (clearance §4 (i) / §5.2): `ir-pass/test/lowering_reject_break_phase_answer_kickback.ll`
  from `clearance_c1/f1_break_kick_before.subj.s1.ll` — `RUN: not … | FileCheck` mirroring
  `cq loop lowering: early break preserves a phase answer` (`LoopLowering.cpp:108`), header quoting the plain-C
  source `f1_break_kick_before.c`. Measure that it declines with THAT string on 542d588 and on your binary
  (the clearance says it does; the r1-subject declined on an earlier fence). Beside it, its discriminating
  control: `f3_break_global_phase_before.c` (`$SP0/progress/clearance_work/p/`) ACCEPTS byte-identical to the
  plain break loop — pin it as an accept fixture so the post-dominance clause is a discriminator, not a wall.
  Leave `lowering_reject_break_phase_answer.ll` (which now pins Q1's string) as is.

## The C-1 POPULATION — rolled == unrolled on EVERY member, on your binary (the witness), all STRICT 2b
From `$SP0/progress/clearance_work/p/`: `d1`/`d1u` (no diffusion), `d1i`/`d1iu`, `d1c`/`d1cu` (`r ^= 9`),
`d1k`/`d1ku` (kickback on `r` too), `d11`/`d11u` (P3 tree `((q>>i)&1) && r==3`), `d1w` K=32 (rolled only —
count 32/32), `d1d` (q DEAD — record the disposition: root + rails, nothing freed dirty), `d1m`/`d1mu`
(direct compare on the invariant register — unaffected, still drbq.12's over-decline; confirm), `d7`/`d7u`
(two invariant registers — already handled by the NotClaimed path; must not move), `d9`/`d9u`, `d12`,
`e5`/`e5u`, `d4`/`d4u`, `d5`/`d5u`, `d6`/`d6u`, `d10`/`d10u`. Plus NEW spellings you write: the carried register
as an `add`/`xor` in-place chain with a record read; TWO carried registers + one invariant; the invariant
register measured INSIDE the body; the invariant register's per-bit condition on a SEXT/ZEXT of `q`
(a cast is a template rail — must stay a leak-control, NOT discharged); K=1; the carried register's gate
BEFORE the kickback in the body; a kickback on `r` whose condition is derived (`(r>>i)&1`, carried + derived).
Put the whole table (name, subj-542d588 counts, fix counts, unrolled counts, 2b, IDENTICAL yes/no) in the
progress file and the notes.

## The twin matrix axis (clearance §4 (ii): the matrix has NO second-CARRIED-register axis, which is why 274 cells could not see C-1)
`tools/loop_twin_matrix.py`: add a small sub-grid (aim ≤ 24 cells; the gate is already the suite's long pole
at ~400 s, and `cells_of_matrix` ASSERTS the sub-grid sizes — update the assert and the docstring) in which the
condition register `a` is loop-INVARIANT with a DERIVED per-bit condition (D4's idiom) and a SECOND register
`r` is loop-CARRIED (gated per trip: `cq_theta`, in-place `add`/`xor`, a kickback on `r`, with/without a
post-loop diffusion on `a`). Reuse `_wrap`'s `second` plumbing (read its docstring: `r` appears iff the region
is an `RY_REGION` one — extend that predicate deliberately and prove the existing 274 cells' generated sources
are BYTE-UNCHANGED by diffing every generated source before/after your edit, as prep-d did). Run the matrix
on YOUR binary in the background (`--phi-surface void`, `--regenerate` for the expected table); every new cell
must be IDENTICAL; if any new cell diverges it is either C-1's residual (then it is a fix, not a quarantine)
or a new class (then an OWNER QUESTION with the signature — never a silent quarantine). Run
`e2e-loop-twin-quarantine-selftest` (0.2 s) after.

## Docs (in your tree, same commits)
- PRD §0 ERRATA E2: today it says "the row is now correct … ⚠ Two things the fix does NOT cover". Rewrite the
  paragraph so it records: THREE things it did not cover at clearance; the third (C-1, the mixed loop) was a
  BLOCK and is FIXED in this round (how, and the witness); the two Prime-Directive residuals stay, and the
  Q-R1-1 sentence now says "ANY loop-invariant TEMPLATE rail (a cast, a Q+Q op, an onward `mul`)", not only
  `q*3` (clearance §2.3).
- `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3 — the clearance + the C-1 fix round**: the BLOCK verdict in one
  paragraph, C-1's root cause, the fix, the answer to the 8h7d.5 question (constraint 6's table), the
  population table, the B3 fixture and its plain-C reachability, what the matrix axis can now see, what you
  ran (only that).
- `CLAUDE.md`: the in-loop paragraph under CORRECTNESS RISK ("An in-loop kickback leaked one ENTANGLED
  which-path rail per activation … Fixed by `LoopLowering::invariantRegisterRoots` …") gains ONE sentence
  naming the mixed shape as the clearance's third instance and where it is fixed. Keep it to one sentence;
  the orchestrator does the wider docs pass.
- The `invariantRegisterRoots` and `collapseFlattenedLoopRails` header comments: the new dispatch, the
  CarriedRoots skip and WHY (constraint 2), and the (I1) argument restated for the mixed case.

## Verification you owe (only what you ran, with commands)
- Red-green per fixture against 542d588 (RED) and your build (GREEN), commands in the progress file.
- The population table above (3 binaries where a spelling exists: 542d588, yours, and the oracle on any
  old-surface twin you write).
- `ctest -R ir-pass-lit` on your build in the BACKGROUND → 0 reds outside your own new files (the standing
  XFAIL `lowering_invert_add_i32.ll` stays). Then `ctest -R '^e2e-slice-control-phase-perbit'` + the new
  twin gate + `e2e-loop-twin-quarantine-selftest`; the twin matrix in the background.
- Mutation validation of the fix, one half at a time (the fix_r2 pattern): disable the skip of constraint 2
  → the mixed accept fixture must go RED; disable the union → RED; re-enable → GREEN. Record the three cycles.
- The injection matrix over your new ACCEPT fixtures (`$SP0/progress/clearance_work/inj.py` or fix_r2's
  harness, re-pointed): 0 MISSED, 0 DIRTY, with the clean + known-bad controls.
- STRICT 2b on every accepting reproducer.
Commit per logical step on `3qlq-inc1-fix-c1`. Hand back per BRIEF_common: first line = which option shipped
and the C-1 rolled/unrolled counts on your binary.
