# review_c1 — independent Rule-13 lens on the C-1 FIX (3qlq Inc 1)

Agent `review_c1`, READ-ONLY on every checkout. Work under `$SP/progress/review_c1_work/`.
SUBJECT (the fix) = `$SP/wt/fix-c1` @ 3ec40c9 (build measured current: `find ir-pass/src ir-pass/include
ir-pass/tools -newer build/ir-pass/cq-opt` -> EMPTY).
PRE-FIX = `/Users/sorenwilkening/Desktop/CQ_lang` @ 542d588 (build current, never rebuilt by me).
ORACLE = `$SP0/wt/pre-3qlq` @ 52d7764.
Harness = my own copy of `run.sh` writing to `review_c1_work/out/` (4 cases subj|fix|r1s|orac).

## Log
- step 0: read BRIEF_common, BRIEF_review_c1, BRIEF_fix_c1, progress/fix_c1.md IN FULL,
  clearance.md, and the fix diff `git -C $SP/wt/fix-c1 diff 542d588 -- ir-pass/src ir-pass/include`
  (+91/-9 in LoopLowering.cpp, +19 in LoopPlan.h; no other source touched).
  Read LoopLowering.cpp 190-300 (peel helpers), 2431-2790 (collapseRailPhisIn), 2790-3260
  (invariantRegisterRoots + markIfRailLocal + collapseFlattenedLoopRails).
- step 1: HARNESS CONTROLLED. `p/ctl_good.c` ACCEPTs 7 lines on subj AND fix; `p/ctl_bad.c`
  DECLINEs `cq rotation lowering: unsupported quantum-derived rotation angle` on both.
- step 2: C-1 REPRODUCED INDEPENDENTLY.
    subj: d1i ACCEPT 2b=0 lines=31, and_i32_hl 3 / and_i32_hl_unc **0**;
          d1iu ACCEPT lines=37, 3/3. DIVERGE.
    fix : d1i ACCEPT 2b=0 lines=**37**, 3/**3**; d1iu 37, 3/3. `diff` EMPTY (IDENTICAL),
          and `diff` rolled(fix) vs unrolled(subj) EMPTY.
  So the fix's headline claim reproduces on my measurement.

- step 3 (my own probe battery, 41 programs through all 3 binaries where a spelling
  exists; `review_c1_work/{p,out}`, `sweep.sh`, `cmp.sh`, logs `sw_subj.log`/`sw_fix.log`).
  ROLLED vs UNROLLED, `cq_template_{and,lshr}_*_hl` mints / `_hl_unc` discharges:

  | probe | subj R\|U | fix R\|U | subj ident | fix ident |
  |---|---|---|---|---|
  | d1i mixed (C-1)          | 3/0\|3/3 | 3/3\|3/3 | DIVERGE(6) | **IDENT** |
  | r1 preheader theta on inv| 3/0\|3/3 | 3/3\|3/3 | DIVERGE(6) | **IDENT** |
  | r3 preheader xor carried | 3/0\|3/3 | 3/3\|3/3 | DIVERGE(6) | **IDENT** |
  | r4 `long` invariant      | 3/0\|3/3 | 3/3\|3/3 | DIVERGE(6) | **IDENT** |
  | r7 `double` carried      | 3/0\|3/3 | 3/3\|3/3 | DIVERGE(6) | **IDENT** |
  | r8 P3 tree, carried leaf | 3/0\|3/3 | 3/3\|3/3 | DIVERGE(6) | **IDENT** |
  | r9 2 invariant + 2 carried|6/0\|6/6 | 6/6\|6/6 | DIVERGE(12)| **IDENT** |
  | r15 carried derived kick | 6/0\|6/6 | 6/6\|6/6 | DIVERGE(12)| **IDENT** |
  | r21 two loops            | 6/0\|6/6 | 6/6\|6/6 | DIVERGE(12)| **IDENT** |
  | r31 onward region FIRST  | 6/0\|6/6 | 6/6\|6/6 | DIVERGE(12)| **IDENT** |
  | **r2 preheader `q=q+7`** | 3/0\|3/3 | **3/0\|3/3** | DIVERGE(6) | **DIVERGE(6)** |
  | **r5 bare `short`**      | 3/0\|3/3 | **3/0\|3/3** | DIVERGE(10)| **DIVERGE(10)** |
  | **r33 onward-only mixed**| 3/0\|3/3 | **3/0\|3/3** | DIVERGE(6) | **DIVERGE(6)** |
  | **r35 = r33 + diffusion**| 3/0\|3/3 | **3/0\|3/3** | DIVERGE(6) | **DIVERGE(6)** |
  | n9 hoisted template (Q-R1-1 control) | 3/0 | 3/0 | — | UNCHANGED |
  | d2 hoisted sext / d3 Q+Q (Q-R1-1)    | leak | leak | — | BYTE-UNCHANGED |
  DECLINES, both binaries, identical strings: r10 tape (`cq I/O output sink: tainted
  argument has continued lineage`), r11 QRAM (`cq QRAM access: tainted-index memory
  access inside a loop`), r13 nested (`condition predates a non-diagonal gate`),
  r16 specialised callee (`callee contains a quantum primitive`), r32 onward-carried,
  r30u/r40u (`control flow under quantum control`, the b2u class), b7.
  ⚠ r12 (`break` with a CLASSICAL exit test) and r14 (my `continue` spelling) ACCEPT on
  both — `-O1` keeps them single-latch classically-bounded, so they are not the declines
  the brief predicted; both go 31 -> 37 like d1i.
- step 4 (ground truth, instrumented copy of the FIX sources under
  `review_c1_work/dbg/` — MY OWN COPY, `$SP/wt/fix-c1` untouched; `errs()` prints at
  every return of `invariantRegisterRoots` / `markIfRailLocal` and at the dispatch):
    d1i : R2=Collapsed roots=1, carried=1, admit %q0, skip %r0, TRUE, marks 1 block  ✓
    n8  : R2=Collapsed, admit %q0 AND %out, skip %r0, TRUE, marks 3 blocks           ✓
    r2  : R2=Collapsed, cand `%4 = add nsw %2, 7` peels TO ITSELF -> "root not a
          CallInst" -> FALSE -> markIfRailLocal added 0 blocks
    r5  : same, with `%4 = sext i16 %2 to i32`
    r33 : **R2=NotClaimed** (round-1 `lowerLoops` already collapsed the carried rail),
          so `invariantRegisterRoots` is called with `CarriedRoots = nullptr` and
          clause (iii) refuses on the CARRIED root `%3` -> FALSE
    r40 : R2=Collapsed, admits %out, skips %r0, TRUE — and then
          `markIfRailLocal` bails **`!AnyLocal`**; the loop is NEVER re-offered at
          round 2 (only ONE `[DBG] loop hdr=` line, `round2=0`)

- step 5 (fixtures, red-green, B3): each new fixture run BY HAND on both binaries
  (`review_c1_work/lit/`, `cq-opt` + `FileCheck` per prefix — I did NOT run ctest in
  `$SP/wt/fix-c1/build`, the orchestrator's run owns it):
    `control_phase_kickback_mixed_invariant_carried_inloop.ll`
      PRE-FIX: opt rc=0, CHECK **rc=1**, UCNT **rc=1**, FCNT **rc=1** (ACNT/XCNT/MDCNT/
      NOROUTE rc=0) — RED, and UCNT (the `and_i32_hl_unc` count) is one of the three.
      FIX: all 7 prefixes rc=0 — GREEN. Claim reproduces.
    `control_phase_kickback_mixed_hoisted_template_leak_control.ll` — all prefixes rc=0 on
      BOTH (the widening does not reach Q-R1-1). Claim reproduces.
    `lowering_break_global_phase_before_accept.ll` — all prefixes rc=0 on BOTH.
    `lowering_reject_break_phase_answer_kickback.ll` — `opt` **exit 1** with
      `cq loop lowering: early break preserves a phase answer` on BOTH binaries, FileCheck
      rc=0 on both; the string is character-identical to `LoopLowering.cpp:109`.
      `lowering_reject_break_phase_answer.ll` still passes on both.
- step 6 (MUTATION VALIDATION, re-run BY ME on my own instrumented copy, never on
  `$SP/wt/fix-c1`; `review_c1_work/msrc/mutate.sh`, log `review_c1_mutate.log`):
    BASELINE GREEN (2 `and_i32_hl_unc` lines) · M1 disable the CarriedRoots SKIP -> **RED**
    (CHECK/UCNT/FCNT, 0 `_unc`) · M2 disable the UNION -> **RED** (same) · RESTORED GREEN.
  Both halves load-bearing. Claim reproduces.
- step 7 (matrix, re-derived by me): `msrc/dump.py` hashes every generated source of every
  cell on both surfaces with the 542d588 script and with the HEAD script:
    base 1096 rows / head 1136 rows; **0 MISSING, 0 CHANGED**, 40 NEW (10 cells x 2
    surfaces x 2 spellings). `cells_of_matrix()` 274 -> 284. `expected.txt` `^m_` rows
    245 -> 255 with every pre-existing row byte-identical (sorted `diff`, no `<` lines);
    `quarantine.txt` byte-unchanged. The 10 new rows are 9 ACCEPT-IDENTICAL + 1
    UNROLLED-ONLY `rail record read past an in-place gate`. All claims reproduce.
- step 8 (e2e goldens): rolled golden == unrolled golden == the committed
  `clearance_c1/d1iu_...unrolled.subj.trace` == MY OWN `d1i` rolled trace on the fix
  binary. Four-way byte-identical.
- step 9 (population re-run, 60 programs, my own sweep): reproduces §3.5 with TWO count
  slips — the `d2` and `n4` rows are printed `0/0 | 0/0` where the correct figures are
  **3/0 | 3/3** (the condition is `i64`/`sext`-widened, so an `and_i32_hl`-only grep reads
  zero). Dispositions unchanged. Everything else matches, incl. `d1w` 32/**32**, `d1d`
  3/3 nothing freed dirty, `n10` byte-unchanged, `d1c`/`n1` DIVERGE(2) unfaithful twins,
  d2/d3/n4/n9/n10 rolled traces BYTE-UNCHANGED subj==fix.
- step 10: STRICT stage 2b on EVERY accepting reproducer I ran — **198 traces, 0 lines
  that are not `0 violation(s), 0 unproven`**.

---

# FINDINGS

## F-C1-1 — `CONFIRMED-MISCOMPILE`. An in-place `add`/`xor` on the INVARIANT register in the loop's PREHEADER puts the mixed loop back exactly where C-1 was, and the pre-3qlq ORACLE discharges the same program.

```c
/* review_c1_work/p/r2_preadd_inv.c — C-1's reproducer plus `+ 7` */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  q = q + 7;                                   /* <-- the only difference */
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
```
MEASURED (`run.sh p/r2_preadd_inv.c fix`, `... p/r2u_...unrolled.c fix`):

| binary | rolled `and_i32_hl`/`_unc` | unrolled | twin |
|---|---|---|---|
| PRE-FIX 542d588 | 3 / **0** | 3 / 3 | DIVERGE(6) |
| **FIX 3ec40c9** | 3 / **0** | 3 / 3 | **DIVERGE(6)** |
| pre-3qlq ORACLE 52d7764, old-surface twin `r2o`/`r2ou` | 3 / **3** | 3 / 3 | **IDENTICAL (38 = 38)** |

`opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s), 0 unproven`. The rolled trace
emits `cqrt_addc_i32(h0, 7)` — **the preheader op is lowered IN PLACE, onto h0** — then
three `cq_template_and_i32_hl(h0, 1<<i)` which-path records that are never `_unc`'d, and
then `cqrt_ry_i32(h0, 0.9)`. That is the clearance's §2.2 argument character for character,
and the oracle criterion it BLOCKED on ("the pre-3qlq ORACLE discharged them") is met.
`q ^= 9` (`p/r71_prexor_inv.c`) is the same, 3/0 vs 3/3 on both binaries.
The oracle's own trace for `r2o` proves the discharge is not an artefact of the surface:
`cqrt_addc_i32(h0, 7)` in the preheader, then per trip
`cq_template_and_i32_hl(h0, 1<<i)` … `cq_template_and_i32_hl_unc(hN, h0, 1<<i); cqrt_free(hN)`,
and `diff` of its rolled and unrolled traces is EMPTY.

ROOT CAUSE, measured with an instrumented copy of the FIX sources
(`review_c1_work/dbg/`, `errs()` at every return of `invariantRegisterRoots`):
```
[DBG] loop hdr= R2=2 roots=1 round2=0          <- Collapsed, the fix's own branch
[DBG] IRR cand:   %4 = add nsw i32 %2, 7
[DBG] IRR peel   %4 = add nsw i32 %2, 7 ->   %4 = add nsw i32 %2, 7
[DBG] IRR false: root not a CallInst           <- clause (ii)
[DBG] markIfRailLocal added 0 blocks
```
`peelInPlaceBase(%4, …, AsLowered=true)` stops AT the `add`, because
`railValueConsumerDisposition` returns `Unproven` there — the preheader is not
`blockCanRepeat` and `taint.InPlaceRailOps` does not yet contain the op at
`collapseFlattenedLoopRails` time — so `Root` is a `BinaryOperator`, `dyn_cast<CallInst>`
fails, and the WHOLE extension returns false. `lowerOps`' M-C then lowers that very op
IN PLACE (`cqrt_addc_i32`), so the register the body reads IS the root mint's rail and
clause (ii)'s (I1) proof carries verbatim. This is C-1's own sentence, one stage over:
*the proof exists and a precondition excludes the customer.*

NOT COVERED BY THE Q-R1-1 DISCLOSURE. PRD §0 E2 as rewritten says "ANY loop-invariant
TEMPLATE rail"; `cqrt_addc` mints no rail at all. `d9` (the notes' nearest population row)
is a chain of THETAS, which peels; no probe in the round used a dtzb op on the INVARIANT
register's pre-loop chain.

## F-C1-2 — `CONFIRMED-MISCOMPILE` (twin witness; no oracle twin expressible). A mixed loop whose in-loop region is an ONWARD (round-2) region leaks every per-trip which-path rail; `n8`, the round's only witness for this shape, escapes only because it ALSO carries a round-1 region.

```c
/* review_c1_work/p/r35_onward_diffusion.c  (+ p/tu_extf.c) */
int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);                       /* 6.5 classical-call arm -> %out */
  for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25); r=cq_theta(r,0.1); }
  y=cq_theta(y,0.9);                                  /* the diffusion */
  return cq_measure(r)+cq_measure(y); }
```
MEASURED, both binaries identical: rolled `and_i32_hl` **3** / `_unc` **0**; hand-unrolled
**3 / 3**; `diff` of the two traces is EXACTLY the three inserted
`cq_template_and_i32_hl_unc(hN, h3, 1<<i)` + `cqrt_free(hN)` pairs. `opt` exit 0,
verify-clean, STRICT 2b `5 rail mint(s) of which 5 left allocated … 0 violation(s), 0
unproven`. The trace ends `cqrt_ry_i32(h3, 0x1.ccc…p-1)` with h6/h8/h10 — bits 0,1,2 of
h3 — LIVE. Same shape without the diffusion: `p/r33_onward_inv_only.c`, 3/0 vs 3/3.

CONTROLS THAT MAKE IT THE CARRIED REGISTER'S FAULT (all on the FIX binary):
`r34` (same loop, NO carried register) **3/3**; `r50` (`r` gated OUTSIDE the loop) **3/3**;
`r51` (`r` carried by an in-place `add`) **3/3**; `r72` (the invariant is a **4.4
select-merge** `%out` instead of a 6.5 one) **3/3**.

ROOT CAUSE, measured:
```
r33: [DBG] loop hdr= R2=0 roots=0 round2=1        <- NotClaimed, so CarriedRoots == nullptr
     [DBG] IRR false: clause(iii) in-loop in-place gate  %13 = cq_theta(%3, 1.0e-01)
```
For an ONWARD region the loop's in-loop control is CLASSICAL at round 1 (`%out` does not
exist yet), so round-1 `lowerLoops` claims and collapses the carried rail itself. By the
round-2 `collapseFlattenedLoopRails` there is no tainted header phi left,
`collapseRailPhisIn` returns **NotClaimed**, and that branch calls
`invariantRegisterRoots(…, /*CarriedRoots=*/nullptr)` — so clause (0), the fix's own
remedy, is not in play and clause (iii) refuses on the carried root's in-body
`cq_theta`, taking the invariant register's discharge down with it. **The fix wired
`CarriedRoots` to the `Collapsed` branch only.** `r72` is served because a `select` with a
tainted condition is tainted at round-1 propagation, so its in-loop region is a ROUND-1
region and the loop reaches the `Collapsed` branch.

A SECOND, INDEPENDENT CAUSE ON THE SAME SHAPE (`p/r40_onward_r1open.c`): there the
extension SUCCEEDS (`IRR true`, roots=2 incl. `%out`) and `markIfRailLocal` then bails
**`!AnyLocal`** — at round 1 the round-2 values are not yet tainted — and the loop is
**never re-offered at round 2**: `AlreadyProcessed` is a set of BLOCKS and the round-2
flatten splices into the same pred block round 1 already flattened, so `NewlyTouched` is
false. (MEASURED: exactly ONE `[DBG] loop hdr=` line, `round2=0`, for both `r40` and `n8`.)
Both causes are the once-only-stage class of notes §2's ⭐ table.

WHAT THIS DOES TO THE RECORD. Notes §3.5's `n8` row ("mixed + an ONWARD 6.5 region in the
same body … 6/**6**") and §3.7's `ControlOwnedRails` row ("`n8`, whose onward 6.5 `%out`
rail discharges 6/6") are TRUE of `n8` and do not generalise: `n8` also contains a round-1
per-bit region on the root mint `q`, which is what puts it on the `Collapsed` path. Remove
that one line and the same program leaks (`r33`/`r35`).

## F-C1-3 — `LEAK`, disclosed class, undisclosed reachability. A bare `short` invariant register.
`p/r5_short_inv.c` (C-1's reproducer with `short q, r`): `-O1` hoists
`%4 = sext i16 %2 to i32` into the preheader, so the per-bit condition reads a TEMPLATE
rail and clause (ii) refuses ("root not a CallInst", MEASURED). rolled 3/0 vs unrolled 3/3
on BOTH binaries. This IS the Q-R1-1 class, but the PRD E2 sentence ("a cast, a Q+Q op, an
onward `mul`") reads as if the user wrote a cast; here the user wrote `short`. One
sentence of disclosure, not a fix.

## F-C1-4 — `DOC`. Two count slips in notes §3.5.
The `d2 hoisted sext` and `n4 per-bit condition on a sext` rows print `0/0 | 0/0`.
MEASURED (mine): both are **3/0 | 3/3** on both binaries — the condition is `i64`/widened,
so an `and_i32_hl`-only grep reads zero. The DISPOSITION recorded (leak, rolled trace
byte-unchanged subj==fix) is correct and I re-confirmed it.

## F-C1-5 — `CLEAR`. The 8h7d.5 multiplicity question (a preheader forward gate with `At` in the K-times body).
`Uncomputation.cpp:986-1000` names this hazard and says *"WIDEN THAT MARKING AND THIS
BECOMES REACHABLE with no test to catch it."* The fix widens that marking. Re-derived:
* `markIfRailLocal`'s operand clause still refuses every outside-`L` tainted operand that
  does not peel to a Root, so only Roots are new;
* every newly admitted Root is `cqrt_alloc_`-produced (root mint, or clause-(ii-b)
  `ControlOwnedRails` merge out-rail) and fails `isInteriorTerminalHandle` (I1) — no
  interior `At` can be planned for it;
* a preheader value that PEELS to a Root is by construction an in-place gate and mints no
  rail, so it is not an interior candidate either;
* a preheader TEMPLATE rail read in the body is necessarily a `Cand` of
  `invariantRegisterRoots`, and every spelling refuses the extension, so the body is never
  marked. MEASURED on `n9`, `d2`, `d3`, `n4`, `r2`, `r5`, `r71` — all 3/0 and all
  BYTE-UNCHANGED subj==fix (this is also why F-C1-1/3 are leaks and not K-adjoints);
* `reverseTerminalGroup` (Uncomputation.cpp:442-448) additionally requires every recovered
  gate to sit in an `IterationLocalBlocks` block once ANY gate repeats, and
  `planInteriorComponent:979` restates it per gate.
DIRECT MEASUREMENTS: `p/r63_dead_inv_pregate.c` — a preheader `cqrt_ry_i32(h0, 0.7)` on an
ADMITTED root whose register is then DEAD — emits **zero** negative-angle `cqrt_ry`
anywhere and is rolled==unrolled BYTE-IDENTICAL; `d1w` at K=32 pairs **32 mints / 32
`_unc`** (a K-vs-1 defect would read 32 against 1). No multiplicity defect found.

## F-C1-6 — `CLEAR`. The RECORD question (F-3's mirror): the fix creates no new stale-record class.
`staleRailRecordRead` is still asked only of the COLLAPSED `ChainsByRoot`, which the notes
state. Its emptiness argument holds on measurement: `n3` (the invariant register
`cq_measure`d ×3 INSIDE the body) rolled == unrolled; `d12`/`d8` unmoved 3/3;
`p/r60_record_read_stale.c` (a DISTINCT SSA record `m = cq_theta(q,0.2)` read per-bit, a
post-loop `z = cq_theta(m,0.9)`, then `cq_measure(m)` and `cq_measure(z)`) accepts on BOTH
binaries and emits the identical stream on both — the pre-existing OQ-C1-2 alias
semantics, which I re-measured BYTE-IDENTICAL on the pre-3qlq ORACLE, on 542d588 and on
the fix (`p/n12_flat_alias_measure_after_gate.c`, 4 = 4 = 4).

## F-C1-7 — `DOC`. The new matrix axis cannot see any of F-C1-1/2/3.
Sub-grid F's 10 cells are all `prefix=none … suffix=none` with a ROOT-MINT invariant `a` at
`i32`: no preheader in-place op on `a`, no `%out` invariant, no non-`i32` width. The axis
does close C-1's own shape (9 of its 10 cells were TRACE-DIVERGENCE before the fix, as the
fix agent measured) — it just does not bound the three residuals above.

## Not findings, but corrections to the brief's expectations
* `r12` (a `break` whose exit test is CLASSICAL) and `r14` (my `continue` spelling) ACCEPT
  on BOTH binaries and go 31 -> 37 like `d1i`: `-O1` keeps them single-latch and
  classically bounded. "Must decline" holds only for a TAINTED break/exit.
* `r32` (the onward `%out` as the CARRIED register, `y = y + 3` per trip) is not a shape:
  it declines `cq controlled lowering: condition predates a non-diagonal gate under
  quantum control` on both binaries, rolled and flat.

---

# WHAT I RAN (only this)

| gate | result |
|---|---|
| harness control | `p/ctl_good.c` ACCEPT 7 lines on subj AND fix; `p/ctl_bad.c` DECLINE `cq rotation lowering: unsupported quantum-derived rotation angle` on both |
| my probe battery | **56 new `p/r*.c` programs** + the round's 60 `d*`/`e5`/`n*`; **198 traces**, 3 binaries where a spelling exists |
| STRICT stage 2b | **198 of 198** `0 violation(s), 0 unproven` |
| red-green, by hand (`cq-opt` + `FileCheck` per prefix) | C-1 accept fixture RED on 542d588 (CHECK/UCNT/FCNT rc=1) / GREEN on the fix; leak control and global-phase control green on both; B3 `opt` exit 1 + exact string on both |
| mutation validation, re-run by me on my own instrumented copy | BASELINE GREEN · M1 RED · M2 RED · RESTORED GREEN |
| matrix generated sources, re-derived | 1096 rows base vs 1136 head: **0 missing, 0 changed**, 40 new; cells 274 -> 284; expected rows 245 -> 255 all pre-existing byte-identical; quarantine byte-unchanged |
| e2e goldens | rolled == unrolled == clearance record == my own `d1i` fix trace (4-way byte-identical) |
| instrumented ground truth | my own copy of the FIX sources under `review_c1_work/dbg/`, built twice; `$SP/wt/fix-c1` NEVER touched or rebuilt |
| read, not re-run | the orchestrator's `orch_full_ctest_c1.log` — **342/342 passed, EXIT=0, 343.9 s** |
| NOT run | any `ctest` in `$SP/wt/fix-c1/build`; the full suite; `cq-opt-equivalence-full`; the twin matrix itself |

# SUBJECT DRIFT DURING THE REVIEW (recorded, not a problem)
`$SP/wt/fix-c1` moved **3ec40c9 -> ba01d8d** while I worked ("the C-1 fix round's
COUNT/STATUS pass"). `git diff --name-only 3ec40c9 HEAD` = **4 files, all docs**
(`CLAUDE.md`, `ROADMAP.md`, the records `README.md`, the PRD) — no source, no fixture, no
golden, no tool. `find ir-pass/src ir-pass/include ir-pass/tools -newer build/ir-pass/cq-opt`
is EMPTY at `ba01d8d`, so every measurement above holds for it. Both checkouts' working
trees are clean; I rebuilt neither.

# VERDICT

FINDINGS
