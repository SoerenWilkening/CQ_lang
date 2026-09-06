# review_r1_L8 — Rule-13 round 1, lens L8 (FIXTURE INTEGRITY)
bd `test_C_libtooling-3qlq.2`, Inc 1 part A (register-free `cq_phi` by kickback).
READ-ONLY. Nothing in `/Users/sorenwilkening/Desktop/CQ_lang` was edited, built or
regenerated; every fixture I ran is a COPY under `$SP/progress/review_r1_L8/fx/`.

SUBJECT  `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`),
         `build/ir-pass/cq-opt` + `build/ir-pass/libCQPass.so` (both mtime 14:49).
ORACLE   `$SP/wt/pre-3qlq` @ `52d7764`, its own `cq-opt` / `libCQPass.so`.
FILES    `$SP/progress/review_r1_L8/` — `harness.py` (lit ShTest replica),
         `inject.py` (the six injections), `drive{,2,3,4}.py`, `matrix.tsv`,
         `matrix_prefixes.tsv`, `matrix_extra.tsv`, `fx/` (11 fixture copies),
         `out/` (clean + injected IR, hand-built evidence files), `inj/` (66
         injected artifacts), `selfcheck/`, `probes/`, `lit_verify.log`,
         `sweep_rz.txt`, `red.txt`, `migset.txt`, `touched.txt`.

---

## 0. Harness, and the three controls that make its "CAUGHT" mean something

`harness.py` mirrors lit's ShTest for these fixtures: it takes EVERY line
containing the token `RUN:` (lit scans all lines, not only comment lines — the
implementer's own recorded trap), expands `%cq-opt`/`%cq-pass`/`%filecheck`/`%s`/`%t`
exactly as `build/ir-pass/test/lit.site.cfg.py` + `ir-pass/test/lit.cfg.py` do, puts
the FileCheck directory on `PATH`, runs RUN-line 0 (the pass) to make `%t.cqd0.ll`,
MUTATES that text, then runs every remaining RUN line and records which
`--check-prefix` exits non-zero.

* **Control A — clean must PASS.** All 11 accepts pass every prefix unmutated
  (`drive.py`, column `clean`: 11/11 PASS).
* **Control B — known-bad must FAIL.** Deleting the forward kickback gate from the
  output fails 11/11 (`drive.py`, column `known-bad`: `FAIL(good)` ×11).
* **Control C — the harness against a deliberately broken fixture.** Two mutants in
  `selfcheck/`: `broken_check.ll` (a `CHECK-NEXT` retargeted at `@cqrt_ZZZ_NOT_A_SYMBOL`)
  and `broken_noroute.ll` (`NOROUTE-NOT: cqrt_cswap` → `NOROUTE-NOT: cqrt_free`, i.e.
  forbidding something the clean output contains). The harness reports **FAIL** on
  both. A harness that reported PASS there would have been worthless.
* **Anti-lie discipline (the Inc-4 precedent).** An injection appends **NO `declare`**,
  so a catch is attributable to the injected CALL and never to a declaration line.
  Audited: `diff -u inj/…$k inj/…$k.mut` is exactly **one** added or removed line per
  injection, six for six. Every case reported NOT-CAUGHT was then re-run WITH the
  matching declare to separate a fixture hole from a harness artifact (`drive.py`
  reports `MISSED` only if BOTH runs pass); the brief's six produced zero such cases.
* **One measured near-miss in my own method, recorded because it is the same class.**
  Checking "is fixture X red?" with `grep -q X red.txt` reports *not red* for a file
  that **does not exist**. That is how I nearly certified
  `control_angle_select_ry_reject_runtime_arms.ll` (the name in `BRIEF_impl_inc1a.md`
  §Step 4) as green; the file does not exist — see F-L8-5. Every disposition below is
  therefore anchored on running the tool, not on a name lookup.

---

## 1. Per-fixture injection table — the brief's six injections

`(a)` `cqrt_cswap` · `(b)` `cqrt_rz_i32_controlled` · `(c)` a second `cqrt_rz_i1` on
the flag AFTER its `cqrt_free` · `(d)` a surviving `call void @cq_phi(double 0.5)` ·
`(e)` the flag's `cqrt_free` DROPPED · `(f)` a NEGATED-angle `cqrt_rz_i1(f, −θ)`
immediately after the forward gate (the shape of F-L7-1). Cell = the `--check-prefix`
that caught it; `N/A` = the shape has no such element. Source `matrix_prefixes.tsv`.

| accept fixture | clean | known-bad | (a) | (b) | (c) | (d) | (e) | (f) |
|---|---|---|---|---|---|---|---|---|
| `control_angle_select_phase_constants` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C4 | CHECK,C1 |
| `control_angle_select_phase_runtime` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C3 | CHECK,C1 |
| `control_phase_kickback_derived_cond` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | C5 | CHECK,C1 |
| `control_phase_kickback_diamond` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C4 | CHECK,C1 |
| `control_phase_kickback_f64_cond` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C4 | CHECK,C1 |
| `control_phase_kickback_ifelse_tail_phi` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C4 | CHECK,C1 |
| `control_phase_kickback_inloop` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C4 | CHECK,C1 |
| `control_phase_kickback_negated` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C3 | CHECK,C1 |
| `control_phase_kickback_seq` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | CHECK,C1 | CHECK,NOROUTE | CHECK,C4 | CHECK,C1 |
| `control_phase_kickback_two_calls` | PASS | FAIL✓ | CHECK,NOROUTE | CHECK,NOROUTE | C1 | CHECK,NOROUTE | CHECK,C4 | CHECK,C1 |
| `lowering_phi_uncontrolled_deleted` | PASS | FAIL✓ | NOROUTE | NOROUTE | N/A | NOROUTE | N/A | NOROUTE |

**All six injections are CAUGHT in every fixture where the shape admits them —
64 of 64 applicable cells, 0 MISSED.** Two structural reasons, both measured:

1. Every kickback / angle-select accept ships a **contiguous `CHECK`→`CHECK-NEXT`
   chain from the flag mint through the strip to the free**, so *anything inserted
   inside the emitted region* is caught by adjacency alone.
2. The `C<n>-COUNT-<k>` + `C<n>-NOT` pairs bound the gate multiplicities, so an
   *extra* `cqrt_rz_i1` or a *missing* `cqrt_free` is caught wherever it is placed.

I re-ran (a)/(b)/(d)/(f) with the injection moved **outside** the CHECK-NEXT window
(immediately before `ret`) to strip reason 1 away. Still caught, by NOROUTE or C1, in
41 of 42 applicable cells (the one `N/A` is my placement helper declining a two-line
run-time-angle injection, not a fixture result; its in-window form is caught by C1).

Two further whole-shape injections, for the two claims the diamond's header makes in
prose (`drive4.py`):

| injection | result |
|---|---|
| **SUBSTITUTE** the kickback gate's width, `cqrt_rz_i1` → `cqrt_rz_f80` | caught 10/10 by `CHECK` **and** `C1` (the count goes to 0) |
| a full **work rail** re-appearing (`cqrt_alloc` + `cqrt_cswap` + `cqrt_free`) | caught 11/11 by `NOROUTE` **and** the `cqrt_free` count |

---

## 2. Findings

### F-L8-1 — DOC-OR-FIXTURE-TRUTH
**The "no TENSORED Rz" negative assertion enumerates 6 of the 8 non-`i1` Rz widths.
`cqrt_rz_f16` and `cqrt_rz_f80` are asserted by NOTHING in 10 of the 11 accepts —
while each of those fixtures' own header says it forbids "`cqrt_rz_<W>` for W != i1".**

*The claim.* `control_phase_kickback_diamond.ll:71-77` (and the same block in nine
siblings): "The four things a register-free kickback must NEVER emit: … `cqrt_rz_<W>`
for W != i1 — the TENSORED per-register Rz is the defect this increment removes".
The assertion under it is an explicit list: `cqrt_rz_i8 · i16 · i32 · i64 · f32 · f64`.
`runtime/cq_runtime.h:140-148` declares **nine** widths — `i1 i8 i16 i32 i64 f32 f64
**f16 f80**`. Two are unlisted.

*Evidence — hand-built, no Python, so the artifact is auditable byte for byte.*
`out/evidence_clean.ll` is the subject's own lowering of
`ir-pass/test/control_phase_kickback_diamond.ll`; `out/evidence_f80.ll` is that file
with one line inserted before `ret` by `sed`:
```
  call void @cqrt_rz_f80(i32 %h_cmp, double 5.000000e-01)
```
FileCheck of the **unmodified fixture** against it:
```
prefix=CHECK exit=0   prefix=NOROUTE exit=0   prefix=C1 exit=0
prefix=C2    exit=0   prefix=C3      exit=0   prefix=C4 exit=0
```
The **discriminating control**, the identical line with the width token changed
(`out/evidence_i32.ll`):
```
prefix=CHECK exit=0   prefix=NOROUTE exit=1   ← caught
```
So the difference is exactly the width token, and nothing else. `i_rz_f16` in
`matrix_extra.tsv` is the same result for `f16`. `lowering_phi_uncontrolled_deleted.ll`
is the ONE fixture that catches both, because its NOROUTE carries the blanket
`; NOROUTE-NOT: cqrt_rz` (line 81) instead of an enumeration.

*Severity, stated honestly.* This is an assertion-completeness gap, **not** a live
miscompile. A *substitution* of the `i1` gate by an `f80` one is caught 10/10 by the
`C1` count (measured, §1). Only an *added* `f16`/`f80` gate is invisible, and the two
minters that can still produce a non-`i1` `cqrt_rz` (`NestedRouteEmit.cpp:116`,
`SwitchRouteEmit.cpp:113`) are part B's rows, reachable from hand IR only. What is
false today is the fixture's own sentence about what it forbids.

*The fix, VALIDATED in both directions before proposing it.* In each of the ten,
replace the six enumerated lines with one regex line:
```
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
```
Measured against real files (`out/fixcand.txt`): clean diamond output **exit 0**;
clean `control_phase_kickback_inloop` output **exit 0**; `f80`-injected **exit 1**;
`f16`-injected **exit 1**; `i32`-injected **exit 1**. Files:
`control_angle_select_phase_{constants,runtime}.ll`,
`control_phase_kickback_{derived_cond,diamond,f64_cond,ifelse_tail_phi,inloop,negated,seq,two_calls}.ll`.

---

### F-L8-2 — DOC-OR-FIXTURE-TRUTH
**Three accept fixtures whose correct stream contains NO `cqrt_x` assert nothing about
`cqrt_x` — so a single, unpaired polarity gate on the flag passes them silently.**

`cqrt_x` is the polarity bracket. An *unpaired* `cqrt_x(f)` inverts which branch the
phase lands on — the L1-lens miscompile. Of the six accepts whose correct output has
zero `cqrt_x`, three carry `; NOROUTE-NOT: call void @cqrt_x(` and three do not:

| accept with no `cqrt_x` in its output | `NOROUTE-NOT` for it? | `C<n>-COUNT` for it? |
|---|---|---|
| `control_phase_kickback_diamond` | **yes** (`:80`) | – |
| `control_phase_kickback_f64_cond` | **yes** (`:68`) | – |
| `control_phase_kickback_seq` | **yes** (`:90`) | – |
| `control_phase_kickback_inloop` | **no** | no |
| `control_phase_kickback_two_calls` | **no** | no |
| `lowering_phi_uncontrolled_deleted` | **no** | no |

*Evidence.* One `call void @cqrt_x(i32 %h_cmp)` inserted before `ret` (outside the
CHECK-NEXT window), fixtures unmodified:
```
control_phase_kickback_inloop      CHECK=0 C1=0 C2=0 C3=0 C4=0 C5=0 NOROUTE=0  *** MISSED ***
control_phase_kickback_two_calls   CHECK=0 C1=0 C2=0 C3=0 C4=0      NOROUTE=0  *** MISSED ***
lowering_phi_uncontrolled_deleted  CHECK=0 C1=0 C2=0                NOROUTE=0  *** MISSED ***
control_phase_kickback_diamond     CHECK=0 C1=0 C2=0 C3=0 C4=0      NOROUTE=1  caught  ← control
```
The diamond is the discriminating control: same injection, same position, caught,
and the only difference between the files is the one directive line. Artifacts
`out/x_control_phase_kickback_{inloop,two_calls,diamond}.inj.ll`,
`out/x_lowering_phi_uncontrolled_deleted.inj.ll`.

*This is an inconsistency inside the family, not a design choice* — the family already
knows the assertion and applies it to half the shapes that need it.

*Fix.* Add `; NOROUTE-NOT: call void @cqrt_x(` to `control_phase_kickback_inloop.ll`
and `control_phase_kickback_two_calls.ll`, and `; NOROUTE-NOT: cqrt_x` to
`lowering_phi_uncontrolled_deleted.ll` (that file's NOROUTE is already blanket-style).
Validated: the clean outputs of all three pass the added line; the injected ones fail it.

---

### F-L8-3 — DOC-OR-FIXTURE-TRUTH
**P7's Rule-1 assert `cq controlled lowering: unclaimed branch phase under quantum
control` has NO fixture, and the progress file says it has one.**

`$SP/progress/impl_inc1a.md` heads its list "Exact new diagnostic strings (Rule 12 —
fixtures mirror these character-for-character)" and lists three. For this one:

* source: `ir-pass/src/TaintPropagation.cpp:1604`, `diagnoseUnderControl(CI,
  "unclaimed branch phase")` — the FIRST clause of `deleteGlobalPhases`, i.e. the sole
  mechanism that turns a Rule-1 hole into a loud decline instead of a **silently
  dropped phase**;
* fixtures containing the string: **3** — `control_phase_kickback_reject_bare_i1.ll:36`,
  `control_phase_kickback_reject_multiblock_arm.ll:30`,
  `lowering_phi_uncontrolled_deleted.ll:19` — **all three in PROSE**. Fixtures with a
  `CHECK` for it: **0** (`grep -c '^; *CHECK.*unclaimed branch phase' ir-pass/test/*.ll | grep -v ':0' | wc -l` -> 0). Nothing in the 1602-fixture corpus executes that branch.

The two decline fixtures do pin the **ordering** (their `RUN: not` + a CHECK for the
*control* string requires the region decline to fire *before* P7 could delete the
call), and I confirmed by measurement that only ONE diagnostic reaches FileCheck in
each (`cq-opt … 2>&1 | wc -l` = 2 lines: the error and a blank). That is a real and
valuable property. It is **not** the assert firing.

*I tried to construct a module that fires it, twice, and both declined earlier*
(`probes/assert_try1.ll`, a tainted `br` with no merge at all → `non-reconverging value
exit under quantum control`, exit 1; `probes/assert_try2.ll`, a `cq_phi` inside a
CLASSICAL sub-diamond nested in a tainted arm → `control flow under quantum control`,
exit 1). So Rule 1 holds on both, and the assert stays defensive-and-unreached.

*Fix (two acceptable forms).* Either (i) the fix agent constructs a hand-IR module that
reaches the assert and ships it as a decline fixture mirroring the string — noting that
if such a module exists it is itself a "third path" finding for L3 — or (ii) the three
fixture headers state explicitly that the branch is **unreached by the corpus and why
no fixture exists**, and the progress-file line is corrected. What must not stand is
the current combination: a claim that the string is mirrored, with no mirror.

---

### F-L8-4 — DOC-OR-FIXTURE-TRUTH
**The same list names a diagnostic string that exists nowhere in the pass.**

`cq controlled lowering: multiple branch phases in one arm under quantum control`:
```
grep -rn 'multiple branch phases in one arm' ir-pass/src ir-pass/include  ->  0 hits
grep -rl 'multiple branch phases in one arm' ir-pass/test/*.ll            ->  0 files
```
It was superseded by orchestrator decision (2) — N>1 `cq_phi` per arm now ACCEPTS
(`control_phase_kickback_two_calls.ll`) — and that supersession is recorded **later in
the same document**. So the "Exact new diagnostic strings" section is stale in 2 of its
3 entries (this one and F-L8-3). A reader grepping for it finds nothing and cannot tell
whether the string was removed or never landed.

*Fix.* Delete the row from `$SP/progress/impl_inc1a.md`'s string list (or move it under
the "superseded" paragraph with `NOT SHIPPED` on it). No fixture or source change.

---

### F-L8-5 — CLEAR (with a hand-off note that is NOT the implementer's error)
`BRIEF_impl_inc1a.md` §Step 4 instructs the implementer to keep
`control_angle_select_ry_reject_runtime_arms.ll` declining. **That file does not
exist**; `ls ir-pass/test/*runtime*` gives `control_angle_select_reject_runtime_arms.ll`
(the Ry stem), `control_angle_select_reject_runtime_arms_rz.ll` (the Rz stem) and
`control_angle_select_reject_runtime_one_arm.ll`. Measured dispositions at `fa96336`:

* `control_angle_select_reject_runtime_arms.ll` — **GREEN**, and green for the right
  reason: SUBJECT and ORACLE both emit
  `cq controlled lowering: rotation angle under quantum control`, byte-identical; its
  `@cq_phi_si32` appears only in a `declare` (line 78), never in a call. The Ry
  direction of the Q3 pin therefore genuinely still holds. ✔
* `control_angle_select_reject_runtime_arms_rz.ll` — **RED** (in the 362), correctly:
  it CALLs `@cq_phi_si32` twice and asserts the Rz stem REFUSES run-time arms, which is
  precisely what owner Q3 reverses. Hand-off: the migration agent must **rewrite it as
  an accept**, not mechanically re-spell it. It cannot go silently false-green (a
  mechanical rewrite leaves `CHECK: error{{.*}}rotation angle` unmatched and the fixture
  red), so this is a work item, not a hazard.

---

### F-L8-6 — CLEAR (checked, no finding)
Two decline fixtures assert only the generic string `cq controlled lowering: control
flow under quantum control`, which **45** fixtures in the corpus assert (`grep -lE
'^; *CHECK[-A-Z0-9]*:.*cq controlled lowering: control flow under quantum control'
ir-pass/test/*.ll | wc -l`), so the string alone cannot show
they decline for the reason their names claim. I tested that directly by removing the
named cause and re-running (`probes/{mixed,multiblock}_reduced.ll`):

* `control_phase_kickback_reject_mixed_arm.ll` minus the arm's `cq_theta` and the merge
  φ → **exit 0**, one `cqrt_rz_i1` emitted;
* `control_phase_kickback_reject_multiblock_arm.ll` with the arm collapsed to one block
  → **exit 0**, one `cqrt_rz_i1` emitted.

Both are genuine discriminators, and the family already ships the corresponding accept
(`control_phase_kickback_diamond.ll`). No change needed.

---

## 3. Every count in the implementer's progress file, re-measured

All MEASURED on the subject at `fa96336`, with the command that produced them.

| claim | command | measured | verdict |
|---|---|---|---|
| 6 commits / 45 files over `dfb8e83` | `git diff --name-only dfb8e83..fa96336 \| wc -l` | 45 | ✔ |
| 21 fixtures = 11 accept + 10 decline | `git diff --name-only … -- ir-pass/test`; `grep -c 'RUN: not'` | 21 = 11 + 10 | ✔ |
| "of the **20** fixtures I ADDED" + 1 REWRITTEN | `git diff --name-status … -- ir-pass/test` | 20 `A` + 1 `M` | ✔ |
| corpus 1602 | `ls ir-pass/test/*.ll \| wc -l` | 1602 | ✔ |
| **1239 passed · 1 XFAIL · 362 FAILED** | `ctest -R ir-pass-lit` re-run by me, 52.88 s, `lit_verify.log` | 1239 · 1 · 362 | ✔ exact |
| `grep -lE '@cq_phi_[a-z0-9]+'` → 491 | same | 491 | ✔ |
| **red \ that set → 0** | `comm -23 red.txt migset.txt` | empty | ✔ |
| 0 of the added fixtures red | `comm -12 red.txt touched.txt` | empty | ✔ |
| 155 green retired-family fixtures = 104 declines + 51 accepts | green ∩ `grep -lE 'cq_phi_'`, minus the 20 ADDED | **155 = 104 + 51** | ✔ (see note) |
| of the 51 accepts, 47 declare-only / **4 CALL it** | `grep -E '(call\|invoke).*@cq_phi_[a-z0-9]+\('` | 47 / 4, and the four names match exactly | ✔ |
| **exactly 3 fixtures still emit a non-`i1` `cqrt_rz`** | full 1602-fixture sweep, `sweep_rz.sh` → `sweep_rz.txt` | 3, all `cqrt_rz_i32`, exactly `control_swap_switch_phase{,_passthrough}.ll` + `control_swap_switch_scrutinee_measured.ll` | ✔ |
| Grover: 15 trace lines both binaries; diff = 2 lines each way | `wc -l`; `diff -u` | 15 / 15; diff is exactly the two `rz_i32_controlled → rz_i1` pairs | ✔ |
| `p6_rolled2` 33/6 · `p_perbit4` 31/4 · `p_perbit32` 227/32 · `p2_angsel` 10/2 | `wc -l`; `grep -c cqrt_rz_i1` | exact on all four | ✔ |
| subject traces: `_controlled` 0 · `cqrt_cswap` 0 · `cqrt_rz_i32` 0 | `grep -c` on all 6 traces | 0 / 0 / 0 | ✔ |
| K-independence: 25 `@slice` lines at K=3 **and** K=1000; 23 at K=4 **and** K=32 | body-line count between `define @slice` and `}` | 23 = 23 and 21 = 21 body lines (= 25 / 23 counting `define`+`}`) | ✔ — INDEPENDENCE exact; the absolute figure is the braces-included reading, worth stating in the file |
| "12 `cq_phi_` prefix recognizers" (commit `c48c526`) | `git show --stat c48c526` | 12 files, +158 lines | ✔ structurally |

**Note on the 155.** The progress file does not state the grep. It reproduces exactly
as *fixtures containing the token `cq_phi_` that are GREEN, minus the 20 files this
increment ADDED* (the one REWRITTEN file counted as pre-existing). Under the narrower
`@cq_phi_<sfx>` grep the same computation gives 129 = 103 + 26, so **the definition is
load-bearing and should be written next to the number** before the migration agent
re-derives it and gets a different answer.

## 4. Fixture-hygiene audit (the F-L6-1 windowing hazard and its neighbours)

Machine-checked across all 21 touched fixtures; every line below is a measurement.

* **No positive directive inside a `NOROUTE` prefix.** `NOROUTE` carries only `-NOT`
  in 21 of 21 — no `NOROUTE:`, `-COUNT-n`, `-NEXT`, `-SAME`, `-DAG`, `-LABEL`. The
  Inc-3/Inc-4 F-L6-1 defect (a positive COUNT windowing every later NOT) is **absent**.
* **Every `C<n>` prefix is exactly one `COUNT-k` followed by its `NOT`,** in that
  order, in 21 of 21. No prefix has two positives (which would silently become an
  ORDER assertion), and no `-NOT` precedes its own positive.
* **Directive prefixes and RUN lines correspond 1:1** — no prefix has directives with
  no RUN line (a silently dead assertion) and none the reverse. (`MEASURED:` at
  `control_phase_kickback_seq.ll:19` and `control_angle_select_phase_constants.ll:6`
  is prose, not a directive; FileCheck only looks at prefixes named on its command
  line, so it is inert. Flagged only because a naive scanner reads it as one.)
* **Every literal `%name` in every directive exists in that fixture's own pass
  output** — 11 of 11 accepts, checked by re-deriving the name set from
  `out/*.cqd0.ll` after stripping `[[…]]` and `{{…}}`. Nothing is typed from memory;
  the Inc-4 F-L?-"9 of 20 named a `%h1` that does not exist" class does not recur.
* **No accidental RUN line.** My parser takes any line containing `RUN:` (as lit
  does); its per-file counts equal `grep -c 'RUN:'` for all 21, so no prose line has
  minted a bogus run directive — the trap the implementer records as having cost 2 red
  fixtures is genuinely absent from what shipped.
* **Decline strings, character-for-character.** All ten decline fixtures were run and
  their emitted diagnostic captured (`§2` artifacts). Each `CHECK` is a literal
  substring of the emitted line, and each string is present in the pass source with
  the same spelling: `ArmClassify.cpp:3633` (`branch phase on a bare i1 condition`),
  `ControlDetect.cpp:593/640` (`control flow inside a loop body`),
  `OpcodeSupport.cpp:338` (`no template for opcode '…' in tainted context`),
  `TaintPropagation.cpp:213` (`unsupported declared prototype for cq_phi`, built by
  `Twine(Concern) + ": unsupported declared prototype for " + …`),
  `TaintPropagation.cpp:458` (`tainted value consumed by an unknown callee`), and the
  `diagnoseUnderControl(…, "rotation angle" / "control flow")` family. **Exception:
  `unclaimed branch phase` — F-L8-3.**
* **One fixture header's MEASURED claim independently re-verified.**
  `control_phase_kickback_reject_qq_compare.ll:10-14` asserts the pre-3qlq oracle emits
  the identical string for the retired-register spelling. I wrote that twin
  (`out/qq_oracle.ll`) and ran the ORACLE binary: `no template for opcode 'icmp i1' in
  tainted context`, **exit 1** — identical. ✔
* **`control_phase_kickback_two_calls.ll`'s header claim** that refusing N>1 would have
  regressed four shipped e2e accepts: all four `.c` files exist and each has ≥2
  `cq_phi` calls in one arm (`slice_control_phase_diamond.c:27-28` is the clearest). ✔
* **`control_phase_kickback_diamond.ll`'s header claim** that all three of
  `recoverRegion`'s recognizers require a non-null `soleMergePhi`: `ControlDetect.cpp`
  lines 298, 312, 333 — three calls, one per recognizer. ✔
* **The `NOROUTE-NOT: fsub` in `control_angle_select_phase_runtime.ll` is a real
  discriminator**, not decoration: injecting `%l8d = fsub double %a, %b` fails NOROUTE
  (exit 1) and passes every other prefix. That is the assertion carrying "the Rz stem
  is EXACT, not by-difference", so it mattered to check.

## 5. Coverage gap I am flagging without claiming as my own finding

No fixture in the 21 has a **data use of the minted flag** (the `ShareCondFlag` shape).
That is the shape of this round's confirmed miscompile F-L7-1, in which the uncompute
spine emits `cqrt_rz_i1(f, −θ)`. My injection (f) is caught 11/11 — but only because
these fixtures' CHECK-NEXT chains are contiguous and their `C1` counts are tight; a
fixture *of the F-L7-1 shape* does not exist to be caught. Whatever fence the fix agent
lands for F-L7-1 needs its own accept fixture with a `zext`/data consumer of the flag,
and a `C1-COUNT` that pins the number of `cqrt_rz_i1` at the number of `cq_phi` calls.

---

## VERDICT — L8 (fixture integrity): **DOC-OR-FIXTURE-TRUTH ×4, no miscompile.**
The brief's six injections are caught in **64 of 64 applicable cells across all 11
accept fixtures**, under a harness proved honest by a clean control, a known-bad
control, two deliberately-broken-fixture self-checks and a per-injection one-line diff
audit; **every numeric claim in `impl_inc1a.md` re-measured EXACTLY**, including the
362/1602 red partition (`red \ {491 retired-family files}` = ∅), the 155 = 104+51
false-green set with its four named CALL sites, and the 3-and-only-3 non-`i1` `cqrt_rz`
emitters found by a full 1602-fixture sweep. The prefix hygiene the Inc-3/Inc-4 rounds
paid for is genuinely applied: `NOROUTE` is pure-negative and whole-file in 21 of 21,
every count sits in its own prefix, and every `%name` is derived from the output.
What is NOT true is written down four times: two Rz widths the headers claim to forbid
are unasserted (**F-L8-1**, `f16`/`f80`, measured invisible in 10 of 11); three
fixtures whose stream has no polarity gate assert nothing about one (**F-L8-2**,
measured invisible in 3, caught in the 3 siblings that carry the line); and the
"Exact new diagnostic strings … fixtures mirror these character-for-character" list is
wrong in 2 of its 3 entries — one string has no fixture (**F-L8-3**, and it is the
Rule-1 assert, the single thing standing between a third path and a silently deleted
phase) and one exists nowhere in the pass at all (**F-L8-4**). All four fixes are
fixture/prose edits; the proposed directives are validated in both directions on real
files. Nothing found here contradicts a PRD §2 decision or a §12 assumption, so there
is **no OWNER QUESTION from this lens**.
